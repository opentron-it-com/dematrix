package com.docanalysis.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;
import java.util.Set;

/**
 * Response DTO for candidate matching results.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class CandidateMatchResponse {
    private String status;
    private String message;
    private Integer totalRequirements;
    private Integer totalCandidates;
    private List<Match> matches;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Match {
        private String requirementId;
        private String requirementName;
        private String candidateId;
        private String candidateName;
        private Double matchScore;
        private Integer matchPercentage;
        private Set<String> matchedSkills;
        private Set<String> missingSkills;
        private String reasoning;
    }
}
