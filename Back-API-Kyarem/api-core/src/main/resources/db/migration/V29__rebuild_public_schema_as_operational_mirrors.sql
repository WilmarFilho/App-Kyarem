-- =============================================================================
-- V29 - Reconstroi o schema public como espelho controlado do operational
-- Remove read models fora do escopo atual e recria os espelhos validados.
-- =============================================================================

DROP TABLE IF EXISTS public.artilharia CASCADE;
DROP TABLE IF EXISTS public.classificacoes CASCADE;
DROP TABLE IF EXISTS public.comentarios_publicos CASCADE;
DROP TABLE IF EXISTS public.contadores_sociais CASCADE;
DROP TABLE IF EXISTS public.estatisticas_partida CASCADE;
DROP TABLE IF EXISTS public.feed_posts CASCADE;
DROP TABLE IF EXISTS public.metricas_atletas CASCADE;
DROP TABLE IF EXISTS public.ranking_assistencias CASCADE;
DROP TABLE IF EXISTS public.ranking_geral_campeonato CASCADE;
DROP TABLE IF EXISTS public.snapshot_comparacao_atletas CASCADE;
DROP TABLE IF EXISTS public.snapshot_comparacao_times CASCADE;
DROP TABLE IF EXISTS public.timeline_campeonato CASCADE;

DROP TABLE IF EXISTS public.eventos_partida_publicos CASCADE;
DROP TABLE IF EXISTS public.partidas_ao_vivo CASCADE;
DROP TABLE IF EXISTS public.partidas_historico CASCADE;
DROP TABLE IF EXISTS public.modalidades_vitrine CASCADE;
DROP TABLE IF EXISTS public.campeonatos_vitrine CASCADE;
DROP TABLE IF EXISTS public.perfis_atletas CASCADE;
DROP TABLE IF EXISTS public.perfis_atleticas CASCADE;

