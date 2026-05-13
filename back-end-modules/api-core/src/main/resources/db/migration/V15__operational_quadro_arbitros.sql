-- =============================================================================
-- V15 - Quadro de arbitragem para papel contextual REFEREE
-- =============================================================================

-- ---------------------------------------------------------------------------
-- QUADRO_ARBITROS
-- Materializa a existencia do arbitro antes de qualquer vinculo em partida.
-- O usuario continua com suas roles globais normais; o papel REFEREE vive aqui.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.quadro_arbitros (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES operational.profiles(id) ON DELETE CASCADE,
    status          VARCHAR(20) NOT NULL DEFAULT 'ATIVO'
                        CHECK (status IN ('ATIVO','INATIVO','SUSPENSO')),
    criado_por      UUID        REFERENCES operational.profiles(id),
    criado_em       TIMESTAMPTZ NOT NULL DEFAULT now(),
    iniciado_em     TIMESTAMPTZ,
    encerrado_em    TIMESTAMPTZ,
    observacoes     TEXT
);

-- Um usuario possui um unico registro no quadro de arbitragem; o status
-- desse registro representa se ele esta apto ou nao a arbitrar.
ALTER TABLE operational.quadro_arbitros
    ADD CONSTRAINT uq_quadro_arbitros_user_id UNIQUE (user_id);

CREATE INDEX IF NOT EXISTS idx_quadro_arbitros_user_id
    ON operational.quadro_arbitros (user_id);

CREATE INDEX IF NOT EXISTS idx_quadro_arbitros_status
    ON operational.quadro_arbitros (status);

-- Backfill: se o usuario ja apareceu em partida_arbitros, ele ja era tratado
-- operacionalmente como arbitro. Entao criamos seu registro ativo no quadro.
INSERT INTO operational.quadro_arbitros (
    user_id,
    status,
    criado_em,
    iniciado_em,
    observacoes
)
SELECT
    pa.arbitro_user_id,
    'ATIVO',
    MIN(pa.criado_em),
    MIN(pa.criado_em),
    'Backfill automatico a partir de operational.partida_arbitros'
FROM operational.partida_arbitros pa
LEFT JOIN operational.quadro_arbitros qa
    ON qa.user_id = pa.arbitro_user_id
   AND qa.status = 'ATIVO'
WHERE qa.id IS NULL
GROUP BY pa.arbitro_user_id;

-- Garante que todo arbitro vinculado a uma partida exista previamente
-- no quadro de arbitragem.
ALTER TABLE operational.partida_arbitros
    ADD CONSTRAINT fk_partida_arbitros_quadro_arbitros_user
    FOREIGN KEY (arbitro_user_id)
    REFERENCES operational.quadro_arbitros(user_id);

-- Alem da existencia no quadro, exige que o arbitro esteja ATIVO no momento
-- do vinculo com a partida.
CREATE OR REPLACE FUNCTION operational.validate_partida_arbitro_ativo()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM operational.quadro_arbitros qa
        WHERE qa.user_id = NEW.arbitro_user_id
          AND qa.status = 'ATIVO'
    ) THEN
        RAISE EXCEPTION 'Usuário % não possui vínculo ATIVO no quadro de arbitragem.', NEW.arbitro_user_id;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_partida_arbitro_ativo ON operational.partida_arbitros;

CREATE TRIGGER trg_validate_partida_arbitro_ativo
BEFORE INSERT OR UPDATE OF arbitro_user_id
ON operational.partida_arbitros
FOR EACH ROW
EXECUTE FUNCTION operational.validate_partida_arbitro_ativo();
