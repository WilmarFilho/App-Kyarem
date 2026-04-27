package com.kyarem.realtime.controller;

import com.kyarem.realtime.hub.MatchEventHub;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;

import java.time.Duration;

/**
 * Expõe o endpoint SSE público:
 *
 *   GET /events/{matchId}
 *   Accept: text/event-stream
 *
 * O app público (web/mobile) conecta aqui para receber atualizações
 * em tempo real de placar, eventos e status da partida.
 *
 * Heartbeat a cada 30s mantém a conexão viva e permite que o cliente
 * detecte desconexões e reconecte com a versao_estado para verificar
 * se perdeu eventos durante a oscilação.
 */
@RestController
@RequestMapping("/events")
@CrossOrigin(origins = "*")   // ajustar para domínios específicos em produção
public class SseController {

    private final MatchEventHub hub;

    public SseController(MatchEventHub hub) {
        this.hub = hub;
    }

    @GetMapping(value = "/{matchId}", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<ServerSentEvent<String>> streamMatchEvents(@PathVariable String matchId) {

        Flux<ServerSentEvent<String>> events = hub.subscribeToMatch(matchId)
                .map(payload -> ServerSentEvent.<String>builder()
                        .event("match-update")
                        .data(payload)
                        .build());

        // Heartbeat a cada 30s para evitar timeout de proxies/firewalls
        Flux<ServerSentEvent<String>> heartbeat = Flux.interval(Duration.ofSeconds(30))
                .map(tick -> ServerSentEvent.<String>builder()
                        .event("heartbeat")
                        .data("{\"status\":\"alive\"}")
                        .build());

        return Flux.merge(events, heartbeat);
    }

    /**
     * Endpoint de saúde simples para o nginx e healthcheck do Docker.
     */
    @GetMapping("/health")
    public String health() {
        return "OK";
    }
}
