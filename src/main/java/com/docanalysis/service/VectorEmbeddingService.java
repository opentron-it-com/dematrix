package com.docanalysis.service;

import com.docanalysis.domain.DocumentChunk;
import com.docanalysis.exception.DocumentProcessingException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;

/**
 * Generates embeddings using local Ollama embeddings (free, no API calls).
 * Enforces max sequence length to prevent Ollama failures.
 * mxbai-embed-large: 1024 dimensions, ~2000 char context window
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class VectorEmbeddingService {

    private final ChromaDbService chromaDbService;
    private final RestTemplate restTemplate;

    @Value("${app.ollama.base-url:http://127.0.0.1:11434}")
    private String ollamaBaseUrl;

    @Value("${app.embedding.model:mxbai-embed-large}")
    private String embeddingModel;

    // mxbai context limit: ~512 tokens ≈ 2000 chars. Use 2000 to match chunk size.
    private static final int MAX_EMBEDDING_TEXT_LENGTH = 2000;

    /**
     * Generate embedding and store in ChromaDB.
     * Truncates text to fit Ollama context window before embedding.
     * ChromaDB upsert failures are logged but not fatal - documents can still be analyzed with full text.
     * @param chunk The document chunk to embed
     */
    public void generateAndStoreEmbedding(DocumentChunk chunk) {
        try {
            log.debug("Generating embedding for chunk: {}", chunk.getId());

            // Truncate text to fit model context window
            String textToEmbed = truncateText(chunk.getChunkText(), MAX_EMBEDDING_TEXT_LENGTH);
            float[] vector = getEmbeddingVector(textToEmbed);

            // Store in ChromaDB (async, non-blocking)
            Map<String, Object> metadata = new HashMap<>();
            metadata.put("document_id", chunk.getDocument().getId());
            metadata.put("document_name", chunk.getDocument().getFileName());
            metadata.put("chunk_id", chunk.getId());
            metadata.put("page_number", chunk.getPageNumber());
            metadata.put("is_table_data", chunk.getIsTableData());
            
            // Try to store in ChromaDB but don't fail if unavailable
            try {
                chromaDbService.upsert(
                        "documents",
                        List.of(chunk.getId()),
                        List.of(vector),
                        List.of(chunk.getChunkText()),
                        List.of(metadata)
                );
                log.info("Embedding stored successfully for chunk: {} in ChromaDB", chunk.getId());
            } catch (Exception chromaError) {
                // ChromaDB upsert failed, but this is not fatal
                // Documents are already stored in database and can be analyzed with full text
                log.warn("ChromaDB upsert failed for chunk {} - falling back to full text analysis: {}", 
                        chunk.getId(), chromaError.getMessage());
            }
        } catch (Exception e) {
            log.error("Failed to generate embedding for chunk: {}", chunk.getId(), e);
            throw new DocumentProcessingException("Failed to generate embedding: " + e.getMessage(), e);
        }
    }

    /**
     * Generate embedding vector for text using local Ollama.
     * @param text The text to embed (should be pre-truncated)
     * @return float array representing the embedding (1024 dims for mxbai)
     */
    public float[] getEmbeddingVector(String text) {
        if (text == null || text.isBlank()) {
            return new float[0];
        }
        return callOllamaEmbedding(text);
    }

    /**
     * Call local Ollama embeddings endpoint.
     * Model: mxbai-embed-large (1024 dimensions).
     */
    private float[] callOllamaEmbedding(String text) {
        String ollamaUrl = normalizeBaseUrl(ollamaBaseUrl);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        Map<String, Object> request = new HashMap<>();
        request.put("model", embeddingModel);
        request.put("prompt", text);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(request, headers);
        
        try {
            return executeOllamaEmbeddingRequest(ollamaUrl, entity);
        } catch (Exception e) {
            if (shouldRetryOnUnknownHost(e) && ollamaBaseUrl.contains("ollama")) {
                String fallbackUrl = normalizeBaseUrl(ollamaBaseUrl.replace("ollama", "127.0.0.1"));
                log.warn("Ollama host resolution failed for '{}', retrying with {}", ollamaBaseUrl, fallbackUrl);
                try {
                    return executeOllamaEmbeddingRequest(fallbackUrl, entity);
                } catch (Exception fallbackEx) {
                    log.error("Ollama fallback embedding request also failed: {}", fallbackEx.getMessage(), fallbackEx);
                    throw new DocumentProcessingException(
                        String.format("Embedding service error. Ensure Ollama is running and accessible at '%s'.", fallbackUrl),
                        fallbackEx
                    );
                }
            }

            log.error("Ollama embedding failed for model '{}': {}", embeddingModel, e.getMessage(), e);
            throw new DocumentProcessingException(
                String.format("Embedding service error. Ensure Ollama is running with '%s' model.", embeddingModel), 
                e
            );
        }
    }

    private String normalizeBaseUrl(String url) {
        return url.endsWith("/") ? url : url + "/";
    }

    private boolean shouldRetryOnUnknownHost(Throwable e) {
        while (e != null) {
            if (e instanceof java.net.UnknownHostException) {
                return true;
            }
            e = e.getCause();
        }
        return false;
    }

    private float[] executeOllamaEmbeddingRequest(String requestUrl, HttpEntity<Map<String, Object>> entity) {
        OllamaEmbeddingResponse response = restTemplate.postForObject(
                requestUrl + "api/embeddings",
                entity,
                OllamaEmbeddingResponse.class
        );

        if (response == null || response.getEmbedding() == null || response.getEmbedding().isEmpty()) {
            throw new DocumentProcessingException("Ollama returned empty embedding response");
        }

        List<Double> embeddingValues = response.getEmbedding();

        if (embeddingValues.size() != 1024) {
            throw new DocumentProcessingException(
                String.format("Embedding dimension mismatch: expected 1024, got %d", embeddingValues.size())
            );
        }

        float[] result = new float[embeddingValues.size()];
        for (int i = 0; i < embeddingValues.size(); i++) {
            result[i] = embeddingValues.get(i).floatValue();
        }
        return result;
    }

    /**
     * Embed a query for retrieval.
     * @param query The query text
     * @return float array embedding (1024 dims)
     */
    public float[] embedQuery(String query) {
        String truncated = truncateText(query, MAX_EMBEDDING_TEXT_LENGTH);
        return getEmbeddingVector(truncated);
    }

    /**
     * Truncate text to fit model context window.
     * Keeps first N characters to preserve semantic meaning from document start.
     */
    private String truncateText(String text, int maxLength) {
        if (text == null || text.length() <= maxLength) {
            return text;
        }
        log.warn("Truncating text from {} to {} chars for embedding", text.length(), maxLength);
        return text.substring(0, maxLength);
    }

    static class OllamaEmbeddingResponse {
        private List<Double> embedding;

        public List<Double> getEmbedding() {
            return embedding;
        }

        public void setEmbedding(List<Double> embedding) {
            this.embedding = embedding;
        }
    }
}
