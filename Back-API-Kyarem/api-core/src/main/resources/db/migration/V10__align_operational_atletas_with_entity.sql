-- Alinha a tabela operational.atletas com a entidade JPA atual.
-- Mantemos colunas legadas para compatibilidade, mas adicionamos as
-- colunas que o Hibernate agora espera ao validar o schema.

ALTER TABLE operational.atletas
    ADD COLUMN IF NOT EXISTS atletica_id UUID REFERENCES operational.atleticas(id),
    ADD COLUMN IF NOT EXISTS nome VARCHAR(255) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS foto_url VARCHAR(500);
