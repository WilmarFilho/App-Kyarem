-- -----------------------------------------------------------------------------
-- CAMPEONATOS: Adicionando colunas faltantes para validacao do Hibernate
-- -----------------------------------------------------------------------------
ALTER TABLE operational.campeonatos
    ADD COLUMN IF NOT EXISTS data_inicio DATE,
    ADD COLUMN IF NOT EXISTS data_fim DATE,
    ADD COLUMN IF NOT EXISTS escudo_url VARCHAR(500);

UPDATE operational.campeonatos
SET escudo_url = logo_url
WHERE escudo_url IS NULL
  AND logo_url IS NOT NULL;
