package com.kyarem.realtime.listener;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.kyarem.realtime.hub.MatchEventHub;
import com.kyarem.realtime.hub.SocialEventHub;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.amqp.support.AmqpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.messaging.handler.annotation.Header;

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
    private final SocialEventHub socialEventHub;
    private final ObjectMapper objectMapper;

    public RealtimeListener(MatchEventHub hub, SocialEventHub socialEventHub, ObjectMapper objectMapper) {
        this.hub = hub;
        this.socialEventHub = socialEventHub;
        this.objectMapper = objectMapper;
    }

    @RabbitListener(queues = "realtime.notify")
    public void onRealtimeEvent(
            String payload,
            @Header(name = AmqpHeaders.RECEIVED_ROUTING_KEY, required = false) String routingKey
    ) {
        try {
            JsonNode node = objectMapper.readTree(payload);
            if (routingKey != null && routingKey.startsWith("social.")) {
                socialEventHub.publish(payload);
                log.debug("[realtime-gateway] Evento social publicado em SSE");
                return;
            }

            String matchId = resolveMatchId(node);

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

    private String resolveMatchId(JsonNode node) {
        String matchId = node.path("matchId").asText("");
        if (!matchId.isBlank()) {
            return matchId;
        }

        matchId = node.path("partidaId").asText("");
        if (!matchId.isBlank()) {
            return matchId;
        }

        String aggregateType = node.path("aggregateType").asText("");
        if ("Partida".equalsIgnoreCase(aggregateType)) {
            return node.path("aggregateId").asText("");
        }

        return "";
    }
}
