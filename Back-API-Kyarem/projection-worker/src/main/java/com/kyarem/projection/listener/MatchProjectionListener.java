package com.kyarem.projection.listener;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

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

    /**
     * Atualiza projeções de partida quando o placar muda.
     * Routing key: match.score.updated
     */
    @RabbitListener(queues = "projection.match")
    public void onMatchEvent(String payload) {
        log.info("[projection-worker] Evento de partida recebido: {}", payload);
        // TODO: desserializar payload, identificar eventType e rotear para o
        //       serviço de projeção correto (PartidaAoVivoProjection, HistoricoProjection, etc.)
        processMatchProjection(payload);
    }

    /**
     * Atualiza read models de feed social.
     * Routing key: social.#
     */
    @RabbitListener(queues = "projection.social")
    public void onSocialEvent(String payload) {
        log.info("[projection-worker] Evento social recebido: {}", payload);
        // TODO: atualizar public.feed_posts, public.comentarios_publicos,
        //       public.contadores_sociais
        processSocialProjection(payload);
    }

    // ── Métodos privados de processamento ─────────────────────────────────────

    private void processMatchProjection(String payload) {
        // Implementação incremental:
        // 1. Deserializar JSON → EventPayload POJO
        // 2. Identificar aggregate_type e event_type
        // 3. Chamar PartidaAoVivoProjectionService ou HistoricoProjectionService
        // 4. Atualizar tabela correspondente no schema public via JPA/native query
        log.debug("[projection-worker] processMatchProjection stub — payload length: {}", payload.length());
    }

    private void processSocialProjection(String payload) {
        log.debug("[projection-worker] processSocialProjection stub — payload length: {}", payload.length());
    }
}
