-- =============================================================================
-- V23 - Adiciona numero_camisa ao elenco permanente do time da atletica
-- Referencia: time_atletica_atletas (V7)
-- =============================================================================
-- A coluna e opcional (nullable). Quando preenchida, representa o numero
-- da camisa do atleta neste time permanente da atletica.
-- Faixa valida: 0 a 999.
-- =============================================================================

ALTER TABLE operational.time_atletica_atletas
    ADD COLUMN IF NOT EXISTS numero_camisa SMALLINT
        CONSTRAINT chk_numero_camisa_range
            CHECK (numero_camisa IS NULL OR (numero_camisa >= 0 AND numero_camisa <= 999));

COMMENT ON COLUMN operational.time_atletica_atletas.numero_camisa
    IS 'Numero da camisa do atleta neste time (0-999). NULL se nao informado.';
