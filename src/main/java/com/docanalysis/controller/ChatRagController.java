package com.docanalysis.controller;

import com.docanalysis.dto.ChatQueryRequest;
import com.docanalysis.dto.ChatStreamResponse;
import com.docanalysis.service.RAGGenerationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

import reactor.core.publisher.Flux;

/**
 * Chat RAG Controller - Handles RAG queries and document analysis.
 * Returns server-sent events for incremental chat updates.
 */
@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
@Slf4j
public class ChatRagController {
    
    private final RAGGenerationService ragGenerationService;
    
    /**
     * Chat endpoint - SSE streaming response.
     * Uses vector search to find relevant chunks.
     * @param request Chat query request with query, conversationId, and optional documentIds filter
     * @return Flux of streaming chat events
     */
    @PostMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<ServerSentEvent<ChatStreamResponse>> streamChatResponse(@RequestBody ChatQueryRequest request) {
        log.info("Chat stream request received: {} (conversation: {})", 
                request.getQuery(), request.getConversationId());
        
        if (request.getQuery() == null || request.getQuery().trim().isEmpty()) {
            log.warn("Empty query received");
            return Flux.just(ServerSentEvent.<ChatStreamResponse>builder()
                .event("error")
                .data(ChatStreamResponse.builder()
                    .status("error")
                    .error("Query must not be empty")
                    .isFinished(true)
                    .build())
                .build());
        }
        
        String conversationId = request.getConversationId() != null ? 
                request.getConversationId() : generateConversationId();
        
        log.debug("Starting RAG generation for conversation: {} with {} documents", conversationId, 
                request.getDocumentIds() != null ? request.getDocumentIds().size() : "all");

        Boolean comprehensiveAnalysis = request.getComprehensiveAnalysis() != null ? request.getComprehensiveAnalysis() : false;

        return ragGenerationService.generateStreamingResponse(request.getQuery(), conversationId, request.getDocumentIds(), comprehensiveAnalysis)
            .map(response -> ServerSentEvent.builder(response).build())
            .onErrorResume(e -> {
                log.error("Error during chat: {}", e.getMessage(), e);
                ChatStreamResponse errorResponse = ChatStreamResponse.builder()
                    .chunk("Error: Could not generate response. " + e.getMessage())
                    .status("error")
                    .conversationId(conversationId)
                    .error(e.getMessage())
                    .isFinished(true)
                    .build();
                return Flux.just(ServerSentEvent.<ChatStreamResponse>builder()
                    .event("error")
                    .data(errorResponse)
                    .build());
            })
            .doOnComplete(() -> log.info("Stream completed for conversation: {}", conversationId));
    }
    
    /**
     * Analyze endpoint - SSE streaming response.
     * @param request Chat query request with query, conversationId, and documentIds
     * @return Flux of streaming chat events
     */
    @PostMapping(value = "/analyze", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<ServerSentEvent<ChatStreamResponse>> analyzeDocuments(@RequestBody ChatQueryRequest request) {
        log.info("Document analyze request received: {} (conversation: {})", 
                request.getQuery(), request.getConversationId());
        
        if (request.getQuery() == null || request.getQuery().trim().isEmpty()) {
            log.warn("Empty query received");
            return Flux.just(ServerSentEvent.<ChatStreamResponse>builder()
                .event("error")
                .data(ChatStreamResponse.builder()
                    .status("error")
                    .error("Query must not be empty")
                    .isFinished(true)
                    .build())
                .build());
        }
        
        if (request.getDocumentIds() == null || request.getDocumentIds().isEmpty()) {
            log.warn("No documents selected for analysis");
            return Flux.just(ServerSentEvent.<ChatStreamResponse>builder()
                .event("error")
                .data(ChatStreamResponse.builder()
                    .status("error")
                    .error("Please select at least one document to analyze")
                    .isFinished(true)
                    .build())
                .build());
        }
        
        String conversationId = request.getConversationId() != null ? 
                request.getConversationId() : generateConversationId();
        
        log.info("Starting analysis flow for {} documents", request.getDocumentIds().size());

        return ragGenerationService.generateStreamingResponse(request.getQuery(), conversationId, request.getDocumentIds(), true)
            .map(response -> ServerSentEvent.builder(response).build())
            .onErrorResume(e -> {
                log.error("Error during document analysis: {}", e.getMessage(), e);
                ChatStreamResponse errorResponse = ChatStreamResponse.builder()
                    .chunk("Error: Could not analyze documents. " + e.getMessage())
                    .status("error")
                    .conversationId(conversationId)
                    .error(e.getMessage())
                    .isFinished(true)
                    .build();
                return Flux.just(ServerSentEvent.<ChatStreamResponse>builder()
                    .event("error")
                    .data(errorResponse)
                    .build());
            })
            .doOnComplete(() -> log.info("Analysis stream completed for conversation: {}", conversationId));
    }
    
    /**
     * Health check endpoint.
     * @return Health status
     */
    @GetMapping("/health")
    public Map<String, String> health() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "chat-rag");
        return response;
    }
    
    private String generateConversationId() {
        return "conv-" + System.currentTimeMillis();
    }
}
