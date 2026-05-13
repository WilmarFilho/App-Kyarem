-- =============================================================================
-- V30 - Ajusta espelhos publicos e adiciona tabelas de relacionamento
-- =============================================================================

ALTER TABLE public.campeonatos_vitrine
    DROP COLUMN IF EXISTS slug;

ALTER TABLE public.eventos_partida_publicos
    DROP COLUMN IF EXISTS equipe_cor;

ALTER TABLE public.partidas_ao_vivo
    DROP COLUMN IF EXISTS time_a_cor_principal,
    DROP COLUMN IF EXISTS time_b_cor_principal;

ALTER TABLE public.partidas_historico
    DROP COLUMN IF EXISTS time_a_cor_principal,
    DROP COLUMN IF EXISTS time_b_cor_principal;

CREATE TABLE IF NOT EXISTS public.atletica_membros_publicos (
    atletica_membro_id       UUID        PRIMARY KEY,
    atletica_id              UUID        NOT NULL,
    user_id                  UUID        NOT NULL,
    papel_codigo             VARCHAR(30) NOT NULL,
    status                   VARCHAR(20) NOT NULL,
    criado_por               UUID,
    criado_em                TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_atletica_membros_publicos_user
    ON public.atletica_membros_publicos (user_id, papel_codigo, status);

CREATE INDEX IF NOT EXISTS idx_atletica_membros_publicos_atletica
    ON public.atletica_membros_publicos (atletica_id, papel_codigo, status);

CREATE TABLE IF NOT EXISTS public.campeonato_atleticas_publicos (
    campeonato_atletica_id   UUID        PRIMARY KEY,
    campeonato_id            UUID        NOT NULL,
    atletica_id              UUID        NOT NULL,
    criado_em                TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_campeonato_atleticas_publicos_campeonato
    ON public.campeonato_atleticas_publicos (campeonato_id, atletica_id);

CREATE INDEX IF NOT EXISTS idx_campeonato_atleticas_publicos_atletica
    ON public.campeonato_atleticas_publicos (atletica_id, campeonato_id);

CREATE TABLE IF NOT EXISTS public.campeonato_atletas_publicos (
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

CREATE INDEX IF NOT EXISTS idx_campeonato_atletas_publicos_atleta
    ON public.campeonato_atletas_publicos (atleta_id, campeonato_id, status);

CREATE INDEX IF NOT EXISTS idx_campeonato_atletas_publicos_atletica
    ON public.campeonato_atletas_publicos (atletica_id, campeonato_id, status);

CREATE INDEX IF NOT EXISTS idx_campeonato_atletas_publicos_time
    ON public.campeonato_atletas_publicos (campeonato_time_id, atleta_id);

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
FROM operational.atletica_membros am
ON CONFLICT (atletica_membro_id) DO UPDATE SET
    atletica_id = EXCLUDED.atletica_id,
    user_id = EXCLUDED.user_id,
    papel_codigo = EXCLUDED.papel_codigo,
    status = EXCLUDED.status,
    criado_por = EXCLUDED.criado_por,
    criado_em = EXCLUDED.criado_em;

INSERT INTO public.campeonato_atleticas_publicos (
    campeonato_atletica_id, campeonato_id, atletica_id, criado_em
)
SELECT
    ca.id,
    ca.campeonato_id,
    ca.atletica_id,
    ca.criado_em
FROM operational.campeonato_atleticas ca
ON CONFLICT (campeonato_atletica_id) DO UPDATE SET
    campeonato_id = EXCLUDED.campeonato_id,
    atletica_id = EXCLUDED.atletica_id,
    criado_em = EXCLUDED.criado_em;

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
FROM operational.campeonato_atletas ca
ON CONFLICT (campeonato_atleta_id) DO UPDATE SET
    campeonato_id = EXCLUDED.campeonato_id,
    atletica_id = EXCLUDED.atletica_id,
    campeonato_time_id = EXCLUDED.campeonato_time_id,
    atleta_id = EXCLUDED.atleta_id,
    status = EXCLUDED.status,
    numero_camisa = EXCLUDED.numero_camisa,
    is_capitao = EXCLUDED.is_capitao,
    is_goleiro = EXCLUDED.is_goleiro,
    inscrito_em = EXCLUDED.inscrito_em;
