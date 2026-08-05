package com.docanalysis.service;

import com.docanalysis.domain.Document;
import com.docanalysis.domain.DocumentChunk;
import com.docanalysis.exception.DocumentProcessingException;
import com.docanalysis.repository.DocumentRepository;
import com.docanalysis.repository.DocumentChunkRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.text.PDFTextStripper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.*;

/**
 * Handles document processing: extraction, chunking, and embedding generation.
 * Uses word-based chunking for PDF reliability (not paragraph-based).
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class DocumentProcessingService {
    
    private final DocumentRepository documentRepository;
    private final DocumentChunkRepository documentChunkRepository;
    private final VectorEmbeddingService vectorEmbeddingService;
    
    @Value("${app.chunking.chunk-size:1024}")
    private int chunkSize;
    
    @Value("${app.chunking.chunk-overlap:100}")
    private int chunkOverlap;
    
    @Value("${app.chunking.min-chunk-size:200}")
    private int minChunkSize;
    
    /**
     * Process a document: extract text, chunk, and generate embeddings.
     * @param fileName Original file name
     * @param title Display title
     * @param filePath Path to uploaded file
     * @return Processed document entity
     */
    public Document processDocument(String fileName, String title, String filePath) {
        try {
            log.info("Starting document processing: {}", fileName);
            
            Document document = Document.builder()
                    .fileName(fileName)
                    .title(title)
                    .filePathRef(filePath)
                    .status("PROCESSING")
                    .fileType(extractFileType(fileName))
                    .fileSize(getFileSize(filePath))
                    .build();
            
            document = documentRepository.save(document);
            log.info("Document entity created with ID: {}", document.getId());
            
            // Extract text based on file type
            String extractedText;
            if (fileName.toLowerCase().endsWith(".pdf")) {
                extractedText = extractTextFromPDF(filePath);
            } else if (fileName.toLowerCase().endsWith(".txt")) {
                extractedText = new String(Files.readAllBytes(Paths.get(filePath)));
            } else {
                throw new DocumentProcessingException("Unsupported file format");
            }
            
            log.info("Extracted text length: {} chars", extractedText.length());
            document.setExtractedText(extractedText);
            
            // Perform word-based chunking (more reliable than paragraph-based)
            List<DocumentChunk> chunks = performWordBasedChunking(document, extractedText);
            log.info("Created {} chunks for document: {}", chunks.size(), document.getId());
            
            document.setChunkCount(chunks.size());
            document.setStatus("INDEXED");
            document = documentRepository.save(document);
            
            // Generate embeddings for all chunks
            for (DocumentChunk chunk : chunks) {
                try {
                    vectorEmbeddingService.generateAndStoreEmbedding(chunk);
                } catch (Exception e) {
                    log.error("Failed to embed chunk {}: {}", chunk.getId(), e.getMessage());
                    throw e;
                }
            }
            
            log.info("Document processing completed: {} ({} chunks indexed)", document.getId(), chunks.size());
            return document;
        } catch (Exception e) {
            log.error("Error processing document: {}", fileName, e);
            throw new DocumentProcessingException("Failed to process document: " + e.getMessage(), e);
        }
    }
    
    /**
     * Split text into chunks by word boundaries.
     * More reliable than paragraph-splitting for PDFs.
     */
    private List<DocumentChunk> performWordBasedChunking(Document document, String text) {
        List<DocumentChunk> chunks = new ArrayList<>();
        
        // Split by whitespace to get words/tokens
        String[] tokens = text.split("\\s+");
        log.debug("Total tokens: {}", tokens.length);
        
        StringBuilder currentChunk = new StringBuilder();
        int sequenceOrder = 0;
        int pageNumber = 1;
        int charOffset = 0;
        
        for (String token : tokens) {
            if (token.isEmpty()) {
                continue;
            }
            
            // Check if adding token exceeds chunk size
            int potentialLength = currentChunk.length() + token.length() + 1;
            
            if (potentialLength > chunkSize && currentChunk.length() > minChunkSize) {
                // Save current chunk
                String chunkText = currentChunk.toString().trim();
                if (!chunkText.isEmpty()) {
                    DocumentChunk chunk = DocumentChunk.builder()
                            .document(document)
                            .chunkText(chunkText)
                            .sequenceOrder(sequenceOrder++)
                            .pageNumber(pageNumber)
                            .startOffset((long) charOffset)
                            .endOffset((long) (charOffset + chunkText.length()))
                            .isTableData(detectTableData(chunkText))
                            .build();
                    
                    chunks.add(documentChunkRepository.save(chunk));
                    log.debug("Saved chunk {}: {} chars", sequenceOrder - 1, chunkText.length());
                    
                    charOffset += chunkText.length();
                }
                
                currentChunk = new StringBuilder(token);
                
                // Update page number
                if (charOffset > 3000 * pageNumber) {
                    pageNumber++;
                }
            } else {
                if (currentChunk.length() > 0) {
                    currentChunk.append(" ");
                }
                currentChunk.append(token);
            }
        }
        
        // Save final chunk
        String finalChunkText = currentChunk.toString().trim();
        if (finalChunkText.length() > minChunkSize) {
            DocumentChunk chunk = DocumentChunk.builder()
                    .document(document)
                    .chunkText(finalChunkText)
                    .sequenceOrder(sequenceOrder)
                    .pageNumber(pageNumber)
                    .startOffset((long) charOffset)
                    .endOffset((long) (charOffset + finalChunkText.length()))
                    .isTableData(detectTableData(finalChunkText))
                    .build();
            
            chunks.add(documentChunkRepository.save(chunk));
            log.debug("Saved final chunk {}: {} chars", sequenceOrder, finalChunkText.length());
        }
        
        return chunks;
    }
    
    private boolean detectTableData(String text) {
        int pipeCount = text.split("\\|", -1).length - 1;
        int tabCount = text.split("\t", -1).length - 1;
        return pipeCount > 2 || tabCount > 2;
    }
    
    private String extractTextFromPDF(String filePath) throws IOException {
        var document = Loader.loadPDF(new File(filePath));
        try {
            PDFTextStripper stripper = new PDFTextStripper();
            return stripper.getText(document);
        } finally {
            document.close();
        }
    }
    
    private String extractFileType(String fileName) {
        int dotIndex = fileName.lastIndexOf('.');
        return dotIndex > 0 ? fileName.substring(dotIndex + 1).toUpperCase() : "UNKNOWN";
    }
    
    private long getFileSize(String filePath) {
        try {
            return Files.size(Paths.get(filePath));
        } catch (IOException e) {
            log.warn("Could not determine file size: {}", filePath);
            return 0L;
        }
    }
}