CREATE TABLE public.campeonatos_vitrine (
    campeonato_id       UUID        PRIMARY KEY,
    nome                VARCHAR(200) NOT NULL,
    nivel               VARCHAR(50),
    data_inicio         DATE,
    data_fim            DATE,
    status              VARCHAR(30) NOT NULL,
    escudo_url          VARCHAR(500),
    criado_em           TIMESTAMPTZ NOT NULL,
    atualizado_em       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.modalidades_vitrine (
    campeonato_modalidade_id UUID        PRIMARY KEY,
    campeonato_id            UUID        NOT NULL,
    modalidade_catalogo_id   UUID        NOT NULL,
    esporte_id               UUID,
    esporte_nome             VARCHAR(100),
    modalidade_nome          VARCHAR(150),
    modalidade_codigo        VARCHAR(100),
    nome_exibicao            VARCHAR(150),
    categoria                VARCHAR(50),
    genero                   VARCHAR(30),
    regras_json              JSONB,
    formato_fases_json       JSONB,
    status                   VARCHAR(30) NOT NULL,
    atualizado_em            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_modalidades_vitrine_campeonato
    ON public.modalidades_vitrine (campeonato_id);

CREATE TABLE public.partidas_ao_vivo (
    partida_id               UUID        PRIMARY KEY,
    campeonato_id            UUID        NOT NULL,
    campeonato_modalidade_id UUID        NOT NULL,
    campeonato_time_a_id     UUID,
    campeonato_time_b_id     UUID,
    status                   VARCHAR(30) NOT NULL,
    periodo_atual            VARCHAR(30),
    categoria                VARCHAR(50),
    fase                     VARCHAR(50),
    agendado_para            TIMESTAMPTZ,
    iniciada_em              TIMESTAMPTZ,
    local                    VARCHAR(300),
    placar_a                 INTEGER     NOT NULL DEFAULT 0,
    placar_b                 INTEGER     NOT NULL DEFAULT 0,
    versao_estado            BIGINT      NOT NULL DEFAULT 0,
    time_a_nome              VARCHAR(200),
    time_b_nome              VARCHAR(200),
    time_a_sigla             VARCHAR(20),
    time_b_sigla             VARCHAR(20),
    time_a_escudo_url        VARCHAR(500),
    time_b_escudo_url        VARCHAR(500),
    time_a_atletica_id       UUID,
    time_b_atletica_id       UUID,
    cronometro               VARCHAR(20),
    atualizado_em            TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_partidas_ao_vivo_status
        CHECK (lower(trim(status)) NOT IN ('agendada', 'finalizada', 'fechada', 'cancelada', 'wo'))
);

CREATE INDEX idx_partidas_ao_vivo_modalidade
    ON public.partidas_ao_vivo (campeonato_modalidade_id, atualizado_em DESC);

CREATE TABLE public.partidas_historico (
    partida_id               UUID        PRIMARY KEY,
    campeonato_id            UUID        NOT NULL,
    campeonato_modalidade_id UUID        NOT NULL,
    campeonato_time_a_id     UUID,
    campeonato_time_b_id     UUID,
    status                   VARCHAR(30) NOT NULL,
    periodo_atual            VARCHAR(30),
    categoria                VARCHAR(50),
    fase                     VARCHAR(50),
    agendado_para            TIMESTAMPTZ,
    iniciada_em              TIMESTAMPTZ,
    encerrada_em             TIMESTAMPTZ,
    local                    VARCHAR(300),
    placar_a                 INTEGER     NOT NULL DEFAULT 0,
    placar_b                 INTEGER     NOT NULL DEFAULT 0,
    versao_estado            BIGINT      NOT NULL DEFAULT 0,
    campeonato_nome          VARCHAR(200),
    campeonato_slug          VARCHAR(160),
    esporte_nome             VARCHAR(100),
    modalidade_nome          VARCHAR(150),
    modalidade_codigo        VARCHAR(100),
    time_a_nome              VARCHAR(200),
    time_b_nome              VARCHAR(200),
    time_a_sigla             VARCHAR(20),
    time_b_sigla             VARCHAR(20),
    time_a_escudo_url        VARCHAR(500),
    time_b_escudo_url        VARCHAR(500),
    time_a_atletica_id       UUID,
    time_b_atletica_id       UUID,
    time_a_atletica_nome     VARCHAR(200),
    time_b_atletica_nome     VARCHAR(200),
    resultado                VARCHAR(20) CHECK (resultado IN ('VITORIA_A','EMPATE','VITORIA_B')),
    houve_prorrogacao        BOOLEAN     NOT NULL DEFAULT FALSE,
    houve_penaltis           BOOLEAN     NOT NULL DEFAULT FALSE,
    placar_penaltis_a        INTEGER,
    placar_penaltis_b        INTEGER,
    duracao_minutos          INTEGER,
    sumula_pdf_url           VARCHAR(500),
    atualizado_em            TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_partidas_historico_status
        CHECK (lower(trim(status)) IN ('finalizada', 'fechada'))
);

CREATE INDEX idx_partidas_historico_modalidade
    ON public.partidas_historico (campeonato_modalidade_id, encerrada_em DESC NULLS LAST, atualizado_em DESC);

CREATE TABLE public.eventos_partida_publicos (
    evento_id                UUID        PRIMARY KEY,
    partida_id               UUID        NOT NULL,
    tipo_evento_id           UUID,
    tipo_evento_codigo       VARCHAR(50),
    tipo_evento_nome         VARCHAR(150),
    impacta_placar           BOOLEAN     NOT NULL DEFAULT FALSE,
    equipe_id                UUID,
    equipe_nome              VARCHAR(200),
    atleta_id                UUID,
    atleta_nome_exibicao     VARCHAR(200),
    atleta_foto_url          VARCHAR(500),
    atleta_sai_id            UUID,
    atleta_sai_nome          VARCHAR(200),
    arbitro_user_id          UUID,
    periodo                  VARCHAR(30),
    minuto                   INTEGER,
    segundo                  INTEGER,
    tempo_cronometro         VARCHAR(20),
    descricao_detalhada      TEXT,
    payload_json             JSONB,
    is_substitution          BOOLEAN     NOT NULL DEFAULT FALSE,
    ordem_evento             BIGINT,
    criado_em                TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_eventos_publicos_partida
    ON public.eventos_partida_publicos (partida_id, criado_em, ordem_evento);

CREATE TABLE public.perfis_atletas (
    atleta_id                UUID        PRIMARY KEY,
    nome_exibicao            VARCHAR(100),
    nome_completo            VARCHAR(200),
    avatar_url               VARCHAR(500),
    data_nascimento          DATE,
    genero                   VARCHAR(30),
    status                   VARCHAR(30) NOT NULL,
    criado_em                TIMESTAMPTZ NOT NULL,
    atualizado_em            TIMESTAMPTZ NOT NULL
);

CREATE TABLE public.perfis_atleticas (
    atletica_id              UUID        PRIMARY KEY,
    nome                     VARCHAR(200) NOT NULL,
    sigla                    VARCHAR(20) NOT NULL,
    slug                     VARCHAR(160),
    cor_principal            VARCHAR(50),
    escudo_url               VARCHAR(500),
    criado_por               UUID,
    status                   VARCHAR(30) NOT NULL,
    criado_em                TIMESTAMPTZ NOT NULL,
    atualizado_em            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.atletica_membros_publicos (
    atletica_membro_id       UUID        PRIMARY KEY,
    atletica_id              UUID        NOT NULL,
    user_id                  UUID        NOT NULL,
    papel_codigo             VARCHAR(30) NOT NULL,
    status                   VARCHAR(20) NOT NULL,
    criado_por               UUID,
    criado_em                TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_atletica_membros_publicos_user
    ON public.atletica_membros_publicos (user_id, papel_codigo, status);

CREATE INDEX idx_atletica_membros_publicos_atletica
    ON public.atletica_membros_publicos (atletica_id, papel_codigo, status);

CREATE TABLE public.campeonato_atleticas_publicos (
    campeonato_atletica_id   UUID        PRIMARY KEY,
    campeonato_id            UUID        NOT NULL,
    atletica_id              UUID        NOT NULL,
    criado_em                TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_campeonato_atleticas_publicos_campeonato
    ON public.campeonato_atleticas_publicos (campeonato_id, atletica_id);

CREATE INDEX idx_campeonato_atleticas_publicos_atletica
    ON public.campeonato_atleticas_publicos (atletica_id, campeonato_id);

CREATE TABLE public.campeonato_atletas_publicos (
    campeonato_atleta_id     UUID        PRIMARY KEY,
    campeonato_id            UUID        NOT NULL,
    atletica_id              UUID        NOT NULL,
    campeonato_time_id       UUID        NOT NULL,
    atleta_id                UUID        NOT NULL,
    status                   VARCHAR(30) NOT NULL,
    numero_camisa            INTEGER,
    is_capitao               BOOLEAN     NOT NULL DEFAULT FALSE,
    is_goleiro               BOOLEAN     NOT NULL DEFAULT FALSE,
    inscrito_em              TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_campeonato_atletas_publicos_atleta
    ON public.campeonato_atletas_publicos (atleta_id, campeonato_id, status);

CREATE INDEX idx_campeonato_atletas_publicos_atletica
    ON public.campeonato_atletas_publicos (atletica_id, campeonato_id, status);

CREATE INDEX idx_campeonato_atletas_publicos_time
    ON public.campeonato_atletas_publicos (campeonato_time_id, atleta_id);

INSERT INTO public.campeonatos_vitrine (
    campeonato_id, nome, nivel, data_inicio, data_fim, status, escudo_url, criado_em, atualizado_em
)
SELECT
    c.id, c.nome, c.nivel, c.data_inicio, c.data_fim, c.status, c.escudo_url, c.criado_em, now()
FROM operational.campeonatos c;

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
LEFT JOIN operational.esportes e ON e.id = mc.esporte_id;

INSERT INTO public.perfis_atletas (
    atleta_id, nome_exibicao, nome_completo, avatar_url, data_nascimento, genero, status, criado_em, atualizado_em
)
SELECT
    p.id,
    p.nome_exibicao,
    p.nome_completo,
    p.avatar_url,
    p.data_nascimento,
    p.genero,
    p.status,
    p.criado_em,
    p.atualizado_em
FROM operational.profiles p;

INSERT INTO public.perfis_atleticas (
    atletica_id, nome, sigla, slug, cor_principal, escudo_url, criado_por, status, criado_em, atualizado_em
)
SELECT
    a.id,
    a.nome,
    a.sigla,
    a.slug,
    a.cor_principal,
    a.escudo_url,
    a.criado_por,
    a.status,
    a.criado_em,
    now()
FROM operational.atleticas a;

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
    COALESCE(tta.nome, atl_a.nome),
    COALESCE(ttb.nome, atl_b.nome),
    atl_a.sigla,
    atl_b.sigla,
    atl_a.escudo_url,
    atl_b.escudo_url,
    atl_a.id,
    atl_b.id,
    last_event.tempo_cronometro,
    now()
FROM operational.partidas p
LEFT JOIN operational.campeonato_times cta ON cta.id = p.campeonato_time_a_id
LEFT JOIN operational.times_atletica tta ON tta.id = cta.time_atletica_id
LEFT JOIN operational.atleticas atl_a ON atl_a.id = tta.atletica_id
LEFT JOIN operational.campeonato_times ctb ON ctb.id = p.campeonato_time_b_id
LEFT JOIN operational.times_atletica ttb ON ttb.id = ctb.time_atletica_id
LEFT JOIN operational.atleticas atl_b ON atl_b.id = ttb.atletica_id
LEFT JOIN LATERAL (
    SELECT ev.tempo_cronometro
    FROM operational.eventos_partida ev
    WHERE ev.partida_id = p.id
    ORDER BY ev.criado_em DESC, ev.ordem_evento DESC NULLS LAST
    LIMIT 1
) last_event ON TRUE
WHERE lower(trim(coalesce(p.status, ''))) NOT IN ('agendada', 'finalizada', 'fechada', 'cancelada', 'wo');

INSERT INTO public.partidas_historico (
    partida_id, campeonato_id, campeonato_modalidade_id, campeonato_time_a_id, campeonato_time_b_id,
    status, periodo_atual, categoria, fase, agendado_para, iniciada_em, encerrada_em, local,
    placar_a, placar_b, versao_estado, campeonato_nome, campeonato_slug, esporte_nome, modalidade_nome,
    modalidade_codigo, time_a_nome, time_b_nome, time_a_sigla, time_b_sigla, time_a_escudo_url, time_b_escudo_url,
    time_a_atletica_id, time_b_atletica_id, time_a_atletica_nome, time_b_atletica_nome,
    resultado, houve_prorrogacao, houve_penaltis,
    placar_penaltis_a, placar_penaltis_b, duracao_minutos, sumula_pdf_url, atualizado_em
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
    p.encerrada_em,
    p.local,
    p.placar_a,
    p.placar_b,
    p.versao_estado,
    c.nome,
    NULL,
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
LEFT JOIN operational.campeonato_times cta ON cta.id = p.campeonato_time_a_id
LEFT JOIN operational.times_atletica tta ON tta.id = cta.time_atletica_id
LEFT JOIN operational.atleticas atl_a ON atl_a.id = tta.atletica_id
LEFT JOIN operational.campeonato_times ctb ON ctb.id = p.campeonato_time_b_id
LEFT JOIN operational.times_atletica ttb ON ttb.id = ctb.time_atletica_id
LEFT JOIN operational.atleticas atl_b ON atl_b.id = ttb.atletica_id
WHERE lower(trim(coalesce(p.status, ''))) IN ('finalizada', 'fechada');

INSERT INTO public.eventos_partida_publicos (
    evento_id, partida_id, tipo_evento_id, tipo_evento_codigo, tipo_evento_nome, impacta_placar,
    equipe_id, equipe_nome, atleta_id, atleta_nome_exibicao, atleta_foto_url,
    atleta_sai_id, atleta_sai_nome, arbitro_user_id, periodo, minuto, segundo, tempo_cronometro,
    descricao_detalhada, payload_json, is_substitution, ordem_evento, criado_em
)
SELECT
    ev.id,
    ev.partida_id,
    te.id,
    te.codigo,
    te.nome,
    coalesce(te.impacta_placar, false),
    ct.id,
    COALESCE(tt.nome, atl.nome),
    ap.id,
    COALESCE(NULLIF(ap.nome_exibicao, ''), ap.nome_completo),
    ap.avatar_url,
    ap_sai.id,
    COALESCE(NULLIF(ap_sai.nome_exibicao, ''), ap_sai.nome_completo),
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
LEFT JOIN operational.tipos_eventos te ON te.id = ev.tipo_evento_id
LEFT JOIN operational.campeonato_times ct ON ct.id = ev.equipe_id
LEFT JOIN operational.times_atletica tt ON tt.id = ct.time_atletica_id
LEFT JOIN operational.atleticas atl ON atl.id = tt.atletica_id
LEFT JOIN operational.profiles ap ON ap.id = ev.atleta_id
LEFT JOIN operational.profiles ap_sai ON ap_sai.id = ev.atleta_sai_id;

INSERT INTO public.atletica_membros_publicos (
    atletica_membro_id, atletica_id, user_id, papel_codigo, status, criado_por, criado_em
)
SELECT
    am.id,
    am.atletica_id,
    am.user_id,
    am.papel_codigo,
    am.status,
    am.criado_por,
    am.criado_em
FROM operational.atletica_membros am;

INSERT INTO public.campeonato_atleticas_publicos (
    campeonato_atletica_id, campeonato_id, atletica_id, criado_em
)
SELECT
    ca.id,
    ca.campeonato_id,
    ca.atletica_id,
    ca.criado_em
FROM operational.campeonato_atleticas ca;

INSERT INTO public.campeonato_atletas_publicos (
    campeonato_atleta_id, campeonato_id, atletica_id, campeonato_time_id, atleta_id,
    status, numero_camisa, is_capitao, is_goleiro, inscrito_em
)
SELECT
    ca.id,
    ca.campeonato_id,
    ca.atletica_id,
    ca.campeonato_time_id,
    ca.atleta_id,
    ca.status,
    ca.numero_camisa,
    ca.is_capitao,
    ca.is_goleiro,
    ca.inscrito_em
FROM operational.campeonato_atletas ca;
