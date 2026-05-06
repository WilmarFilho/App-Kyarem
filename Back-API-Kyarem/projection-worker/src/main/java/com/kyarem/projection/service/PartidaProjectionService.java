package com.kyarem.projection.service;

import com.fasterxml.jackson.databind.JsonNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class PartidaProjectionService {

    private static final Logger log = LoggerFactory.getLogger(PartidaProjectionService.class);
    private final JdbcTemplate jdbcTemplate;

    public PartidaProjectionService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional
    public void processMatchEvent(String routingKey, JsonNode payload) {
        String eventType = text(payload, "eventType");
        if (eventType.isBlank()) {
            log.warn("Payload sem eventType, ignorando: {}", payload);
            return;
        }

        UUID partidaId = resolvePartidaId(payload);
        UUID eventoId = resolveEventoId(payload);

        log.info("Processando evento: eventType={}, routingKey={}, partidaId={}, eventoId={}, payload={}",
                eventType,
                routingKey,
                partidaId,
                eventoId,
                payload);

        switch (eventType) {
            case "PartidaCriada", "PartidaIniciada", "StatusAlterado", "PartidaAtualizada" -> upsertPartidaAoVivo(partidaId);
            case "EventoRegistrado", "EventoAtualizado" -> {
                upsertPartidaAoVivo(partidaId);
                if (eventoId != null) {
                    upsertEventoPublico(eventoId);
                }
            }
            case "EventoExcluido" -> {
                upsertPartidaAoVivo(partidaId);
                if (eventoId != null) {
                    deleteEventoPublico(eventoId);
                }
            }
            case "SumulaFechada" -> {
                upsertPartidaHistorico(partidaId);
                syncEventosPublicosDaPartida(partidaId);
                jdbcTemplate.update("DELETE FROM public.partidas_ao_vivo WHERE partida_id = ?", partidaId);
            }
            case "PartidaExcluida" -> deletePartidaPublic(partidaId);
            default -> log.info("Evento {} não possui projeção configurada. Payload: {}", eventType, payload);
        }
    }

    private UUID resolvePartidaId(JsonNode payload) {
        String partidaId = text(payload, "partidaId");
        if (!partidaId.isBlank()) {
            return UUID.fromString(partidaId);
        }

        String aggregateType = text(payload, "aggregateType");
        if ("Partida".equalsIgnoreCase(aggregateType)) {
            return UUID.fromString(text(payload, "aggregateId"));
        }

        throw new IllegalStateException("Não foi possível determinar a partida do payload: " + payload);
    }

    private UUID resolveEventoId(JsonNode payload) {
        String aggregateType = text(payload, "aggregateType");
        if ("EventoPartida".equalsIgnoreCase(aggregateType)) {
            return UUID.fromString(text(payload, "aggregateId"));
        }

        String eventoId = text(payload, "eventoId");
        return eventoId.isBlank() ? null : UUID.fromString(eventoId);
    }

    private String text(JsonNode payload, String field) {
        return payload.hasNonNull(field) ? payload.get(field).asText() : "";
    }

    private void upsertPartidaAoVivo(UUID partidaId) {
        log.info("Atualizando projeção partidas_ao_vivo para partida {}", partidaId);
        String selectSql = """
                SELECT
                    p.id AS partida_id,
                    p.campeonato_id,
                    p.campeonato_modalidade_id,
                    COALESCE(team_a.nome, atl_a.nome) AS time_a_nome,
                    COALESCE(team_b.nome, atl_b.nome) AS time_b_nome,
                    atl_a.escudo_url AS time_a_escudo_url,
                    atl_b.escudo_url AS time_b_escudo_url,
                    atl_a.id AS time_a_atletica_id,
                    atl_b.id AS time_b_atletica_id,
                    atl_a.cor_principal AS time_a_cor_principal,
                    atl_b.cor_principal AS time_b_cor_principal,
                    p.placar_a,
                    p.placar_b,
                    p.status,
                    p.periodo_atual,
                    last_event.tempo_cronometro AS cronometro,
                    p.local,
                    p.agendado_para,
                    p.versao_estado
                FROM operational.partidas p
                LEFT JOIN operational.campeonato_times ta ON p.campeonato_time_a_id = ta.id
                LEFT JOIN operational.times_atletica team_a ON ta.time_atletica_id = team_a.id
                LEFT JOIN operational.atleticas atl_a ON team_a.atletica_id = atl_a.id
                LEFT JOIN operational.campeonato_times tb ON p.campeonato_time_b_id = tb.id
                LEFT JOIN operational.times_atletica team_b ON tb.time_atletica_id = team_b.id
                LEFT JOIN operational.atleticas atl_b ON team_b.atletica_id = atl_b.id
                LEFT JOIN LATERAL (
                    SELECT ev.tempo_cronometro
                    FROM operational.eventos_partida ev
                    WHERE ev.partida_id = p.id
                    ORDER BY ev.criado_em DESC, ev.ordem_evento DESC NULLS LAST
                    LIMIT 1
                ) last_event ON TRUE
                WHERE p.id = ?
                """;

        final int[] affected = {0};
        jdbcTemplate.query(selectSql, rs -> {
            String upsertSql = """
                    INSERT INTO public.partidas_ao_vivo (
                        partida_id, campeonato_id, campeonato_modalidade_id,
                        time_a_nome, time_b_nome, time_a_escudo_url, time_b_escudo_url,
                        time_a_atletica_id, time_b_atletica_id,
                        time_a_cor_principal, time_b_cor_principal,
                        placar_a, placar_b, status, periodo_atual, cronometro, local, agendado_para, versao_estado, atualizado_em
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
                    ON CONFLICT (partida_id) DO UPDATE SET
                        campeonato_id = EXCLUDED.campeonato_id,
                        campeonato_modalidade_id = EXCLUDED.campeonato_modalidade_id,
                        time_a_nome = EXCLUDED.time_a_nome,
                        time_b_nome = EXCLUDED.time_b_nome,
                        time_a_escudo_url = EXCLUDED.time_a_escudo_url,
                        time_b_escudo_url = EXCLUDED.time_b_escudo_url,
                        time_a_atletica_id = EXCLUDED.time_a_atletica_id,
                        time_b_atletica_id = EXCLUDED.time_b_atletica_id,
                        time_a_cor_principal = EXCLUDED.time_a_cor_principal,
                        time_b_cor_principal = EXCLUDED.time_b_cor_principal,
                        placar_a = EXCLUDED.placar_a,
                        placar_b = EXCLUDED.placar_b,
                        status = EXCLUDED.status,
                        periodo_atual = EXCLUDED.periodo_atual,
                        cronometro = EXCLUDED.cronometro,
                        local = EXCLUDED.local,
                        agendado_para = EXCLUDED.agendado_para,
                        versao_estado = EXCLUDED.versao_estado,
                        atualizado_em = NOW()
                    """;

            affected[0] += jdbcTemplate.update(upsertSql,
                rs.getObject("partida_id"),
                rs.getObject("campeonato_id"),
                rs.getObject("campeonato_modalidade_id"),
                rs.getString("time_a_nome"),
                rs.getString("time_b_nome"),
                rs.getString("time_a_escudo_url"),
                rs.getString("time_b_escudo_url"),
                rs.getObject("time_a_atletica_id"),
                rs.getObject("time_b_atletica_id"),
                rs.getString("time_a_cor_principal"),
                rs.getString("time_b_cor_principal"),
                rs.getInt("placar_a"),
                rs.getInt("placar_b"),
                rs.getString("status"),
                rs.getString("periodo_atual"),
                rs.getString("cronometro"),
                rs.getString("local"),
                rs.getObject("agendado_para"),
                rs.getLong("versao_estado"));
        }, partidaId);
        log.info("Projeção partidas_ao_vivo para partida {} afetou {} linha(s)", partidaId, affected[0]);
    }

    private void upsertPartidaHistorico(UUID partidaId) {
        log.info("Atualizando projeção partidas_historico para partida {}", partidaId);
        String sql = """
                INSERT INTO public.partidas_historico (
                    partida_id, campeonato_id, campeonato_slug, campeonato_nome,
                    campeonato_modalidade_id, esporte_nome, modalidade_nome,
                    fase, rodada, categoria, genero,
                    time_a_id, time_a_nome, time_a_sigla, time_a_escudo_url, time_a_atletica_id, time_a_atletica_nome, time_a_cor_principal,
                    time_b_id, time_b_nome, time_b_sigla, time_b_escudo_url, time_b_atletica_id, time_b_atletica_nome, time_b_cor_principal,
                    placar_a, placar_b, resultado, houve_prorrogacao, houve_penaltis,
                    placar_penaltis_a, placar_penaltis_b, local, agendado_para, iniciada_em, encerrada_em,
                    duracao_minutos, sumula_pdf_url, atualizado_em
                )
                SELECT
                    p.id,
                    c.id,
                    NULL,
                    c.nome,
                    cm.id,
                    esp.nome,
                    mc.nome,
                    p.fase,
                    p.rodada,
                    p.categoria,
                    cm.genero,
                    ta.id,
                    COALESCE(tta.nome, atl_a.nome),
                    atl_a.sigla,
                    atl_a.escudo_url,
                    atl_a.id,
                    atl_a.nome,
                    atl_a.cor_principal,
                    tb.id,
                    COALESCE(ttb.nome, atl_b.nome),
                    atl_b.sigla,
                    atl_b.escudo_url,
                    atl_b.id,
                    atl_b.nome,
                    atl_b.cor_principal,
                    p.placar_a,
                    p.placar_b,
                    CASE
                        WHEN COALESCE(p.placar_a, 0) > COALESCE(p.placar_b, 0) THEN 'VITORIA_A'
                        WHEN COALESCE(p.placar_b, 0) > COALESCE(p.placar_a, 0) THEN 'VITORIA_B'
                        ELSE 'EMPATE'
                    END,
                    EXISTS (
                        SELECT 1
                        FROM operational.eventos_partida ev
                        JOIN operational.tipos_eventos te ON te.id = ev.tipo_evento_id
                        WHERE ev.partida_id = p.id
                          AND upper(coalesce(te.codigo, te.nome)) LIKE '%PRORROG%'
                    ),
                    EXISTS (
                        SELECT 1
                        FROM operational.eventos_partida ev
                        JOIN operational.tipos_eventos te ON te.id = ev.tipo_evento_id
                        WHERE ev.partida_id = p.id
                          AND upper(coalesce(te.codigo, te.nome)) LIKE '%PENALT%'
                    ),
                    NULL,
                    NULL,
                    p.local,
                    p.agendado_para,
                    p.iniciada_em,
                    p.encerrada_em,
                    CASE
                        WHEN p.iniciada_em IS NOT NULL AND p.encerrada_em IS NOT NULL
                            THEN GREATEST(0, FLOOR(EXTRACT(EPOCH FROM (p.encerrada_em - p.iniciada_em)) / 60))::INTEGER
                        ELSE NULL
                    END,
                    p.sumula_pdf_url,
                    NOW()
                FROM operational.partidas p
                JOIN operational.campeonatos c ON c.id = p.campeonato_id
                JOIN operational.campeonato_modalidades cm ON cm.id = p.campeonato_modalidade_id
                JOIN operational.modalidades_catalogo mc ON mc.id = cm.modalidade_catalogo_id
                JOIN operational.esportes esp ON esp.id = mc.esporte_id
                LEFT JOIN operational.campeonato_times ta ON ta.id = p.campeonato_time_a_id
                LEFT JOIN operational.times_atletica tta ON tta.id = ta.time_atletica_id
                LEFT JOIN operational.atleticas atl_a ON atl_a.id = tta.atletica_id
                LEFT JOIN operational.campeonato_times tb ON tb.id = p.campeonato_time_b_id
                LEFT JOIN operational.times_atletica ttb ON ttb.id = tb.time_atletica_id
                LEFT JOIN operational.atleticas atl_b ON atl_b.id = ttb.atletica_id
                WHERE p.id = ?
                ON CONFLICT (partida_id) DO UPDATE SET
                    campeonato_id = EXCLUDED.campeonato_id,
                    campeonato_slug = EXCLUDED.campeonato_slug,
                    campeonato_nome = EXCLUDED.campeonato_nome,
                    campeonato_modalidade_id = EXCLUDED.campeonato_modalidade_id,
                    esporte_nome = EXCLUDED.esporte_nome,
                    modalidade_nome = EXCLUDED.modalidade_nome,
                    fase = EXCLUDED.fase,
                    rodada = EXCLUDED.rodada,
                    categoria = EXCLUDED.categoria,
                    genero = EXCLUDED.genero,
                    time_a_id = EXCLUDED.time_a_id,
                    time_a_nome = EXCLUDED.time_a_nome,
                    time_a_sigla = EXCLUDED.time_a_sigla,
                    time_a_escudo_url = EXCLUDED.time_a_escudo_url,
                    time_a_atletica_id = EXCLUDED.time_a_atletica_id,
                    time_a_atletica_nome = EXCLUDED.time_a_atletica_nome,
                    time_a_cor_principal = EXCLUDED.time_a_cor_principal,
                    time_b_id = EXCLUDED.time_b_id,
                    time_b_nome = EXCLUDED.time_b_nome,
                    time_b_sigla = EXCLUDED.time_b_sigla,
                    time_b_escudo_url = EXCLUDED.time_b_escudo_url,
                    time_b_atletica_id = EXCLUDED.time_b_atletica_id,
                    time_b_atletica_nome = EXCLUDED.time_b_atletica_nome,
                    time_b_cor_principal = EXCLUDED.time_b_cor_principal,
                    placar_a = EXCLUDED.placar_a,
                    placar_b = EXCLUDED.placar_b,
                    resultado = EXCLUDED.resultado,
                    houve_prorrogacao = EXCLUDED.houve_prorrogacao,
                    houve_penaltis = EXCLUDED.houve_penaltis,
                    placar_penaltis_a = EXCLUDED.placar_penaltis_a,
                    placar_penaltis_b = EXCLUDED.placar_penaltis_b,
                    local = EXCLUDED.local,
                    agendado_para = EXCLUDED.agendado_para,
                    iniciada_em = EXCLUDED.iniciada_em,
                    encerrada_em = EXCLUDED.encerrada_em,
                    duracao_minutos = EXCLUDED.duracao_minutos,
                    sumula_pdf_url = EXCLUDED.sumula_pdf_url,
                    atualizado_em = NOW()
                """;

        int affected = jdbcTemplate.update(sql, partidaId);
        log.info("Projeção partidas_historico para partida {} afetou {} linha(s)", partidaId, affected);
    }

    private void upsertEventoPublico(UUID eventoId) {
        log.info("Atualizando projeção eventos_partida_publicos para evento {}", eventoId);
        String sql = """
                INSERT INTO public.eventos_partida_publicos (
                    evento_id, partida_id, tipo_evento_codigo, tipo_evento_nome, impacta_placar,
                    equipe_id, equipe_nome, equipe_cor,
                    atleta_id, atleta_nome_exibicao, atleta_foto_url,
                    atleta_sai_id, atleta_sai_nome,
                    periodo, minuto, segundo, descricao, payload_json, criado_em
                )
                SELECT
                    ev.id AS evento_id,
                    ev.partida_id,
                    te.codigo AS tipo_evento_codigo,
                    te.nome AS tipo_evento_nome,
                    te.impacta_placar AS impacta_placar,
                    ta.id AS equipe_id,
                    COALESCE(t_atl.nome, atl_ta.nome) AS equipe_nome,
                    atl_ta.cor_principal AS equipe_cor,
                    a.id AS atleta_id,
                    COALESCE(a.nome_competicao, p.nome_completo) AS atleta_nome_exibicao,
                    a.foto_url AS atleta_foto_url,
                    a_sai.id AS atleta_sai_id,
                    COALESCE(a_sai.nome_competicao, p_sai.nome_completo) AS atleta_sai_nome,
                    ev.periodo,
                    ev.minuto,
                    ev.segundo,
                    ev.descricao_detalhada AS descricao,
                    ev.payload_json AS payload_json,
                    ev.criado_em
                FROM operational.eventos_partida ev
                LEFT JOIN operational.tipos_eventos te ON ev.tipo_evento_id = te.id
                LEFT JOIN operational.campeonato_times ta ON ev.equipe_id = ta.id
                LEFT JOIN operational.times_atletica t_atl ON ta.time_atletica_id = t_atl.id
                LEFT JOIN operational.atleticas atl_ta ON t_atl.atletica_id = atl_ta.id
                LEFT JOIN operational.atletas a ON ev.atleta_id = a.id
                LEFT JOIN operational.profiles p ON a.user_id = p.id
                LEFT JOIN operational.atletas a_sai ON ev.atleta_sai_id = a_sai.id
                LEFT JOIN operational.profiles p_sai ON a_sai.user_id = p_sai.id
                WHERE ev.id = ?
                ON CONFLICT (evento_id) DO UPDATE SET
                    partida_id = EXCLUDED.partida_id,
                    tipo_evento_codigo = EXCLUDED.tipo_evento_codigo,
                    tipo_evento_nome = EXCLUDED.tipo_evento_nome,
                    impacta_placar = EXCLUDED.impacta_placar,
                    equipe_id = EXCLUDED.equipe_id,
                    equipe_nome = EXCLUDED.equipe_nome,
                    equipe_cor = EXCLUDED.equipe_cor,
                    atleta_id = EXCLUDED.atleta_id,
                    atleta_nome_exibicao = EXCLUDED.atleta_nome_exibicao,
                    atleta_foto_url = EXCLUDED.atleta_foto_url,
                    atleta_sai_id = EXCLUDED.atleta_sai_id,
                    atleta_sai_nome = EXCLUDED.atleta_sai_nome,
                    periodo = EXCLUDED.periodo,
                    minuto = EXCLUDED.minuto,
                    segundo = EXCLUDED.segundo,
                    descricao = EXCLUDED.descricao,
                    payload_json = EXCLUDED.payload_json,
                    criado_em = EXCLUDED.criado_em
                """;

        int affected = jdbcTemplate.update(sql, eventoId);
        log.info("Projeção eventos_partida_publicos para evento {} afetou {} linha(s)", eventoId, affected);
        if (affected == 0) {
            Integer operationalCount = jdbcTemplate.queryForObject(
                    "SELECT COUNT(1) FROM operational.eventos_partida WHERE id = ?",
                    Integer.class,
                    eventoId);
            log.warn("Evento {} não gerou projeção pública. Existe em operational.eventos_partida? count={}", eventoId, operationalCount);
        }
    }

    private void syncEventosPublicosDaPartida(UUID partidaId) {
        log.info("Sincronizando eventos públicos da partida {}", partidaId);
        String sql = """
                INSERT INTO public.eventos_partida_publicos (
                    evento_id, partida_id, tipo_evento_codigo, tipo_evento_nome, impacta_placar,
                    equipe_id, equipe_nome, equipe_cor,
                    atleta_id, atleta_nome_exibicao, atleta_foto_url,
                    atleta_sai_id, atleta_sai_nome,
                    periodo, minuto, segundo, descricao, payload_json, criado_em
                )
                SELECT
                    ev.id AS evento_id,
                    ev.partida_id,
                    te.codigo AS tipo_evento_codigo,
                    te.nome AS tipo_evento_nome,
                    te.impacta_placar AS impacta_placar,
                    ta.id AS equipe_id,
                    COALESCE(t_atl.nome, atl_ta.nome) AS equipe_nome,
                    atl_ta.cor_principal AS equipe_cor,
                    a.id AS atleta_id,
                    COALESCE(a.nome_competicao, p.nome_completo) AS atleta_nome_exibicao,
                    a.foto_url AS atleta_foto_url,
                    a_sai.id AS atleta_sai_id,
                    COALESCE(a_sai.nome_competicao, p_sai.nome_completo) AS atleta_sai_nome,
                    ev.periodo,
                    ev.minuto,
                    ev.segundo,
                    ev.descricao_detalhada AS descricao,
                    ev.payload_json AS payload_json,
                    ev.criado_em
                FROM operational.eventos_partida ev
                LEFT JOIN operational.tipos_eventos te ON ev.tipo_evento_id = te.id
                LEFT JOIN operational.campeonato_times ta ON ev.equipe_id = ta.id
                LEFT JOIN operational.times_atletica t_atl ON ta.time_atletica_id = t_atl.id
                LEFT JOIN operational.atleticas atl_ta ON t_atl.atletica_id = atl_ta.id
                LEFT JOIN operational.atletas a ON ev.atleta_id = a.id
                LEFT JOIN operational.profiles p ON a.user_id = p.id
                LEFT JOIN operational.atletas a_sai ON ev.atleta_sai_id = a_sai.id
                LEFT JOIN operational.profiles p_sai ON a_sai.user_id = p_sai.id
                WHERE ev.partida_id = ?
                ON CONFLICT (evento_id) DO UPDATE SET
                    partida_id = EXCLUDED.partida_id,
                    tipo_evento_codigo = EXCLUDED.tipo_evento_codigo,
                    tipo_evento_nome = EXCLUDED.tipo_evento_nome,
                    impacta_placar = EXCLUDED.impacta_placar,
                    equipe_id = EXCLUDED.equipe_id,
                    equipe_nome = EXCLUDED.equipe_nome,
                    equipe_cor = EXCLUDED.equipe_cor,
                    atleta_id = EXCLUDED.atleta_id,
                    atleta_nome_exibicao = EXCLUDED.atleta_nome_exibicao,
                    atleta_foto_url = EXCLUDED.atleta_foto_url,
                    atleta_sai_id = EXCLUDED.atleta_sai_id,
                    atleta_sai_nome = EXCLUDED.atleta_sai_nome,
                    periodo = EXCLUDED.periodo,
                    minuto = EXCLUDED.minuto,
                    segundo = EXCLUDED.segundo,
                    descricao = EXCLUDED.descricao,
                    payload_json = EXCLUDED.payload_json,
                    criado_em = EXCLUDED.criado_em
                """;

        int affected = jdbcTemplate.update(sql, partidaId);
        log.info("Sincronização de eventos públicos da partida {} afetou {} linha(s)", partidaId, affected);
    }

    private void deleteEventoPublico(UUID eventoId) {
        int affected = jdbcTemplate.update("DELETE FROM public.eventos_partida_publicos WHERE evento_id = ?", eventoId);
        log.info("Remoção de evento público {} afetou {} linha(s)", eventoId, affected);
    }

    private void deletePartidaPublic(UUID partidaId) {
        int aoVivo = jdbcTemplate.update("DELETE FROM public.partidas_ao_vivo WHERE partida_id = ?", partidaId);
        int historico = jdbcTemplate.update("DELETE FROM public.partidas_historico WHERE partida_id = ?", partidaId);
        int eventos = jdbcTemplate.update("DELETE FROM public.eventos_partida_publicos WHERE partida_id = ?", partidaId);
        log.info("Remoção de projeções da partida {} afetou ao_vivo={}, historico={}, eventos={}", partidaId, aoVivo, historico, eventos);
    }
}
