package com.docanalysis.service;

import com.docanalysis.domain.Document;
import com.docanalysis.domain.DocumentChunk;
import com.docanalysis.dto.ChatStreamResponse;
import com.docanalysis.repository.DocumentChunkRepository;
import com.docanalysis.repository.DocumentRepository;
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
 * 1. For comprehensive analysis: fetch ALL chunks from selected documents
 * 2. For regular queries: Embed user query, retrieve top-K chunks from ChromaDB
 * 3. Build augmented prompt for fast inference
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
    private final DocumentChunkRepository documentChunkRepository;
    private final DocumentRepository documentRepository;
    
    @Value("${app.search.top-k:3}")
    private int contextLimit;
    
    /**
     * Generate streaming RAG response for user query, filtered by selected documents.
     * @param userQuery The natural language question
     * @param conversationId Conversation ID for tracking
     * @param documentIds Optional list of document IDs to filter by
     * @param comprehensiveAnalysis If true, fetch ALL chunks instead of vector search
     * @return Flux of streaming response chunks
     */
    public Flux<ChatStreamResponse> generateStreamingResponse(String userQuery, String conversationId, 
                                                             List<String> documentIds, Boolean comprehensiveAnalysis) {
        log.info("Starting RAG generation for query: {} with {} documents (comprehensive: {})", userQuery, 
                documentIds != null ? documentIds.size() : "all", comprehensiveAnalysis);
        
        try {
            List<DocumentChunk> contextChunks;
            
            if (Boolean.TRUE.equals(comprehensiveAnalysis) && documentIds != null && !documentIds.isEmpty()) {
                // Fetch ALL chunks from selected documents
                log.info("Comprehensive analysis mode: fetching all chunks from {} documents", documentIds.size());
                contextChunks = documentIds.stream()
                        .flatMap(docId -> documentChunkRepository.findByDocumentId(docId).stream())
                        .collect(Collectors.toList());
                log.info("Retrieved {} chunks in comprehensive mode", contextChunks.size());
            } else {
                // Standard vector search mode
                float[] queryVector = vectorEmbeddingService.embedQuery(userQuery);
                log.debug("Query vector generated: {} dimensions", queryVector.length);
                contextChunks = vectorRepositoryService.searchRelevantContexts(queryVector, documentIds);
                log.debug("Retrieved {} context chunks via vector search", contextChunks.size());
            }

            if (contextChunks.isEmpty() && documentIds != null && !documentIds.isEmpty()) {
                log.info("Vector search returned no usable chunks; falling back to repository chunks for {} documents", documentIds.size());
                contextChunks = documentIds.stream()
                        .flatMap(docId -> documentChunkRepository.findByDocumentId(docId).stream())
                        .collect(Collectors.toList());
                log.info("Repository fallback retrieved {} chunks", contextChunks.size());
            }
            
            if (contextChunks.isEmpty()) {
                log.warn("No relevant chunks found for query - proceeding with generic response");
                return Flux.just(ChatStreamResponse.builder()
                        .chunk("No documents have been uploaded yet or no relevant information was found in the selected documents. Please upload documents or select different documents to enable document analysis.")
                        .status("completed")
                        .conversationId(conversationId)
                        .timestamp(LocalDateTime.now())
                        .citations(Collections.emptyList())
                        .build());
            }
            
            final List<DocumentChunk> selectedContextChunks = contextChunks;

            // Build augmented prompt for fast inference
            String augmentedPrompt = buildAugmentedPrompt(userQuery, selectedContextChunks);
            log.debug("Augmented prompt length: {} characters", augmentedPrompt.length());
            
            // Stream response from LLM
            return llmService.streamCompletion(augmentedPrompt)
                    .map(chunk -> buildStreamingResponse(chunk, selectedContextChunks, conversationId, false))
                    .concatWith(Mono.fromCallable(() -> 
                            buildStreamingResponse("", selectedContextChunks, conversationId, true)
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
     * Overload for backward compatibility
     */
    public Flux<ChatStreamResponse> generateStreamingResponse(String userQuery, String conversationId, List<String> documentIds) {
        return generateStreamingResponse(userQuery, conversationId, documentIds, false);
    }
    
    /**
     * Build augmented prompt optimized for fast inference.
     * Uses minimal tokens for Qwen2.5:0.5B speed.
     * @param userQuery The user's question
     * @param contextChunks Retrieved document chunks
     * @return Formatted prompt for LLM
     */
    private String buildAugmentedPrompt(String userQuery, List<DocumentChunk> contextChunks) {
        StringBuilder promptBuilder = new StringBuilder(2048);
        
        // Check if this is a requirements/analysis query
        boolean isAnalysisQuery = userQuery.toLowerCase().contains("analyze") || 
                                 userQuery.toLowerCase().contains("technolog") ||
                                 userQuery.toLowerCase().contains("experience") ||
                                 userQuery.toLowerCase().contains("requirement") ||
                                 userQuery.toLowerCase().contains("responsibility") ||
                                 userQuery.toLowerCase().contains("salary") ||
                                 userQuery.length() > 100;
        
        if (isAnalysisQuery) {
            promptBuilder.append("You are a job requirements analyzer. Extract and summarize information from the provided documents.\n");
            promptBuilder.append("Use only the document content below. Do not invent facts.\n");
            promptBuilder.append("If a detail is not present in the documents, say 'Not explicitly stated in the provided documents.'\n");
            promptBuilder.append("Format clearly with headers for each section.\n\n");
        } else {
            promptBuilder.append("You are answering from the provided documents only.\n");
            promptBuilder.append("Use the document content below. If the answer is missing, say: 'Not explicitly stated in the provided documents.'\n\n");
        }
        
        // Add ALL context sections
        promptBuilder.append("DOCUMENTS:\n");
        
        for (int i = 0; i < contextChunks.size(); i++) {
            DocumentChunk chunk = contextChunks.get(i);
            promptBuilder.append("\n--- Document ").append(i + 1).append(" ---\n");
            promptBuilder.append("File: ").append(chunk.getDocument().getFileName()).append("\n");
            if (chunk.getPageNumber() != null) {
                promptBuilder.append("Page: ").append(chunk.getPageNumber()).append("\n");
            }
            promptBuilder.append(chunk.getChunkText()).append("\n");
        }
        
        // Add question
        promptBuilder.append("\nQuestion: ").append(userQuery).append("\n");
        promptBuilder.append("Answer:");
        
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
