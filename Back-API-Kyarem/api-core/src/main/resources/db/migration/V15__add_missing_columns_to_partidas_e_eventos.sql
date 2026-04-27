-- -----------------------------------------------------------------------------
-- PARTIDAS E EVENTOS: Adicionando colunas faltantes para validacao do Hibernate
-- -----------------------------------------------------------------------------

-- 1. EVENTOS_PARTIDA
ALTER TABLE operational.eventos_partida
    ADD COLUMN IF NOT EXISTS atleta_sai_id UUID REFERENCES operational.atletas(id),
    ADD COLUMN IF NOT EXISTS descricao_detalhada TEXT,
    ADD COLUMN IF NOT EXISTS is_substitution BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS local_evento_id VARCHAR(255) UNIQUE;

-- 2. PARTIDA_ARBITROS
-- O Hibernate espera um @Id do tipo UUID (coluna id)
-- A tabela original usava PRIMARY KEY (partida_id, user_id)
ALTER TABLE operational.partida_arbitros DROP CONSTRAINT IF EXISTS partida_arbitros_pkey;

ALTER TABLE operational.partida_arbitros
    ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid(),
    ADD COLUMN IF NOT EXISTS arbitro_id UUID REFERENCES operational.profiles(id),
    ADD COLUMN IF NOT EXISTS criado_em TIMESTAMP NOT NULL DEFAULT NOW();

-- Adiciona a nova PK se nao existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_schema = 'operational'
          AND table_name = 'partida_arbitros'
          AND constraint_type = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE operational.partida_arbitros ADD PRIMARY KEY (id);
    END IF;
END $$;

-- Faz backfill do arbitro_id usando user_id se necessario
UPDATE operational.partida_arbitros
SET arbitro_id = user_id
WHERE arbitro_id IS NULL
  AND user_id IS NOT NULL;
