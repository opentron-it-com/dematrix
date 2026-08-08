package com.docanalysis.service;

import com.docanalysis.domain.DocumentChunk;
import com.docanalysis.repository.DocumentChunkRepository;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class VectorRepositoryServiceTest {

    @Test
    void searchWithScores_usesMetadataDocumentIdWhenDatabaseChunkIsMissing() {
        DocumentChunkRepository repository = mock(DocumentChunkRepository.class);
        ChromaDbService chromaDbService = mock(ChromaDbService.class);
        VectorRepositoryService service = new VectorRepositoryService(repository, chromaDbService);

        ReflectionTestUtils.setField(service, "topK", 5);
        ReflectionTestUtils.setField(service, "similarityThreshold", 0.7);

        ChromaDbService.ChromaQueryResult result = new ChromaDbService.ChromaQueryResult();
        result.setId("chunk-1");
        result.setDocument("Chunk text from Chroma");
        result.setDistance(0.2);
        result.setMetadata(Map.of("document_id", "doc-123", "document_name", "resume.pdf"));

        when(chromaDbService.query(eq("documents"), any(float[].class), eq(5)))
                .thenReturn(List.of(result));
        when(repository.findById("chunk-1")).thenReturn(Optional.empty());

        List<VectorRepositoryService.ScoredChunk> scoredChunks =
                service.searchWithScores(new float[]{0.1f, 0.2f, 0.3f}, List.of("doc-123"));

        assertThat(scoredChunks).hasSize(1);
        assertThat(scoredChunks.get(0).chunk.getDocument().getId()).isEqualTo("doc-123");
        assertThat(scoredChunks.get(0).chunk.getChunkText()).isEqualTo("Chunk text from Chroma");
    }
}
