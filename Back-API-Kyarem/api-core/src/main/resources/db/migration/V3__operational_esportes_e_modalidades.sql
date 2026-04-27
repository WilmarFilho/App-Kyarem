-- =============================================================================
-- V3 - Estrutura esportiva base
-- Referencia: nova_arquitetura.txt secao 5.2
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ESPORTES
-- Tipo macro do esporte (futebol, basquete, volei...)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.esportes (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    nome        VARCHAR(100) NOT NULL UNIQUE,
    criado_em   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- MODALIDADES_CATALOGO
-- Modalidades reais derivadas de um esporte
-- Exemplos: futebol -> futsal, society, campo | volei -> quadra, areia
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.modalidades_catalogo (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    esporte_id          UUID        NOT NULL REFERENCES operational.esportes(id),
    codigo              VARCHAR(50) NOT NULL UNIQUE,
    nome                VARCHAR(150) NOT NULL,
    descricao           TEXT,
    tipo_partida        VARCHAR(50),
    regras_base_json    JSONB,
    eventos_base_json   JSONB,
    ativo               BOOLEAN     NOT NULL DEFAULT TRUE
);
