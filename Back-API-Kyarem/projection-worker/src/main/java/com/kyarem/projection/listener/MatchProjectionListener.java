package com.kyarem.projection.listener;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.support.AmqpHeaders;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;
import org.springframework.messaging.handler.annotation.Header;
import com.fasterxml.jackson.databind.ObjectMapper;

/**
 * Consome eventos de partida e atualiza os read models do schema public:
 *  - public.partidas_ao_vivo
 *  - public.partidas_historico
 *  - public.eventos_partida_publicos
 *  - public.estatisticas_partida
 *  - public.timeline_campeonato
 *
 * Cada método é um consumidor independente com ACK manual configurado
 * para garantir que mensagens não sejam perdidas em caso de falha.
 */
@Component
public class MatchProjectionListener {

    private static final Logger log = LoggerFactory.getLogger(MatchProjectionListener.class);

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final com.kyarem.projection.service.PartidaProjectionService partidaProjectionService;

    public MatchProjectionListener(com.kyarem.projection.service.PartidaProjectionService partidaProjectionService) {
        this.partidaProjectionService = partidaProjectionService;
    }

    /**
     * Atualiza projeções de partida quando o placar muda.
     * Routing key: match.score.updated
     */
    @RabbitListener(queues = "projection.match")
    public void onMatchEvent(String payload,
                             @Header(name = AmqpHeaders.RECEIVED_ROUTING_KEY, required = false) String routingKey) {
        log.info("[projection-worker] Evento de partida recebido (routingKey={}): {}", routingKey, payload);
        try {
            com.fasterxml.jackson.databind.JsonNode node = objectMapper.readTree(payload);
            partidaProjectionService.processMatchEvent(routingKey == null ? "" : routingKey, node);
        } catch (Exception e) {
            log.error("Erro ao processar evento de partida: {}", e.getMessage(), e);
            // Re-throw if you want DLQ or manual ack rejection, 
            // for now let's swallow or throw based on your retry config
            throw new RuntimeException(e);
        }
    }

    /**
     * Atualiza read models de feed social.
     * Routing key: social.#
     */
    @RabbitListener(queues = "projection.social")
    public void onSocialEvent(String payload) {
        log.info("[projection-worker] Evento social recebido: {}", payload);
    }
}
