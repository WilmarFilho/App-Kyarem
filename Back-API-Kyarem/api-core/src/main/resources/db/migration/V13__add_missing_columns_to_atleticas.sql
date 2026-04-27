-- -----------------------------------------------------------------------------
-- ATLETICAS: Adicionando colunas faltantes para validacao do Hibernate
-- -----------------------------------------------------------------------------
ALTER TABLE operational.atleticas
    ADD COLUMN IF NOT EXISTS cor_principal VARCHAR(7),
    ADD COLUMN IF NOT EXISTS escudo_url VARCHAR(500),
    ADD COLUMN IF NOT EXISTS presidente_id UUID;

UPDATE operational.atleticas
SET escudo_url = logo_url
WHERE escudo_url IS NULL
  AND logo_url IS NOT NULL;
