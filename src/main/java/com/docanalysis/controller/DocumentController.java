package com.docanalysis.controller;

import com.docanalysis.domain.Document;
import com.docanalysis.repository.DocumentRepository;
import com.docanalysis.repository.DocumentChunkRepository;
import com.docanalysis.service.DocumentProcessingService;
import com.docanalysis.service.DocumentDeletionService;
import com.docanalysis.service.CandidateMatchingService;
import com.docanalysis.dto.CandidateMatchResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.stereotype.Component;
import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Component
@RestController
@RequestMapping("/api/documents")
@RequiredArgsConstructor
@Slf4j
public class DocumentController {
    
    private final DocumentRepository documentRepository;
    private final DocumentChunkRepository documentChunkRepository;
    private final DocumentProcessingService documentProcessingService;
    private final DocumentDeletionService documentDeletionService;
    private final CandidateMatchingService candidateMatchingService;

    @Value("${app.storage.upload-dir:./uploads}")
    private String uploadDir;
    
    @PostConstruct
    public void init() {
        log.info("*** DocumentController initialized and registered ***");
    }
    
    @GetMapping
    public ResponseEntity<?> listDocuments(
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "pageSize", defaultValue = "50") int pageSize,
            @RequestParam(value = "sortBy", defaultValue = "uploadedAt") String sortBy,
            @RequestParam(value = "sortDir", defaultValue = "DESC") String sortDir) {
        log.info("GET /api/documents called: page={}, pageSize={}, sortBy={}", page, pageSize, sortBy);
        try {
            List<Document> allDocs = documentRepository.findAll();
            
            // Sort by requested field
            if ("title".equalsIgnoreCase(sortBy)) {
                allDocs.sort((a, b) -> "DESC".equalsIgnoreCase(sortDir) ? b.getTitle().compareTo(a.getTitle()) : a.getTitle().compareTo(b.getTitle()));
            } else if ("status".equalsIgnoreCase(sortBy)) {
                allDocs.sort((a, b) -> "DESC".equalsIgnoreCase(sortDir) ? b.getStatus().compareTo(a.getStatus()) : a.getStatus().compareTo(b.getStatus()));
            } else {
                // Default: uploadedAt
                allDocs.sort((a, b) -> "DESC".equalsIgnoreCase(sortDir) ? b.getUploadedAt().compareTo(a.getUploadedAt()) : a.getUploadedAt().compareTo(b.getUploadedAt()));
            }
            
            int totalElements = allDocs.size();
            int totalPages = (totalElements + pageSize - 1) / pageSize;
            int start = page * pageSize;
            int end = Math.min(start + pageSize, totalElements);
            
            List<Document> pagedDocs = start < totalElements ? allDocs.subList(start, end) : List.of();
            List<Map<String, Object>> docsList = pagedDocs.stream().map(d -> {
                Map<String, Object> doc = new HashMap<>();
                doc.put("id", d.getId());
                doc.put("documentId", d.getId());
                doc.put("title", d.getTitle());
                doc.put("fileName", d.getFileName());
                doc.put("status", d.getStatus());
                doc.put("uploadedAt", d.getUploadedAt());
                doc.put("fileSize", d.getFileSize());
                doc.put("chunkCount", d.getChunkCount());
                return doc;
            }).collect(Collectors.toList());
            
            Map<String, Object> response = new HashMap<>();
            response.put("documents", docsList);
            response.put("totalElements", (long) totalElements);
            response.put("totalPages", totalPages);
            response.put("currentPage", page);
            response.put("pageSize", pageSize);
            response.put("hasMore", page < (totalPages - 1));
            log.debug("Returning {} documents (page {}/{})", docsList.size(), page, totalPages);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error listing documents", e);
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }
    
    @GetMapping("/list")
    public ResponseEntity<?> listDocumentsLegacy(
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "pageSize", defaultValue = "50") int pageSize) {
        log.info("GET /api/documents/list called");
        return listDocuments(page, pageSize, "uploadedAt", "DESC");
    }
    
    @PostMapping("/upload")
    public ResponseEntity<?> uploadDocument(
            @RequestParam("file") MultipartFile file,
            @RequestParam(value = "title", required = false) String title) {
        try {
            if (file.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of("error", "File is empty"));
            }
            
            String fileName = file.getOriginalFilename();
            String docTitle = title != null && !title.isEmpty() ? title : fileName;
            long fileSize = file.getSize();
            
            log.info("Uploading document: {}, title: {}, size: {} bytes", fileName, docTitle, fileSize);

            String storedFilePath = saveUpload(fileName, file);
            Document doc = documentProcessingService.processDocument(fileName, docTitle, storedFilePath);
            
            Map<String, Object> response = new HashMap<>();
            response.put("id", doc.getId());
            response.put("fileName", doc.getFileName());
            response.put("title", doc.getTitle());
            response.put("fileSize", doc.getFileSize());
            response.put("status", doc.getStatus());
            response.put("chunkCount", doc.getChunkCount());
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error uploading document", e);
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * Delete a single document by ID
     */
    @DeleteMapping("/{documentId}")
    public ResponseEntity<?> deleteDocument(@PathVariable String documentId) {
        log.info("DELETE /api/documents/{} called", documentId);
        try {
            if (documentDeletionService.deleteDocument(documentId)) {
                return ResponseEntity.ok(Map.of("message", "Document deleted successfully", "id", documentId));
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            log.error("Error deleting document: {}", documentId, e);
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * Delete multiple documents by IDs
     */
    @DeleteMapping
    public ResponseEntity<?> deleteDocuments(@RequestBody Map<String, List<String>> request) {
        List<String> documentIds = request.get("documentIds");
        log.info("DELETE /api/documents with {} documents", documentIds != null ? documentIds.size() : 0);
        
        if (documentIds == null || documentIds.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "No document IDs provided"));
        }

        try {
            int deletedCount = documentDeletionService.deleteDocuments(documentIds);
            return ResponseEntity.ok(Map.of("message", "Documents deleted", "deletedCount", deletedCount));
        } catch (Exception e) {
            log.error("Error deleting documents", e);
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * Match candidates (CVs) to requirements
     */
    @PostMapping("/match")
    public ResponseEntity<?> matchCandidates(@RequestBody Map<String, List<String>> request) {
        List<String> requirementIds = request.get("requirementIds");
        List<String> candidateIds = request.get("candidateIds");
        
        log.info("POST /api/documents/match with {} requirements and {} candidates", 
                 requirementIds != null ? requirementIds.size() : 0,
                 candidateIds != null ? candidateIds.size() : 0);
        
        if (requirementIds == null || requirementIds.isEmpty() || candidateIds == null || candidateIds.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Both requirementIds and candidateIds must be provided"));
        }

        try {
            CandidateMatchResponse response = candidateMatchingService.matchCandidatesToRequirements(requirementIds, candidateIds);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error matching candidates", e);
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    private String saveUpload(String fileName, MultipartFile file) throws IOException {
        Path uploadPath = Paths.get(uploadDir).toAbsolutePath().normalize();
        Files.createDirectories(uploadPath);

        String safeFileName = fileName == null ? "uploaded_file" : Paths.get(fileName).getFileName().toString();
        String storedFileName = System.currentTimeMillis() + "_" + safeFileName;
        Path targetPath = uploadPath.resolve(storedFileName);

        Files.copy(file.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);
        return targetPath.toString();
    }
    
    private String getFileType(String fileName) {
        if (fileName == null) return "unknown";
        int lastDot = fileName.lastIndexOf('.');
        return lastDot > 0 ? fileName.substring(lastDot + 1).toLowerCase() : "unknown";
    }
}
