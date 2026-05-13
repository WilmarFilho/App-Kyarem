-- =============================================================================
-- V33 - Enriquece atletas/atléticas públicas por campeonato e expõe times
-- =============================================================================

ALTER TABLE public.campeonato_atleticas_publicos
    ADD COLUMN IF NOT EXISTS atletica_nome VARCHAR(200),
    ADD COLUMN IF NOT EXISTS atletica_sigla VARCHAR(20),
    ADD COLUMN IF NOT EXISTS atletica_escudo_url VARCHAR(500);

UPDATE public.campeonato_atleticas_publicos cap
SET atletica_nome = a.nome,
    atletica_sigla = a.sigla,
    atletica_escudo_url = a.escudo_url
FROM operational.campeonato_atleticas ca
JOIN operational.atleticas a ON a.id = ca.atletica_id
WHERE ca.id = cap.campeonato_atletica_id;

CREATE TABLE IF NOT EXISTS public.campeonato_times_publicos (
    campeonato_time_id       UUID PRIMARY KEY,
    campeonato_id            UUID NOT NULL,
    campeonato_atletica_id   UUID NOT NULL,
    atletica_id              UUID NOT NULL,
    campeonato_modalidade_id UUID NOT NULL,
    modalidade_nome          VARCHAR(150),
    modalidade_genero        VARCHAR(30),
    nome_equipe              VARCHAR(200) NOT NULL,
    status                   VARCHAR(30) NOT NULL,
    criado_em                TIMESTAMPTZ NOT NULL,
    atualizado_em            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_campeonato_times_publicos_campeonato
    ON public.campeonato_times_publicos (campeonato_id, atletica_id);

CREATE INDEX IF NOT EXISTS idx_campeonato_times_publicos_atletica
    ON public.campeonato_times_publicos (campeonato_atletica_id, campeonato_modalidade_id);

INSERT INTO public.campeonato_times_publicos (
    campeonato_time_id,
    campeonato_id,
    campeonato_atletica_id,
    atletica_id,
    campeonato_modalidade_id,
    modalidade_nome,
    modalidade_genero,
    nome_equipe,
    status,
    criado_em,
    atualizado_em
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
    atualizado_em = now();

ALTER TABLE public.campeonato_times_publicos ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'campeonato_times_publicos'
          AND policyname = 'Permitir leitura anon e auth em campeonato_times_publicos'
    ) THEN
        CREATE POLICY "Permitir leitura anon e auth em campeonato_times_publicos"
            ON public.campeonato_times_publicos
            FOR SELECT
            TO anon, authenticated
            USING (true);
    END IF;
END $$;

GRANT SELECT ON public.campeonato_times_publicos TO anon, authenticated;
