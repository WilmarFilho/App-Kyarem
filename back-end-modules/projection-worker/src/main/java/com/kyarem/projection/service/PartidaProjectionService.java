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
                eventType, routingKey, partidaId, eventoId, payload);

        switch (eventType) {
            case "CampeonatoCriado", "CampeonatoAtualizado" -> syncCampeonato(resolveAggregateId(payload, "campeonatoId"));
            case "CampeonatoExcluido" -> deleteCampeonato(resolveAggregateId(payload, "campeonatoId"));
            case "CampeonatoModalidadeCriada", "CampeonatoModalidadeAtualizada" ->
                    syncCampeonatoModalidade(resolveAggregateId(payload, "campeonatoModalidadeId"));
            case "CampeonatoModalidadeExcluida" ->
                    deleteCampeonatoModalidade(resolveAggregateId(payload, "campeonatoModalidadeId"));
            case "CampeonatoAtleticaCriada", "CampeonatoAtleticaAtualizada" ->
                    syncCampeonatoAtletica(resolveAggregateId(payload, "campeonatoAtleticaId"));
            case "CampeonatoAtleticaExcluida" ->
                    deleteCampeonatoAtletica(resolveAggregateId(payload, "campeonatoAtleticaId"));
            case "CampeonatoTimeCriado", "CampeonatoTimeAtualizado" ->
                    syncCampeonatoTime(resolveAggregateId(payload, "campeonatoTimeId"));
            case "CampeonatoTimeExcluido" ->
                    deleteCampeonatoTime(resolveAggregateId(payload, "campeonatoTimeId"));
            case "CampeonatoAtletaCriado", "CampeonatoAtletaAtualizado" ->
                    syncCampeonatoAtleta(resolveAggregateId(payload, "campeonatoAtletaId"));
            case "CampeonatoAtletaExcluido" ->
                    deleteCampeonatoAtleta(resolveAggregateId(payload, "campeonatoAtletaId"));
            case "AtleticaCriada", "AtleticaAtualizada" -> syncAtletica(resolveAggregateId(payload, "atleticaId"));
            case "AtleticaExcluida" -> deleteAtletica(resolveAggregateId(payload, "atleticaId"));
            case "AtleticaMembroCriado", "AtleticaMembroAtualizado" ->
                    syncAtleticaMembro(resolveAggregateId(payload, "atleticaMembroId"));
            case "AtleticaMembroExcluido" ->
                    deleteAtleticaMembro(resolveAggregateId(payload, "atleticaMembroId"));
            case "ProfileCriado", "ProfileAtualizado" -> syncProfile(resolveAggregateId(payload, "profileId"));
            case "PartidaCriada", "PartidaIniciada", "StatusAlterado", "PartidaAtualizada" -> syncPartidaProjection(partidaId);
            case "EventoRegistrado", "EventoAtualizado" -> {
                syncPartidaProjection(partidaId);
                if (eventoId != null) {
                    upsertEventoPublico(eventoId);
                }
            }
            case "EventoExcluido" -> {
                syncPartidaProjection(partidaId);
                if (eventoId != null) {
                    deleteEventoPublico(eventoId);
                }
            }
            case "SumulaFechada" -> {
                syncPartidaProjection(partidaId);
                syncEventosPublicosDaPartida(partidaId);
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

        return null;
    }

    private UUID resolveEventoId(JsonNode payload) {
        String aggregateType = text(payload, "aggregateType");
        if ("EventoPartida".equalsIgnoreCase(aggregateType)) {
            return UUID.fromString(text(payload, "aggregateId"));
        }

        String eventoId = text(payload, "eventoId");
        return eventoId.isBlank() ? null : UUID.fromString(eventoId);
    }

    private UUID resolveAggregateId(JsonNode payload, String explicitField) {
        String explicitId = text(payload, explicitField);
        if (!explicitId.isBlank()) {
            return UUID.fromString(explicitId);
        }
        String aggregateId = text(payload, "aggregateId");
        return aggregateId.isBlank() ? null : UUID.fromString(aggregateId);
    }

    private String text(JsonNode payload, String field) {
        return payload.hasNonNull(field) ? payload.get(field).asText() : "";
    }

    private void syncPartidaProjection(UUID partidaId) {
        if (partidaId == null) {
            return;
        }

        String status = jdbcTemplate.query(
                "SELECT status FROM operational.partidas WHERE id = ?",
                rs -> rs.next() ? rs.getString("status") : null,
                partidaId
        );
        if (status == null) {
            deletePartidaPublic(partidaId);
            return;
        }

        String normalized = status.trim().toLowerCase();
        if (isHistoricalStatus(normalized)) {
            upsertPartidaHistorico(partidaId);
            jdbcTemplate.update("DELETE FROM public.partidas_ao_vivo WHERE partida_id = ?", partidaId);
            return;
        }

        if (isLiveStatus(normalized)) {
            upsertPartidaAoVivo(partidaId);
            jdbcTemplate.update("DELETE FROM public.partidas_historico WHERE partida_id = ?", partidaId);
            return;
        }

        jdbcTemplate.update("DELETE FROM public.partidas_ao_vivo WHERE partida_id = ?", partidaId);
        jdbcTemplate.update("DELETE FROM public.partidas_historico WHERE partida_id = ?", partidaId);
    }

    private boolean isHistoricalStatus(String status) {
        return "finalizada".equals(status) || "fechada".equals(status);
    }

    private boolean isLiveStatus(String status) {
        return !status.isBlank()
                && !isHistoricalStatus(status)
                && !"agendada".equals(status)
                && !"cancelada".equals(status)
                && !"wo".equals(status);
    }

    private void syncCampeonato(UUID campeonatoId) {
        if (campeonatoId == null) {
            return;
        }
        jdbcTemplate.update("""
                INSERT INTO public.campeonatos_vitrine (
                    campeonato_id, nome, nivel, data_inicio, data_fim, status, escudo_url, criado_em, atualizado_em
                )
                SELECT id, nome, nivel, data_inicio, data_fim, status, escudo_url, criado_em, now()
                FROM operational.campeonatos
                WHERE id = ?
                ON CONFLICT (campeonato_id) DO UPDATE SET
                    nome = EXCLUDED.nome,
                    nivel = EXCLUDED.nivel,
                    data_inicio = EXCLUDED.data_inicio,
                    data_fim = EXCLUDED.data_fim,
                    status = EXCLUDED.status,
                    escudo_url = EXCLUDED.escudo_url,
                    criado_em = EXCLUDED.criado_em,
                    atualizado_em = now()
                """, campeonatoId);
    }

    private void deleteCampeonato(UUID campeonatoId) {
        if (campeonatoId != null) {
            jdbcTemplate.update("""
                    DELETE FROM public.eventos_partida_publicos
                    WHERE partida_id IN (
                        SELECT partida_id FROM public.partidas_ao_vivo WHERE campeonato_id = ?
                        UNION
                        SELECT partida_id FROM public.partidas_historico WHERE campeonato_id = ?
                    )
                    """, campeonatoId, campeonatoId);
            jdbcTemplate.update("DELETE FROM public.partidas_ao_vivo WHERE campeonato_id = ?", campeonatoId);
            jdbcTemplate.update("DELETE FROM public.partidas_historico WHERE campeonato_id = ?", campeonatoId);
            jdbcTemplate.update("DELETE FROM public.campeonato_atletas_publicos WHERE campeonato_id = ?", campeonatoId);
            jdbcTemplate.update("DELETE FROM public.campeonato_times_publicos WHERE campeonato_id = ?", campeonatoId);
            jdbcTemplate.update("DELETE FROM public.campeonato_atleticas_publicos WHERE campeonato_id = ?", campeonatoId);
            jdbcTemplate.update("DELETE FROM public.modalidades_vitrine WHERE campeonato_id = ?", campeonatoId);
            jdbcTemplate.update("DELETE FROM public.campeonatos_vitrine WHERE campeonato_id = ?", campeonatoId);
        }
    }

    private void syncCampeonatoModalidade(UUID campeonatoModalidadeId) {
        if (campeonatoModalidadeId == null) {
            return;
        }
        jdbcTemplate.update("""
                INSERT INTO public.modalidades_vitrine (
                    campeonato_modalidade_id, campeonato_id, modalidade_catalogo_id, esporte_id, esporte_nome,
                    modalidade_nome, modalidade_codigo, nome_exibicao, categoria, genero, regras_json,
                    formato_fases_json, status, atualizado_em
                )
                SELECT
                    cm.id,
                    cm.campeonato_id,
                    cm.modalidade_catalogo_id,
                    e.id,
                    e.nome,
                    mc.nome,
                    mc.codigo,
                    cm.nome_exibicao,
                    cm.categoria,
                    cm.genero,
                    cm.regras_json,
                    cm.formato_fases_json,
                    cm.status,
                    now()
                FROM operational.campeonato_modalidades cm
                JOIN operational.modalidades_catalogo mc ON mc.id = cm.modalidade_catalogo_id
                LEFT JOIN operational.esportes e ON e.id = mc.esporte_id
                WHERE cm.id = ?
                ON CONFLICT (campeonato_modalidade_id) DO UPDATE SET
                    campeonato_id = EXCLUDED.campeonato_id,
                    modalidade_catalogo_id = EXCLUDED.modalidade_catalogo_id,
                    esporte_id = EXCLUDED.esporte_id,
                    esporte_nome = EXCLUDED.esporte_nome,
                    modalidade_nome = EXCLUDED.modalidade_nome,
                    modalidade_codigo = EXCLUDED.modalidade_codigo,
                    nome_exibicao = EXCLUDED.nome_exibicao,
                    categoria = EXCLUDED.categoria,
                    genero = EXCLUDED.genero,
                    regras_json = EXCLUDED.regras_json,
                    formato_fases_json = EXCLUDED.formato_fases_json,
                    status = EXCLUDED.status,
                    atualizado_em = now()
                """, campeonatoModalidadeId);
    }

    private void deleteCampeonatoModalidade(UUID campeonatoModalidadeId) {
        if (campeonatoModalidadeId != null) {
            jdbcTemplate.update("DELETE FROM public.modalidades_vitrine WHERE campeonato_modalidade_id = ?", campeonatoModalidadeId);
        }
    }

    private void syncCampeonatoAtletica(UUID campeonatoAtleticaId) {
        if (campeonatoAtleticaId == null) {
            return;
        }
        jdbcTemplate.update("""
                INSERT INTO public.campeonato_atleticas_publicos (
                    campeonato_atletica_id, campeonato_id, atletica_id, criado_em,
                    atletica_nome, atletica_sigla, atletica_escudo_url
                )
                SELECT ca.id, ca.campeonato_id, ca.atletica_id, ca.criado_em,
                       a.nome, a.sigla, a.escudo_url
                FROM operational.campeonato_atleticas ca
                JOIN operational.atleticas a ON a.id = ca.atletica_id
                WHERE ca.id = ?
                ON CONFLICT (campeonato_atletica_id) DO UPDATE SET
                    campeonato_id = EXCLUDED.campeonato_id,
                    atletica_id = EXCLUDED.atletica_id,
                    criado_em = EXCLUDED.criado_em,
                    atletica_nome = EXCLUDED.atletica_nome,
                    atletica_sigla = EXCLUDED.atletica_sigla,
                    atletica_escudo_url = EXCLUDED.atletica_escudo_url
                """, campeonatoAtleticaId);
    }

    private void deleteCampeonatoAtletica(UUID campeonatoAtleticaId) {
        if (campeonatoAtleticaId != null) {
            jdbcTemplate.update("DELETE FROM public.campeonato_times_publicos WHERE campeonato_atletica_id = ?", campeonatoAtleticaId);
            jdbcTemplate.update("DELETE FROM public.campeonato_atleticas_publicos WHERE campeonato_atletica_id = ?", campeonatoAtleticaId);
        }
    }

    private void syncCampeonatoAtleta(UUID campeonatoAtletaId) {
        if (campeonatoAtletaId == null) {
            return;
        }
        jdbcTemplate.update("""
                INSERT INTO public.campeonato_atletas_publicos (
                    campeonato_atleta_id, campeonato_id, atletica_id, campeonato_time_id, atleta_id,
                    status, numero_camisa, is_capitao, is_goleiro, inscrito_em
                )
                SELECT id, campeonato_id, atletica_id, campeonato_time_id, atleta_id,
                       status, numero_camisa, is_capitao, is_goleiro, inscrito_em
                FROM operational.campeonato_atletas
                WHERE id = ?
                ON CONFLICT (campeonato_atleta_id) DO UPDATE SET
                    campeonato_id = EXCLUDED.campeonato_id,
                    atletica_id = EXCLUDED.atletica_id,
                    campeonato_time_id = EXCLUDED.campeonato_time_id,
                    atleta_id = EXCLUDED.atleta_id,
                    status = EXCLUDED.status,
                    numero_camisa = EXCLUDED.numero_camisa,
                    is_capitao = EXCLUDED.is_capitao,
                    is_goleiro = EXCLUDED.is_goleiro,
                    inscrito_em = EXCLUDED.inscrito_em
                """, campeonatoAtletaId);
    }

    private void syncCampeonatoTime(UUID campeonatoTimeId) {
        if (campeonatoTimeId == null) {
            return;
        }
        jdbcTemplate.update("""
                INSERT INTO public.campeonato_times_publicos (
                    campeonato_time_id, campeonato_id, campeonato_atletica_id, atletica_id,
                    campeonato_modalidade_id, modalidade_nome, modalidade_genero,
                    nome_equipe, status, criado_em, atualizado_em
                )
                SELECT
                    ct.id,
                    ct.campeonato_id,
                    ct.campeonato_atletica_id,
                    ca.atletica_id,
                    ct.campeonato_modalidade_id,
                    COALESCE(cm.nome_exibicao, mc.nome),
                    cm.genero,
                    COALESCE(NULLIF(ta.nome, ''), atl.nome),
                    ct.status,
                    ct.criado_em,
                    now()
                FROM operational.campeonato_times ct
                JOIN operational.campeonato_atleticas ca ON ca.id = ct.campeonato_atletica_id
                JOIN operational.campeonato_modalidades cm ON cm.id = ct.campeonato_modalidade_id
                JOIN operational.modalidades_catalogo mc ON mc.id = cm.modalidade_catalogo_id
                LEFT JOIN operational.times_atletica ta ON ta.id = ct.time_atletica_id
                LEFT JOIN operational.atleticas atl ON atl.id = ta.atletica_id
                WHERE ct.id = ?
                ON CONFLICT (campeonato_time_id) DO UPDATE SET
                    campeonato_id = EXCLUDED.campeonato_id,
                    campeonato_atletica_id = EXCLUDED.campeonato_atletica_id,
                    atletica_id = EXCLUDED.atletica_id,
                    campeonato_modalidade_id = EXCLUDED.campeonato_modalidade_id,
                    modalidade_nome = EXCLUDED.modalidade_nome,
                    modalidade_genero = EXCLUDED.modalidade_genero,
                    nome_equipe = EXCLUDED.nome_equipe,
                    status = EXCLUDED.status,
                    criado_em = EXCLUDED.criado_em,
                    atualizado_em = now()
                """, campeonatoTimeId);
    }

    private void deleteCampeonatoTime(UUID campeonatoTimeId) {
        if (campeonatoTimeId != null) {
            jdbcTemplate.update("DELETE FROM public.campeonato_times_publicos WHERE campeonato_time_id = ?", campeonatoTimeId);
        }
    }

    private void deleteCampeonatoAtleta(UUID campeonatoAtletaId) {
        if (campeonatoAtletaId != null) {
            jdbcTemplate.update("DELETE FROM public.campeonato_atletas_publicos WHERE campeonato_atleta_id = ?", campeonatoAtletaId);
        }
    }

    private void syncAtletica(UUID atleticaId) {
        if (atleticaId == null) {
            return;
        }
        jdbcTemplate.update("""
                INSERT INTO public.perfis_atleticas (
                    atletica_id, nome, sigla, slug, cor_principal, escudo_url, criado_por, status, criado_em, atualizado_em
                )
                SELECT id, nome, sigla, slug, cor_principal, escudo_url, criado_por, status, criado_em, now()
                FROM operational.atleticas
                WHERE id = ?
                ON CONFLICT (atletica_id) DO UPDATE SET
                    nome = EXCLUDED.nome,
                    sigla = EXCLUDED.sigla,
                    slug = EXCLUDED.slug,
                    cor_principal = EXCLUDED.cor_principal,
                    escudo_url = EXCLUDED.escudo_url,
                    criado_por = EXCLUDED.criado_por,
                    status = EXCLUDED.status,
                    criado_em = EXCLUDED.criado_em,
                    atualizado_em = now()
                """, atleticaId);
        refreshCampeonatoAtleticasByAtletica(atleticaId);
        refreshPartidasByAtletica(atleticaId);
    }

    private void deleteAtletica(UUID atleticaId) {
        if (atleticaId != null) {
            jdbcTemplate.update("DELETE FROM public.perfis_atleticas WHERE atletica_id = ?", atleticaId);
        }
    }

    private void refreshCampeonatoAtleticasByAtletica(UUID atleticaId) {
        jdbcTemplate.update("""
                UPDATE public.campeonato_atleticas_publicos cap
                SET atletica_nome = a.nome,
                    atletica_sigla = a.sigla,
                    atletica_escudo_url = a.escudo_url
                FROM operational.atleticas a
                WHERE a.id = ?
                  AND cap.atletica_id = a.id
                """, atleticaId);
    }

    private void refreshPartidasByAtletica(UUID atleticaId) {
        jdbcTemplate.update("""
                UPDATE public.partidas_ao_vivo pa
                SET time_a_escudo_url = a.escudo_url,
                    time_a_sigla = a.sigla,
                    time_a_nome = COALESCE((
                        SELECT ta.nome
                        FROM operational.campeonato_times ct
                        LEFT JOIN operational.times_atletica ta ON ta.id = ct.time_atletica_id
                        WHERE ct.id = pa.campeonato_time_a_id
                    ), a.nome),
                    atualizado_em = now()
                FROM operational.atleticas a
                WHERE a.id = ?
                  AND pa.time_a_atletica_id = a.id
                """, atleticaId);

        jdbcTemplate.update("""
                UPDATE public.partidas_ao_vivo pa
                SET time_b_escudo_url = a.escudo_url,
                    time_b_sigla = a.sigla,
                    time_b_nome = COALESCE((
                        SELECT tb.nome
                        FROM operational.campeonato_times ct
                        LEFT JOIN operational.times_atletica tb ON tb.id = ct.time_atletica_id
                        WHERE ct.id = pa.campeonato_time_b_id
                    ), a.nome),
                    atualizado_em = now()
                FROM operational.atleticas a
                WHERE a.id = ?
                  AND pa.time_b_atletica_id = a.id
                """, atleticaId);

        jdbcTemplate.update("""
                UPDATE public.partidas_historico ph
                SET time_a_escudo_url = a.escudo_url,
                    time_a_sigla = a.sigla,
                    time_a_atletica_nome = a.nome,
                    time_a_nome = COALESCE((
                        SELECT ta.nome
                        FROM operational.campeonato_times ct
                        LEFT JOIN operational.times_atletica ta ON ta.id = ct.time_atletica_id
                        WHERE ct.id = ph.campeonato_time_a_id
                    ), a.nome),
                    atualizado_em = now()
                FROM operational.atleticas a
                WHERE a.id = ?
                  AND ph.time_a_atletica_id = a.id
                """, atleticaId);

        jdbcTemplate.update("""
                UPDATE public.partidas_historico ph
                SET time_b_escudo_url = a.escudo_url,
                    time_b_sigla = a.sigla,
                    time_b_atletica_nome = a.nome,
                    time_b_nome = COALESCE((
                        SELECT tb.nome
                        FROM operational.campeonato_times ct
                        LEFT JOIN operational.times_atletica tb ON tb.id = ct.time_atletica_id
                        WHERE ct.id = ph.campeonato_time_b_id
                    ), a.nome),
                    atualizado_em = now()
                FROM operational.atleticas a
                WHERE a.id = ?
                  AND ph.time_b_atletica_id = a.id
                """, atleticaId);
    }

    private void syncAtleticaMembro(UUID atleticaMembroId) {
        if (atleticaMembroId == null) {
            return;
        }
        jdbcTemplate.update("""
                INSERT INTO public.atletica_membros_publicos (
                    atletica_membro_id, atletica_id, user_id, papel_codigo, status, criado_por, criado_em
                )
                SELECT id, atletica_id, user_id, papel_codigo, status, criado_por, criado_em
                FROM operational.atletica_membros
                WHERE id = ?
                ON CONFLICT (atletica_membro_id) DO UPDATE SET
                    atletica_id = EXCLUDED.atletica_id,
                    user_id = EXCLUDED.user_id,
                    papel_codigo = EXCLUDED.papel_codigo,
                    status = EXCLUDED.status,
                    criado_por = EXCLUDED.criado_por,
                    criado_em = EXCLUDED.criado_em
                """, atleticaMembroId);
    }

    private void deleteAtleticaMembro(UUID atleticaMembroId) {
        if (atleticaMembroId != null) {
            jdbcTemplate.update("DELETE FROM public.atletica_membros_publicos WHERE atletica_membro_id = ?", atleticaMembroId);
        }
    }

    private void syncProfile(UUID profileId) {
        if (profileId == null) {
            return;
        }
        jdbcTemplate.update("""
                INSERT INTO public.perfis_atletas (
                    atleta_id, nome_exibicao, nome_completo, avatar_url, data_nascimento, genero, status, criado_em, atualizado_em
                )
                SELECT id, nome_exibicao, nome_completo, avatar_url, data_nascimento, genero, status, criado_em, atualizado_em
                FROM operational.profiles
                WHERE id = ?
                ON CONFLICT (atleta_id) DO UPDATE SET
                    nome_exibicao = EXCLUDED.nome_exibicao,
                    nome_completo = EXCLUDED.nome_completo,
                    avatar_url = EXCLUDED.avatar_url,
                    data_nascimento = EXCLUDED.data_nascimento,
                    genero = EXCLUDED.genero,
                    status = EXCLUDED.status,
                    criado_em = EXCLUDED.criado_em,
                    atualizado_em = EXCLUDED.atualizado_em
                """, profileId);
    }

    private void upsertPartidaAoVivo(UUID partidaId) {
        log.info("Atualizando projeção partidas_ao_vivo para partida {}", partidaId);
        String sql = """
                INSERT INTO public.partidas_ao_vivo (
                    partida_id, campeonato_id, campeonato_modalidade_id, campeonato_time_a_id, campeonato_time_b_id,
                    status, periodo_atual, categoria, fase, agendado_para, iniciada_em, local,
                    placar_a, placar_b, versao_estado, time_a_nome, time_b_nome, time_a_sigla, time_b_sigla,
                    time_a_escudo_url, time_b_escudo_url, time_a_atletica_id, time_b_atletica_id, cronometro, atualizado_em
                )
                SELECT
                    p.id,
                    p.campeonato_id,
                    p.campeonato_modalidade_id,
                    p.campeonato_time_a_id,
                    p.campeonato_time_b_id,
                    p.status,
                    p.periodo_atual,
                    p.categoria,
                    p.fase,
                    p.agendado_para,
                    p.iniciada_em,
                    p.local,
                    p.placar_a,
                    p.placar_b,
                    p.versao_estado,
                    COALESCE(team_a.nome, atl_a.nome),
                    COALESCE(team_b.nome, atl_b.nome),
                    atl_a.sigla,
                    atl_b.sigla,
                    atl_a.escudo_url,
                    atl_b.escudo_url,
                    atl_a.id,
                    atl_b.id,
                    last_event.tempo_cronometro,
                    now()
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
                ON CONFLICT (partida_id) DO UPDATE SET
                    campeonato_id = EXCLUDED.campeonato_id,
                    campeonato_modalidade_id = EXCLUDED.campeonato_modalidade_id,
                    campeonato_time_a_id = EXCLUDED.campeonato_time_a_id,
                    campeonato_time_b_id = EXCLUDED.campeonato_time_b_id,
                    status = EXCLUDED.status,
                    periodo_atual = EXCLUDED.periodo_atual,
                    categoria = EXCLUDED.categoria,
                    fase = EXCLUDED.fase,
                    agendado_para = EXCLUDED.agendado_para,
                    iniciada_em = EXCLUDED.iniciada_em,
                    local = EXCLUDED.local,
                    placar_a = EXCLUDED.placar_a,
                    placar_b = EXCLUDED.placar_b,
                    versao_estado = EXCLUDED.versao_estado,
                    time_a_nome = EXCLUDED.time_a_nome,
                    time_b_nome = EXCLUDED.time_b_nome,
                    time_a_sigla = EXCLUDED.time_a_sigla,
                    time_b_sigla = EXCLUDED.time_b_sigla,
                    time_a_escudo_url = EXCLUDED.time_a_escudo_url,
                    time_b_escudo_url = EXCLUDED.time_b_escudo_url,
                    time_a_atletica_id = EXCLUDED.time_a_atletica_id,
                    time_b_atletica_id = EXCLUDED.time_b_atletica_id,
                    cronometro = EXCLUDED.cronometro,
                    atualizado_em = now()
                """;
        int affected = jdbcTemplate.update(sql, partidaId);
        log.info("Projeção partidas_ao_vivo para partida {} afetou {} linha(s)", partidaId, affected);
    }

    private void upsertPartidaHistorico(UUID partidaId) {
        log.info("Atualizando projeção partidas_historico para partida {}", partidaId);
        String sql = """
                INSERT INTO public.partidas_historico (
                    partida_id, campeonato_id, campeonato_modalidade_id, campeonato_time_a_id, campeonato_time_b_id,
                    status, periodo_atual, categoria, fase, agendado_para, iniciada_em, encerrada_em, local,
                    placar_a, placar_b, versao_estado, campeonato_nome, campeonato_slug, esporte_nome, modalidade_nome,
                    modalidade_codigo, time_a_nome, time_b_nome, time_a_sigla, time_b_sigla, time_a_escudo_url, time_b_escudo_url,
                    time_a_atletica_id, time_b_atletica_id, time_a_atletica_nome, time_b_atletica_nome,
                    resultado, houve_prorrogacao, houve_penaltis, placar_penaltis_a, placar_penaltis_b,
                    duracao_minutos, sumula_pdf_url, atualizado_em
                )
                SELECT
                    p.id,
                    c.id,
                    cm.id,
                    p.campeonato_time_a_id,
                    p.campeonato_time_b_id,
                    p.status,
                    p.periodo_atual,
                    p.categoria,
                    p.fase,
                    p.agendado_para,
                    p.iniciada_em,
                    p.encerrada_em,
                    p.local,
                    p.placar_a,
                    p.placar_b,
                    p.versao_estado,
                    c.nome,
                    c.slug,
                    esp.nome,
                    mc.nome,
                    mc.codigo,
                    COALESCE(tta.nome, atl_a.nome),
                    COALESCE(ttb.nome, atl_b.nome),
                    atl_a.sigla,
                    atl_b.sigla,
                    atl_a.escudo_url,
                    atl_b.escudo_url,
                    atl_a.id,
                    atl_b.id,
                    atl_a.nome,
                    atl_b.nome,
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
                    CASE
                        WHEN p.iniciada_em IS NOT NULL AND p.encerrada_em IS NOT NULL
                            THEN GREATEST(0, FLOOR(EXTRACT(EPOCH FROM (p.encerrada_em - p.iniciada_em)) / 60))::INTEGER
                        ELSE NULL
                    END,
                    p.sumula_pdf_url,
                    now()
                FROM operational.partidas p
                JOIN operational.campeonatos c ON c.id = p.campeonato_id
                JOIN operational.campeonato_modalidades cm ON cm.id = p.campeonato_modalidade_id
                JOIN operational.modalidades_catalogo mc ON mc.id = cm.modalidade_catalogo_id
                LEFT JOIN operational.esportes esp ON esp.id = mc.esporte_id
                LEFT JOIN operational.campeonato_times ta ON ta.id = p.campeonato_time_a_id
                LEFT JOIN operational.times_atletica tta ON tta.id = ta.time_atletica_id
                LEFT JOIN operational.atleticas atl_a ON atl_a.id = tta.atletica_id
                LEFT JOIN operational.campeonato_times tb ON tb.id = p.campeonato_time_b_id
                LEFT JOIN operational.times_atletica ttb ON ttb.id = tb.time_atletica_id
                LEFT JOIN operational.atleticas atl_b ON atl_b.id = ttb.atletica_id
                WHERE p.id = ?
                ON CONFLICT (partida_id) DO UPDATE SET
                    campeonato_id = EXCLUDED.campeonato_id,
                    campeonato_modalidade_id = EXCLUDED.campeonato_modalidade_id,
                    campeonato_time_a_id = EXCLUDED.campeonato_time_a_id,
                    campeonato_time_b_id = EXCLUDED.campeonato_time_b_id,
                    status = EXCLUDED.status,
                    periodo_atual = EXCLUDED.periodo_atual,
                    categoria = EXCLUDED.categoria,
                    fase = EXCLUDED.fase,
                    agendado_para = EXCLUDED.agendado_para,
                    iniciada_em = EXCLUDED.iniciada_em,
                    encerrada_em = EXCLUDED.encerrada_em,
                    local = EXCLUDED.local,
                    placar_a = EXCLUDED.placar_a,
                    placar_b = EXCLUDED.placar_b,
                    versao_estado = EXCLUDED.versao_estado,
                    campeonato_nome = EXCLUDED.campeonato_nome,
                    campeonato_slug = EXCLUDED.campeonato_slug,
                    esporte_nome = EXCLUDED.esporte_nome,
                    modalidade_nome = EXCLUDED.modalidade_nome,
                    modalidade_codigo = EXCLUDED.modalidade_codigo,
                    time_a_nome = EXCLUDED.time_a_nome,
                    time_b_nome = EXCLUDED.time_b_nome,
                    time_a_sigla = EXCLUDED.time_a_sigla,
                    time_b_sigla = EXCLUDED.time_b_sigla,
                    time_a_escudo_url = EXCLUDED.time_a_escudo_url,
                    time_b_escudo_url = EXCLUDED.time_b_escudo_url,
                    time_a_atletica_id = EXCLUDED.time_a_atletica_id,
                    time_b_atletica_id = EXCLUDED.time_b_atletica_id,
                    time_a_atletica_nome = EXCLUDED.time_a_atletica_nome,
                    time_b_atletica_nome = EXCLUDED.time_b_atletica_nome,
                    resultado = EXCLUDED.resultado,
                    houve_prorrogacao = EXCLUDED.houve_prorrogacao,
                    houve_penaltis = EXCLUDED.houve_penaltis,
                    placar_penaltis_a = EXCLUDED.placar_penaltis_a,
                    placar_penaltis_b = EXCLUDED.placar_penaltis_b,
                    duracao_minutos = EXCLUDED.duracao_minutos,
                    sumula_pdf_url = EXCLUDED.sumula_pdf_url,
                    atualizado_em = now()
                """;

        int affected = jdbcTemplate.update(sql, partidaId);
        log.info("Projeção partidas_historico para partida {} afetou {} linha(s)", partidaId, affected);
    }

    @SuppressWarnings("null")
    private void upsertEventoPublico(UUID eventoId) {
        log.info("Atualizando projeção eventos_partida_publicos para evento {}", eventoId);
        String sql = buildEventosPublicosUpsertSql("WHERE ev.id = ?");
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

    @SuppressWarnings("null")
    private void syncEventosPublicosDaPartida(UUID partidaId) {
        log.info("Sincronizando eventos públicos da partida {}", partidaId);
        String sql = buildEventosPublicosUpsertSql("WHERE ev.partida_id = ?");
        int affected = jdbcTemplate.update(sql, partidaId);
        log.info("Sincronização de eventos públicos da partida {} afetou {} linha(s)", partidaId, affected);
    }

    private String buildEventosPublicosUpsertSql(String whereClause) {
        return """
                INSERT INTO public.eventos_partida_publicos (
                    evento_id, partida_id, tipo_evento_id, tipo_evento_codigo, tipo_evento_nome, impacta_placar,
                    equipe_id, equipe_nome, atleta_id, atleta_nome_exibicao, atleta_foto_url,
                    atleta_sai_id, atleta_sai_nome, arbitro_user_id, periodo, minuto, segundo, tempo_cronometro,
                    descricao_detalhada, payload_json, is_substitution, ordem_evento, criado_em
                )
                SELECT
                    ev.id AS evento_id,
                    ev.partida_id,
                    te.id AS tipo_evento_id,
                    te.codigo AS tipo_evento_codigo,
                    te.nome AS tipo_evento_nome,
                    coalesce(te.impacta_placar, false) AS impacta_placar,
                    ta.id AS equipe_id,
                    COALESCE(t_atl.nome, atl_ta.nome) AS equipe_nome,
                    p.id AS atleta_id,
                    COALESCE(NULLIF(p.nome_exibicao, ''), p.nome_completo) AS atleta_nome_exibicao,
                    p.avatar_url AS atleta_foto_url,
                    p_sai.id AS atleta_sai_id,
                    COALESCE(NULLIF(p_sai.nome_exibicao, ''), p_sai.nome_completo) AS atleta_sai_nome,
                    ev.arbitro_user_id,
                    ev.periodo,
                    ev.minuto,
                    ev.segundo,
                    ev.tempo_cronometro,
                    ev.descricao_detalhada,
                    ev.payload_json,
                    ev.is_substitution,
                    ev.ordem_evento,
                    ev.criado_em
                FROM operational.eventos_partida ev
                LEFT JOIN operational.tipos_eventos te ON ev.tipo_evento_id = te.id
                LEFT JOIN operational.campeonato_times ta ON ev.equipe_id = ta.id
                LEFT JOIN operational.times_atletica t_atl ON ta.time_atletica_id = t_atl.id
                LEFT JOIN operational.atleticas atl_ta ON t_atl.atletica_id = atl_ta.id
                LEFT JOIN operational.profiles p ON ev.atleta_id = p.id
                LEFT JOIN operational.profiles p_sai ON ev.atleta_sai_id = p_sai.id
                """ + whereClause + """
                ON CONFLICT (evento_id) DO UPDATE SET
                    partida_id = EXCLUDED.partida_id,
                    tipo_evento_id = EXCLUDED.tipo_evento_id,
                    tipo_evento_codigo = EXCLUDED.tipo_evento_codigo,
                    tipo_evento_nome = EXCLUDED.tipo_evento_nome,
                    impacta_placar = EXCLUDED.impacta_placar,
                    equipe_id = EXCLUDED.equipe_id,
                    equipe_nome = EXCLUDED.equipe_nome,
                    atleta_id = EXCLUDED.atleta_id,
                    atleta_nome_exibicao = EXCLUDED.atleta_nome_exibicao,
                    atleta_foto_url = EXCLUDED.atleta_foto_url,
                    atleta_sai_id = EXCLUDED.atleta_sai_id,
                    atleta_sai_nome = EXCLUDED.atleta_sai_nome,
                    arbitro_user_id = EXCLUDED.arbitro_user_id,
                    periodo = EXCLUDED.periodo,
                    minuto = EXCLUDED.minuto,
                    segundo = EXCLUDED.segundo,
                    tempo_cronometro = EXCLUDED.tempo_cronometro,
                    descricao_detalhada = EXCLUDED.descricao_detalhada,
                    payload_json = EXCLUDED.payload_json,
                    is_substitution = EXCLUDED.is_substitution,
                    ordem_evento = EXCLUDED.ordem_evento,
                    criado_em = EXCLUDED.criado_em
                """;
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
