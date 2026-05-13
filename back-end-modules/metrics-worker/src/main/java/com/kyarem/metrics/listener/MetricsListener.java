package com.kyarem.metrics.listener;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

/**
 * Consome eventos que disparam recálculo de métricas e rankings.
 *
 * Tabelas alvo no schema public:
 * - public.classificacoes (pontos, vitórias, derrotas, saldo)
 * - public.artilharia (pontuadores por modalidade)
 * - public.ranking_assistencias
 * - public.ranking_geral_campeonato
 * - public.metricas_atletas
 * - public.snapshot_comparacao_atletas / times
 */
@Component
public class MetricsListener {

    private static final Logger log = LoggerFactory.getLogger(MetricsListener.class);

    /**
     * Recalcula classificação e estatísticas de atletas quando
     * uma partida é encerrada ou cancelada.
     * Routing keys: match.finished, match.closed
     */
    @RabbitListener(queues = "metrics.recalculate")
    public void onRecalculateRequest(String payload) {
        log.info("[metrics-worker] Recalculo solicitado: {}", payload);
        recalculateStandings(payload);
        recalculateArtilharia(payload);
    }

    /**
     * Recalcula o ranking geral da atletica no campeonato.
     * Routing key: ranking.requested
     */
    @RabbitListener(queues = "metrics.ranking")
    public void onRankingRequest(String payload) {
        log.info("[metrics-worker] Ranking solicitado: {}", payload);
        // Lógica futura para recalcular public.ranking_geral_campeonato
        // agrupando pontos de todas as modalidades por atlética
        recalculateGeneralRanking(payload);
    }

    // ── Stubs de implementação ────────────────────────────────────────────────

    private void recalculateStandings(String payload) {
        log.debug("[metrics-worker] recalculateStandings stub");
    }

    private void recalculateArtilharia(String payload) {
        log.debug("[metrics-worker] recalculateArtilharia stub");
    }

    private void recalculateGeneralRanking(String payload) {
        log.debug("[metrics-worker] recalculateGeneralRanking stub");
    }
}
