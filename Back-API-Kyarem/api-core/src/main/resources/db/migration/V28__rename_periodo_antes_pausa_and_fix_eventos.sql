-- =============================================================================
-- V28 - Renomeia status_antes_pausa → periodo_antes_pausa
--       Remove coluna rodada de operational.partidas
--       Adiciona periodo_atual a public.partidas_ao_vivo
--       Garante que ordem_evento é preenchido automaticamente
-- =============================================================================

-- 1. Renomear coluna na tabela operacional
ALTER TABLE operational.partidas
    RENAME COLUMN status_antes_pausa TO periodo_antes_pausa;

-- 2. Remover coluna rodada de operational.partidas
ALTER TABLE operational.partidas
    DROP COLUMN IF EXISTS rodada;

-- 3. Garantir que periodo_atual existe em operational.partidas (já deve existir, mas garante)
ALTER TABLE operational.partidas
    ADD COLUMN IF NOT EXISTS periodo_atual TEXT;

-- 4. Adicionar periodo_atual em public.partidas_ao_vivo se não existir
ALTER TABLE public.partidas_ao_vivo
    ADD COLUMN IF NOT EXISTS periodo_antes_pausa TEXT;

-- 5. Criar sequence para ordem_evento se não existir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_sequences WHERE schemaname = 'operational' AND sequencename = 'eventos_partida_ordem_seq') THEN
        CREATE SEQUENCE operational.eventos_partida_ordem_seq;
    END IF;
END;
$$;

-- 6. Definir default de ordem_evento usando a sequence (preenchimento automático)
ALTER TABLE operational.eventos_partida
    ALTER COLUMN ordem_evento SET DEFAULT nextval('operational.eventos_partida_ordem_seq');

-- 7. Preencher ordem_evento nos registros existentes que estejam NULL
UPDATE operational.eventos_partida
SET ordem_evento = nextval('operational.eventos_partida_ordem_seq')
WHERE ordem_evento IS NULL;

-- 8. Popular periodo e minuto/segundo nos eventos existentes que tenham tempo_cronometro
UPDATE operational.eventos_partida ep
SET
    minuto = CASE
        WHEN ep.tempo_cronometro ~ '^\d+:\d+$'
        THEN SPLIT_PART(ep.tempo_cronometro, ':', 1)::INTEGER
        ELSE NULL
    END,
    segundo = CASE
        WHEN ep.tempo_cronometro ~ '^\d+:\d+$'
        THEN SPLIT_PART(ep.tempo_cronometro, ':', 2)::INTEGER
        ELSE NULL
    END
WHERE ep.tempo_cronometro IS NOT NULL
  AND (ep.minuto IS NULL OR ep.segundo IS NULL);

-- 9. Popular payload_json nos eventos existentes que tenham descricao_detalhada mas payload nulo
UPDATE operational.eventos_partida
SET payload_json = jsonb_build_object('descricao', descricao_detalhada)
WHERE descricao_detalhada IS NOT NULL
  AND descricao_detalhada <> ''
  AND payload_json IS NULL;
