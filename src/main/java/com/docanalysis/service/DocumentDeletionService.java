package com.docanalysis.service;

import com.docanalysis.domain.DocumentChunk;
import com.docanalysis.repository.DocumentRepository;
import com.docanalysis.repository.DocumentChunkRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

/**
 * Service for document deletion operations with proper transaction management.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DocumentDeletionService {
    
    private final DocumentRepository documentRepository;
    private final DocumentChunkRepository documentChunkRepository;
    
    @PersistenceContext
    private EntityManager entityManager;
    
    /**
     * Delete a single document and all associated chunks.
     * @param documentId The ID of the document to delete
     * @return true if deleted, false if not found
     */
    @Transactional
    public boolean deleteDocument(String documentId) {
        log.info("Deleting document: {}", documentId);
        
        var document = documentRepository.findById(documentId);
        if (document.isEmpty()) {
            log.warn("Document not found: {}", documentId);
            return false;
        }
        
        try {
            // Delete all associated chunks first using direct query
            var chunks = documentChunkRepository.findByDocumentId(documentId);
            for (DocumentChunk chunk : chunks) {
                entityManager.remove(entityManager.contains(chunk) ? chunk : entityManager.merge(chunk));
            }
            log.debug("Deleted {} chunks for document: {}", chunks.size(), documentId);
            
            // Delete the document
            var doc = entityManager.contains(document.get()) ? document.get() : entityManager.merge(document.get());
            entityManager.remove(doc);
            entityManager.flush();
            
            log.info("Document deleted successfully: {}", documentId);
            return true;
        } catch (Exception e) {
            log.error("Error deleting document: {}", documentId, e);
            throw new RuntimeException("Failed to delete document: " + documentId, e);
        }
    }
    
    /**
     * Delete multiple documents and all associated chunks.
     * @param documentIds List of document IDs to delete
     * @return Number of documents deleted
     */
    @Transactional
    public int deleteDocuments(java.util.List<String> documentIds) {
        log.info("Deleting {} documents", documentIds.size());
        
        int deletedCount = 0;
        for (String docId : documentIds) {
            try {
                if (deleteDocument(docId)) {
                    deletedCount++;
                }
            } catch (Exception e) {
                log.error("Failed to delete document {}: {}", docId, e.getMessage());
            }
        }
        
        log.info("Successfully deleted {} documents", deletedCount);
        return deletedCount;
    }
}
