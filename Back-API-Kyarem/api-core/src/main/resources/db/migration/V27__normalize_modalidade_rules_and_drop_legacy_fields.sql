-- =============================================================================
-- V27 - Padroniza regras de modalidade e remove campos legados
-- =============================================================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'operational'
          AND table_name = 'modalidades_catalogo'
          AND column_name = 'slug'
    ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'operational'
          AND table_name = 'modalidades_catalogo'
          AND column_name = 'codigo'
    ) THEN
        ALTER TABLE operational.modalidades_catalogo
            RENAME COLUMN slug TO codigo;
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'operational'
          AND table_name = 'modalidades_catalogo'
          AND column_name = 'genero'
    ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'operational'
          AND table_name = 'modalidades_catalogo'
          AND column_name = 'descricao'
    ) THEN
        ALTER TABLE operational.modalidades_catalogo
            RENAME COLUMN genero TO descricao;
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'operational'
          AND table_name = 'modalidades_catalogo'
          AND column_name = 'motor_configs_default'
    ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'operational'
          AND table_name = 'modalidades_catalogo'
          AND column_name = 'regras_base_json'
    ) THEN
        ALTER TABLE operational.modalidades_catalogo
            RENAME COLUMN motor_configs_default TO regras_base_json;
    END IF;
END $$;

ALTER TABLE operational.modalidades_catalogo
    ADD COLUMN IF NOT EXISTS regras_base_json JSONB;

WITH defaults AS (
    SELECT
        id,
        CASE upper(coalesce(motor_regras, ''))
            WHEN 'VOLEI_V1' THEN jsonb_build_object(
                'tempoPartidaMinutos', 0,
                'periodos', 3,
                'cronometroParado', false,
                'tipoPontuacao', 'SETS',
                'setsParaVencer', 3,
                'pontosPorSet', 25,
                'faltasColetivasLimite', NULL,
                'permiteProrrogacao', false,
                'permitePenaltis', false,
                'eventosPermitidos', NULL
            )
            WHEN 'BASQUETE_V1' THEN jsonb_build_object(
                'tempoPartidaMinutos', 40,
                'periodos', 4,
                'cronometroParado', true,
                'tipoPontuacao', 'PONTOS',
                'setsParaVencer', NULL,
                'pontosPorSet', NULL,
                'faltasColetivasLimite', NULL,
                'permiteProrrogacao', false,
                'permitePenaltis', false,
                'eventosPermitidos', NULL
            )
            WHEN 'HANDEBOL_V1' THEN jsonb_build_object(
                'tempoPartidaMinutos', 60,
                'periodos', 2,
                'cronometroParado', true,
                'tipoPontuacao', 'GOLS',
                'setsParaVencer', NULL,
                'pontosPorSet', NULL,
                'faltasColetivasLimite', NULL,
                'permiteProrrogacao', false,
                'permitePenaltis', false,
                'eventosPermitidos', NULL
            )
            WHEN 'SOCIETY_V1' THEN jsonb_build_object(
                'tempoPartidaMinutos', 50,
                'periodos', 2,
                'cronometroParado', false,
                'tipoPontuacao', 'GOLS',
                'setsParaVencer', NULL,
                'pontosPorSet', NULL,
                'faltasColetivasLimite', NULL,
                'permiteProrrogacao', false,
                'permitePenaltis', false,
                'eventosPermitidos', NULL
            )
            WHEN 'FUTEBOL_CAMPO_V1' THEN jsonb_build_object(
                'tempoPartidaMinutos', 90,
                'periodos', 2,
                'cronometroParado', false,
                'tipoPontuacao', 'GOLS',
                'setsParaVencer', NULL,
                'pontosPorSet', NULL,
                'faltasColetivasLimite', NULL,
                'permiteProrrogacao', false,
                'permitePenaltis', false,
                'eventosPermitidos', NULL
            )
            WHEN 'GENERICO_V1' THEN jsonb_build_object(
                'tempoPartidaMinutos', 20,
                'periodos', 2,
                'cronometroParado', true,
                'tipoPontuacao', 'GOLS',
                'setsParaVencer', NULL,
                'pontosPorSet', NULL,
                'faltasColetivasLimite', NULL,
                'permiteProrrogacao', false,
                'permitePenaltis', false,
                'eventosPermitidos', NULL
            )
            ELSE jsonb_build_object(
                'tempoPartidaMinutos', 20,
                'periodos', 2,
                'cronometroParado', true,
                'tipoPontuacao', 'GOLS',
                'setsParaVencer', NULL,
                'pontosPorSet', NULL,
                'faltasColetivasLimite', 5,
                'permiteProrrogacao', false,
                'permitePenaltis', false,
                'eventosPermitidos', NULL
            )
        END AS base_rules
    FROM operational.modalidades_catalogo
)
UPDATE operational.modalidades_catalogo mc
SET regras_base_json = (
    defaults.base_rules
    || coalesce(mc.regras_base_json, '{}'::jsonb)
    || jsonb_build_object('eventosPermitidos', NULL)
)
FROM defaults
WHERE defaults.id = mc.id;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'operational'
          AND table_name = 'campeonato_modalidades'
          AND column_name = 'tempo_partida_minutos'
    ) THEN
        EXECUTE $sql$
            UPDATE operational.campeonato_modalidades
            SET regras_json = (
                coalesce(regras_json, '{}'::jsonb)
                || jsonb_strip_nulls(
                    jsonb_build_object(
                        'tempoPartidaMinutos', tempo_partida_minutos,
                        'permiteProrrogacao', CASE
                            WHEN permite_prorrogacao IS NOT NULL THEN to_jsonb(permite_prorrogacao)
                            ELSE NULL
                        END,
                        'permitePenaltis', CASE
                            WHEN permite_penaltis IS NOT NULL THEN to_jsonb(permite_penaltis)
                            ELSE NULL
                        END
                    )
                )
            )
        $sql$;
    END IF;
END $$;

ALTER TABLE operational.campeonato_modalidades
    DROP COLUMN IF EXISTS tempo_partida_minutos,
    DROP COLUMN IF EXISTS permite_prorrogacao,
    DROP COLUMN IF EXISTS permite_penaltis;
