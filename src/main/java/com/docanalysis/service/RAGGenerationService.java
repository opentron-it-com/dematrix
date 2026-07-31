package com.docanalysis.service;

import com.docanalysis.domain.DocumentChunk;
import com.docanalysis.dto.ChatStreamResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * RAG Generation Service - Orchestrates the retrieval-augmented generation pipeline.
 * 
 * Optimized for fast inference with Qwen2.5:0.5B.
 * Flow:
 * 1. Embed user query
 * 2. Retrieve top-3 chunks from ChromaDB (reduced for speed)
 * 3. Build compact prompt for fast inference
 * 4. Stream response from Qwen2.5:0.5B LLM
 * 5. Attach citations to response
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class RAGGenerationService {
    
    private final VectorRepositoryService vectorRepositoryService;
    private final VectorEmbeddingService vectorEmbeddingService;
    private final LLMService llmService;
    
    @Value("${app.search.top-k:3}")
    private int contextLimit;
    
    /**
     * Generate streaming RAG response for user query.
     * @param userQuery The natural language question
     * @param conversationId Conversation ID for tracking
     * @return Flux of streaming response chunks
     */
    public Flux<ChatStreamResponse> generateStreamingResponse(String userQuery, String conversationId) {
        log.info("Starting RAG generation for query: {}", userQuery);
        
        try {
            // Step 1: Embed the user query using Voyage
            float[] queryVector = vectorEmbeddingService.embedQuery(userQuery);
            log.debug("Query vector generated: {} dimensions", queryVector.length);
            
            // Step 2: Retrieve relevant contexts from Chroma (top-3 for speed)
            List<DocumentChunk> contextChunks = vectorRepositoryService.searchRelevantContexts(queryVector);
            log.debug("Retrieved {} context chunks", contextChunks.size());
            
            if (contextChunks.isEmpty()) {
                log.warn("No relevant chunks found for query - proceeding with generic response");
                return Flux.just(ChatStreamResponse.builder()
                        .chunk("No documents have been uploaded yet or no relevant information was found. Please upload documents to enable document analysis.")
                        .status("completed")
                        .conversationId(conversationId)
                        .timestamp(LocalDateTime.now())
                        .citations(Collections.emptyList())
                        .build());
            }
            
            // Step 3: Build compact augmented prompt for fast inference
            String augmentedPrompt = buildAugmentedPrompt(userQuery, contextChunks);
            log.debug("Augmented prompt length: {} characters", augmentedPrompt.length());
            
            // Step 4: Stream response from LLM
            return llmService.streamCompletion(augmentedPrompt)
                    .map(chunk -> buildStreamingResponse(chunk, contextChunks, conversationId, false))
                    .concatWith(Mono.fromCallable(() -> 
                            buildStreamingResponse("", contextChunks, conversationId, true)
                    ))
                    .doOnError(e -> log.error("Error during RAG generation", e));
        } catch (Exception e) {
            log.error("Error in RAG generation: {}", e.getMessage(), e);
            return Flux.just(ChatStreamResponse.builder()
                    .status("error")
                    .error(e.getMessage())
                    .conversationId(conversationId)
                    .timestamp(LocalDateTime.now())
                    .build());
        }
    }
    
    /**
     * Build compact augmented prompt optimized for fast inference.
     * Uses minimal tokens for Qwen2.5:0.5B speed.
     * @param userQuery The user's question
     * @param contextChunks Retrieved document chunks
     * @return Formatted prompt for LLM
     */
    private String buildAugmentedPrompt(String userQuery, List<DocumentChunk> contextChunks) {
        StringBuilder promptBuilder = new StringBuilder(512);
        
        // Shorter system prompt for faster inference
        promptBuilder.append("Answer from the context only.\n");
        promptBuilder.append("If not found, say: \"Not in documents.\"\n\n");
        
        // Add context sections - compact format
        promptBuilder.append("CONTEXT:\n");
        
        for (int i = 0; i < contextChunks.size(); i++) {
            DocumentChunk chunk = contextChunks.get(i);
            promptBuilder.append("[").append(i + 1).append("] ");
            promptBuilder.append(chunk.getDocument().getFileName());
            if (chunk.getPageNumber() != null) {
                promptBuilder.append(" p.").append(chunk.getPageNumber());
            }
            promptBuilder.append(":\n");
            promptBuilder.append(chunk.getChunkText()).append("\n\n");
        }
        
        // Add question
        promptBuilder.append("Q: ").append(userQuery).append("\n");
        promptBuilder.append("A:");
        
        return promptBuilder.toString();
    }
    
    /**
     * Build streaming response chunk with citations.
     * @param chunk Text chunk from LLM
     * @param contextChunks Source chunks for citations
     * @param conversationId Conversation ID
     * @param isFinished Whether this is the final chunk
     * @return ChatStreamResponse DTO
     */
    private ChatStreamResponse buildStreamingResponse(String chunk, 
                                                     List<DocumentChunk> contextChunks,
                                                     String conversationId,
                                                     boolean isFinished) {
        List<ChatStreamResponse.Citation> citations = contextChunks.stream()
                .map(chunkData -> ChatStreamResponse.Citation.builder()
                        .documentId(chunkData.getDocument().getId())
                        .documentName(chunkData.getDocument().getFileName())
                        .chunkId(chunkData.getId())
                        .contentSnippet(truncate(chunkData.getChunkText(), 100))
                        .pageNumber(chunkData.getPageNumber())
                        .tableCoordinates(chunkData.getIsTableData() ? "table-data" : null)
                        .build())
                .collect(Collectors.toList());
        
        return ChatStreamResponse.builder()
                .chunk(chunk)
                .role("assistant")
                .status(isFinished ? "completed" : "streaming")
                .citations(isFinished ? citations : Collections.emptyList())
                .conversationId(conversationId)
                .timestamp(LocalDateTime.now())
                .isFinished(isFinished)
                .build();
    }
    
    private String truncate(String text, int maxLength) {
        return text.length() > maxLength ? text.substring(0, maxLength) + "..." : text;
    }
}
