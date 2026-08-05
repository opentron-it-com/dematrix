package com.docanalysis.service;

import com.docanalysis.domain.Document;
import com.docanalysis.domain.DocumentChunk;
import com.docanalysis.dto.CandidateMatchResponse;
import com.docanalysis.repository.DocumentRepository;
import com.docanalysis.repository.DocumentChunkRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Service for matching CVs to Client Requirements.
 * Extracts skills/terms from both and performs semantic matching.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CandidateMatchingService {
    
    private final DocumentRepository documentRepository;
    private final DocumentChunkRepository documentChunkRepository;
    private final VectorRepositoryService vectorRepositoryService;
    private final VectorEmbeddingService vectorEmbeddingService;
    
    /**
     * Match candidates (CVs) to requirements.
     * @param requirementIds List of requirement document IDs
     * @param candidateIds List of candidate document IDs
     * @return Structured matching results
     */
    public CandidateMatchResponse matchCandidatesToRequirements(List<String> requirementIds, List<String> candidateIds) {
        log.info("Matching {} candidates to {} requirements", candidateIds.size(), requirementIds.size());
        
        try {
            List<Document> requirements = requirementIds.stream()
                    .map(documentRepository::findById)
                    .filter(Optional::isPresent)
                    .map(Optional::get)
                    .collect(Collectors.toList());
            
            List<Document> candidates = candidateIds.stream()
                    .map(documentRepository::findById)
                    .filter(Optional::isPresent)
                    .map(Optional::get)
                    .collect(Collectors.toList());
            
            if (requirements.isEmpty() || candidates.isEmpty()) {
                return CandidateMatchResponse.builder()
                        .status("error")
                        .message("Requirements or candidates not found")
                        .matches(Collections.emptyList())
                        .build();
            }
            
            // Extract key terms from requirements
            Map<String, RequirementProfile> requirementProfiles = extractRequirementProfiles(requirements);
            log.debug("Extracted profiles for {} requirements", requirementProfiles.size());
            
            // Extract key terms from candidates
            Map<String, CandidateProfile> candidateProfiles = extractCandidateProfiles(candidates);
            log.debug("Extracted profiles for {} candidates", candidateProfiles.size());
            
            // Perform matching
            List<CandidateMatchResponse.Match> matches = performMatching(requirementProfiles, candidateProfiles);
            
            return CandidateMatchResponse.builder()
                    .status("success")
                    .message("Matching completed")
                    .totalRequirements(requirements.size())
                    .totalCandidates(candidates.size())
                    .matches(matches)
                    .build();
        } catch (Exception e) {
            log.error("Error in candidate matching", e);
            return CandidateMatchResponse.builder()
                    .status("error")
                    .message("Matching failed: " + e.getMessage())
                    .matches(Collections.emptyList())
                    .build();
        }
    }
    
    /**
     * Extract key skills/terms from requirement documents.
     */
    private Map<String, RequirementProfile> extractRequirementProfiles(List<Document> requirements) {
        Map<String, RequirementProfile> profiles = new HashMap<>();
        
        for (Document req : requirements) {
            List<DocumentChunk> chunks = documentChunkRepository.findByDocumentId(req.getId());
            String fullText = chunks.stream()
                    .map(DocumentChunk::getChunkText)
                    .collect(Collectors.joining(" "));
            
            // Extract key terms
            Set<String> skills = extractKeyTerms(fullText);
            
            profiles.put(req.getId(), RequirementProfile.builder()
                    .documentId(req.getId())
                    .documentName(req.getFileName())
                    .fullText(fullText.substring(0, Math.min(500, fullText.length())))
                    .skills(skills)
                    .build());
        }
        
        return profiles;
    }
    
    /**
     * Extract key skills/terms from candidate documents (CVs).
     */
    private Map<String, CandidateProfile> extractCandidateProfiles(List<Document> candidates) {
        Map<String, CandidateProfile> profiles = new HashMap<>();
        
        for (Document cand : candidates) {
            List<DocumentChunk> chunks = documentChunkRepository.findByDocumentId(cand.getId());
            String fullText = chunks.stream()
                    .map(DocumentChunk::getChunkText)
                    .collect(Collectors.joining(" "));
            
            // Extract key terms
            Set<String> skills = extractKeyTerms(fullText);
            
            profiles.put(cand.getId(), CandidateProfile.builder()
                    .documentId(cand.getId())
                    .documentName(cand.getFileName())
                    .fullText(fullText.substring(0, Math.min(500, fullText.length())))
                    .skills(skills)
                    .build());
        }
        
        return profiles;
    }
    
    /**
     * Extract key technical and non-technical terms from text.
     * Looks for programming languages, frameworks, tools, roles, etc.
     */
    private Set<String> extractKeyTerms(String text) {
        Set<String> terms = new HashSet<>();
        String lowerText = text.toLowerCase();
        
        // Common tech keywords
        String[] keywords = {
            "java", "python", "javascript", "typescript", "go", "golang", "rust", "c++", "c#",
            "react", "angular", "vue", "spring", "spring boot", "django", "flask",
            "kubernetes", "docker", "microservices", "rest api", "graphql",
            "postgres", "mysql", "mongodb", "redis", "elasticsearch",
            "aws", "gcp", "azure", "cloud",
            "ci/cd", "devops", "terraform", "ansible",
            "frontend", "backend", "fullstack", "full-stack",
            "senior", "junior", "lead", "architect", "developer", "engineer",
            "agile", "scrum", "git", "linux", "unix", "sql", "nosql",
            "testing", "junit", "pytest", "jest", "automation",
            "html", "css", "node", "npm", "maven", "gradle",
            "payment", "ecommerce", "fintech", "analytics", "machine learning", "ml",
            "mobile", "android", "ios", "react native", "flutter"
        };
        
        for (String keyword : keywords) {
            if (lowerText.contains(keyword)) {
                terms.add(keyword);
            }
        }
        
        return terms;
    }
    
    /**
     * Perform semantic matching between requirements and candidates.
     */
    private List<CandidateMatchResponse.Match> performMatching(
            Map<String, RequirementProfile> requirementProfiles,
            Map<String, CandidateProfile> candidateProfiles) {
        
        List<CandidateMatchResponse.Match> matches = new ArrayList<>();
        
        for (RequirementProfile req : requirementProfiles.values()) {
            for (CandidateProfile cand : candidateProfiles.values()) {
                // Calculate match score based on skill overlap
                double matchScore = calculateMatchScore(req.getSkills(), cand.getSkills());
                
                if (matchScore > 0) {
                    Set<String> matchedSkills = new HashSet<>(req.getSkills());
                    matchedSkills.retainAll(cand.getSkills());
                    
                    Set<String> missingSkills = new HashSet<>(req.getSkills());
                    missingSkills.removeAll(cand.getSkills());
                    
                    matches.add(CandidateMatchResponse.Match.builder()
                            .requirementId(req.getDocumentId())
                            .requirementName(req.getDocumentName())
                            .candidateId(cand.getDocumentId())
                            .candidateName(cand.getDocumentName())
                            .matchScore(Math.round(matchScore * 100.0) / 100.0)
                            .matchPercentage((int)(matchScore * 100))
                            .matchedSkills(matchedSkills)
                            .missingSkills(missingSkills)
                            .reasoning(generateReasoning(req, cand, matchedSkills, missingSkills))
                            .build());
                }
            }
        }
        
        // Sort by match score (descending)
        matches.sort((a, b) -> Double.compare(b.getMatchScore(), a.getMatchScore()));
        
        return matches;
    }
    
    /**
     * Calculate match score based on skill overlap.
     */
    private double calculateMatchScore(Set<String> requiredSkills, Set<String> candidateSkills) {
        if (requiredSkills.isEmpty()) {
            return 0.0;
        }
        
        Set<String> intersection = new HashSet<>(requiredSkills);
        intersection.retainAll(candidateSkills);
        
        return (double) intersection.size() / requiredSkills.size();
    }
    
    /**
     * Generate human-readable reasoning for a match.
     */
    private String generateReasoning(RequirementProfile req, CandidateProfile cand, 
                                     Set<String> matched, Set<String> missing) {
        StringBuilder reasoning = new StringBuilder();
        
        if (matched.isEmpty()) {
            reasoning.append("No direct skill matches found. ");
        } else if (matched.size() == req.getSkills().size()) {
            reasoning.append("Excellent match! Candidate has all required skills: ");
            reasoning.append(String.join(", ", matched)).append(". ");
        } else {
            reasoning.append("Good match with ").append(matched.size()).append("/")
                    .append(req.getSkills().size()).append(" required skills. ");
            reasoning.append("Matched: ").append(String.join(", ", matched));
            if (!missing.isEmpty()) {
                reasoning.append(". Missing: ").append(String.join(", ", missing));
            }
            reasoning.append(". ");
        }
        
        return reasoning.toString();
    }
    
    @lombok.Data
    @lombok.Builder
    private static class RequirementProfile {
        private String documentId;
        private String documentName;
        private String fullText;
        private Set<String> skills;
    }
    
    @lombok.Data
    @lombok.Builder
    private static class CandidateProfile {
        private String documentId;
        private String documentName;
        private String fullText;
        private Set<String> skills;
    }
}
