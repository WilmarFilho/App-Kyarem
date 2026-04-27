package com.kyarem.realtime.listener;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.kyarem.realtime.hub.MatchEventHub;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

/**
 * Consome a fila realtime.notify e faz push para os clientes SSE conectados.
 *
 * Mensagem esperada (JSON):
 * {
 *   "matchId": "uuid",
 *   "eventType": "match.score.updated",
 *   "payload": { ... dados do evento ... }
 * }
 */
@Component
public class RealtimeListener {

    private static final Logger log = LoggerFactory.getLogger(RealtimeListener.class);

    private final MatchEventHub hub;
    private final ObjectMapper objectMapper;

    public RealtimeListener(MatchEventHub hub, ObjectMapper objectMapper) {
        this.hub = hub;
        this.objectMapper = objectMapper;
    }

    @RabbitListener(queues = "realtime.notify")
    public void onRealtimeEvent(String payload) {
        try {
            JsonNode node = objectMapper.readTree(payload);
            String matchId = node.path("matchId").asText();

            if (matchId.isBlank()) {
                log.warn("[realtime-gateway] Evento sem matchId recebido, ignorando");
                return;
            }

            hub.publish(matchId, payload);
            log.debug("[realtime-gateway] Evento publicado para partida {}", matchId);

        } catch (Exception ex) {
            log.error("[realtime-gateway] Erro ao processar evento realtime: {}", ex.getMessage());
        }
    }
}
