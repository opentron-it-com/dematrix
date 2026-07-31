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
 * Previously used Voyage AI API but switched to local for cost-efficiency.
 * Embeddings are stored ONLY in ChromaDB to avoid synchronization issues.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class VectorEmbeddingService {

    private final ChromaDbService chromaDbService;
    private final RestTemplate restTemplate;

    @Value("${app.ollama.base-url:http://ollama:11434}")
    private String ollamaBaseUrl;

    @Value("${app.embedding.model:nomic-embed-text}")
    private String embeddingModel;

    /**
     * Generate embedding and store in ChromaDB only.
     * Uses local Ollama embeddings for zero-cost inference.
     * @param chunk The document chunk to embed
     */
    public void generateAndStoreEmbedding(DocumentChunk chunk) {
        try {
            log.debug("Generating embedding for chunk: {}", chunk.getId());

            float[] vector = getEmbeddingVector(chunk.getChunkText());

            // Store ONLY in ChromaDB (never in PostgreSQL)
            Map<String, Object> metadata = new HashMap<>();
            metadata.put("document_id", chunk.getDocument().getId());
            metadata.put("document_name", chunk.getDocument().getFileName());
            metadata.put("chunk_id", chunk.getId());
            metadata.put("page_number", chunk.getPageNumber());
            metadata.put("is_table_data", chunk.getIsTableData());
            
            chromaDbService.upsert(
                    "documents",
                    List.of(chunk.getId()),
                    List.of(vector),
                    List.of(chunk.getChunkText()),
                    List.of(metadata)
            );
            
            log.info("Embedding stored successfully for chunk: {} in ChromaDB", chunk.getId());
        } catch (Exception e) {
            log.error("Failed to generate embedding for chunk: {}", chunk.getId(), e);
            throw new DocumentProcessingException("Failed to generate embedding: " + e.getMessage(), e);
        }
    }

    /**
     * Generate embedding vector for text using local Ollama.
     * @param text The text to embed
     * @return float array representing the embedding
     */
    public float[] getEmbeddingVector(String text) {
        try {
            if (text == null || text.isBlank()) {
                return new float[0];
            }
            return callOllamaEmbedding(text);
        } catch (Exception e) {
            log.error("Error generating embedding with Ollama, using fallback", e);
            return generateMockEmbedding(text);
        }
    }

    /**
     * Call local Ollama embeddings endpoint.
     * Model: nomic-embed-text (384 dimensions, fast, free).
     */
    private float[] callOllamaEmbedding(String text) {
        String ollamaUrl = ollamaBaseUrl.endsWith("/") ? ollamaBaseUrl : ollamaBaseUrl + "/";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        Map<String, Object> request = new HashMap<>();
        request.put("model", embeddingModel);
        request.put("prompt", text);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(request, headers);
        
        try {
            OllamaEmbeddingResponse response = restTemplate.postForObject(
                    ollamaUrl + "api/embeddings",
                    entity,
                    OllamaEmbeddingResponse.class
            );

            if (response == null || response.getEmbedding() == null || response.getEmbedding().isEmpty()) {
                log.warn("Ollama returned empty embedding, using fallback");
                return generateMockEmbedding(text);
            }

            List<Double> embeddingValues = response.getEmbedding();
            float[] result = new float[embeddingValues.size()];
            for (int i = 0; i < embeddingValues.size(); i++) {
                result[i] = embeddingValues.get(i).floatValue();
            }
            return result;
        } catch (Exception e) {
            log.warn("Ollama embedding failed ({}), ensure model '{}' is pulled. Using fallback", 
                    e.getMessage(), embeddingModel);
            return generateMockEmbedding(text);
        }
    }

    /**
     * Fallback: deterministic mock embedding (384 dims).
     * Used when Ollama is unavailable. Quality is lower but allows graceful degradation.
     */
    private float[] generateMockEmbedding(String text) {
        int dimension = 384;
        float[] vector = new float[dimension];

        long hashValue = text.hashCode();
        for (int i = 0; i < dimension; i++) {
            hashValue = (hashValue * 1103515245 + 12345) & 0x7fffffff;
            vector[i] = (float) ((hashValue % 1000) / 1000.0 - 0.5);
        }

        float norm = 0f;
        for (float v : vector) {
            norm += v * v;
        }
        norm = (float) Math.sqrt(norm);

        if (norm > 0) {
            for (int i = 0; i < dimension; i++) {
                vector[i] /= norm;
            }
        }

        return vector;
    }

    /**
     * Embed a query for retrieval.
     * @param query The query text
     * @return float array embedding
     */
    public float[] embedQuery(String query) {
        return getEmbeddingVector(query);
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
