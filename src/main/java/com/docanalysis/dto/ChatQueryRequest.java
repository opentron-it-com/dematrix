package com.docanalysis.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ChatQueryRequest {
    
    private String query;
    private String conversationId;
    private Integer maxTokens;
    private Double temperature;
    private Boolean includeContext;
    private Boolean comprehensiveAnalysis;  // NEW: Force fetch all chunks instead of vector search
    
    @Builder.Default
    private Integer contextLimit = 5;
    
    private java.util.List<String> documentIds;
}
