package com.kyarem.realtime.hub;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Sinks;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Hub central de SSE.
 *
 * Mantém um Sinks.Many por partida ativa.
 * O RabbitMQ listener publica mensagens aqui; o SseController as entrega aos clientes.
 *
 * Cada cliente (app público) abre uma conexão SSE para /events/{matchId}
 * e recebe atualizações em tempo real enquanto a partida estiver ativa.
 */
@Component
public class MatchEventHub {

    private static final Logger log = LoggerFactory.getLogger(MatchEventHub.class);

    // matchId → Sink multicast para N clientes conectados
    private final Map<String, Sinks.Many<String>> matchSinks = new ConcurrentHashMap<>();

    /**
     * Retorna (ou cria) o Flux SSE para uma partida específica.
     * Chamado pelo SseController quando um cliente conecta.
     */
    public Flux<String> subscribeToMatch(String matchId) {
        Sinks.Many<String> sink = matchSinks.computeIfAbsent(
                matchId,
                id -> Sinks.many().multicast().onBackpressureBuffer(256)
        );
        log.debug("[realtime-gateway] Cliente conectado à partida {}", matchId);
        return sink.asFlux();
    }

    /**
     * Publica um evento para todos os clientes conectados a uma partida.
     * Chamado pelo RealtimeListener quando chega uma mensagem do RabbitMQ.
     */
    public void publish(String matchId, String eventPayload) {
        Sinks.Many<String> sink = matchSinks.get(matchId);
        if (sink == null) {
            // Nenhum cliente conectado — ignora silenciosamente
            return;
        }
        Sinks.EmitResult result = sink.tryEmitNext(eventPayload);
        if (result.isFailure()) {
            log.warn("[realtime-gateway] Falha ao emitir para partida {}: {}", matchId, result);
        }
    }

    /**
     * Remove o sink quando a partida encerrar (libera memória).
     */
    public void closeMatch(String matchId) {
        Sinks.Many<String> sink = matchSinks.remove(matchId);
        if (sink != null) {
            sink.tryEmitComplete();
            log.info("[realtime-gateway] Sink removido para partida {}", matchId);
        }
    }
}
