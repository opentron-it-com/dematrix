package com.docanalysis.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import reactor.core.publisher.Flux;

import java.util.*;

/**
 * LLM Service using Ollama Qwen2.5:0.5B for answer generation.
 * Provides streaming completion for RAG queries with strict grounding prompts.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class LLMService {

    @Qualifier("ollamaRestTemplate")
    private final RestTemplate restTemplate;

    @Qualifier("ollamaWebClient")
    private final WebClient webClient;

    @Value("${app.ollama.base-url:http://ollama:11434}")
    private String ollamaBaseUrl;

    @Value("${app.ollama.model:qwen2.5:0.5b}")
    private String modelName;

    @Value("${app.llm.temperature:0.3}")
    private double temperature;

    /**
     * Generate streaming completion from Ollama Qwen2.5:0.5B with grounding prompt.
     * Optimized for fast inference with low temperature for deterministic output.
     * @param prompt The augmented prompt with context and question
     * @return Flux of response chunks for streaming to client
     */
    public Flux<String> streamCompletion(String prompt) {
        log.debug("Generating streaming completion with Ollama Qwen2.5:0.5B model");

        try {
            return generateOllamaStreamingResponse(prompt);
        } catch (Exception e) {
            log.error("Ollama generation failed: " + e.getMessage(), e);
            return Flux.error(e);
        }
    }

    private Flux<String> generateOllamaStreamingResponse(String prompt) {
        try {
            log.info("Calling Ollama at: {}", ollamaBaseUrl);
            String model = "qwen2.5:0.5b";
            return callOllamaGenerateStream(prompt, model)
                    .filter(response -> response.getResponse() != null && !response.getResponse().isBlank())
                    .map(OllamaStreamResponse::getResponse)
                    .switchIfEmpty(Flux.error(new RuntimeException("Ollama returned empty response")))
                    .doOnNext(chunk -> log.debug("Received Ollama stream chunk of {} characters", chunk.length()))
                    .doOnComplete(() -> log.info("Ollama streaming response completed"));
        } catch (Exception e) {
            log.error("Ollama API generation failed: {}", e.getMessage(), e);
            return Flux.error(e);
        }
    }

    private Flux<OllamaStreamResponse> callOllamaGenerateStream(String prompt, String model) {
        String ollamaUrl = ollamaBaseUrl.endsWith("/") ? ollamaBaseUrl : ollamaBaseUrl + "/";

        Map<String, Object> request = new LinkedHashMap<>();
        request.put("model", model);
        request.put("prompt", prompt);
        request.put("temperature", temperature);
        request.put("stream", true);

        log.debug("Using Ollama model for streaming: {}", model);
        return webClient.post()
                .uri(ollamaUrl + "api/generate")
                .contentType(MediaType.APPLICATION_JSON)
                .accept(MediaType.APPLICATION_NDJSON, MediaType.APPLICATION_JSON)
                .bodyValue(request)
                .retrieve()
                .bodyToFlux(OllamaStreamResponse.class);
    }

    static class OllamaResponse {
        private String response;
        private String error;

        public String getResponse() {
            return response;
        }

        public void setResponse(String response) {
            this.response = response;
        }

        public String getError() {
            return error;
        }

        public void setError(String error) {
            this.error = error;
        }
    }

    static class OllamaStreamResponse {
        private String response;
        private boolean done;
        private String error;

        public String getResponse() {
            return response;
        }

        public void setResponse(String response) {
            this.response = response;
        }

        public boolean isDone() {
            return done;
        }

        public void setDone(boolean done) {
            this.done = done;
        }

        public String getError() {
            return error;
        }

        public void setError(String error) {
            this.error = error;
        }
    }
}
