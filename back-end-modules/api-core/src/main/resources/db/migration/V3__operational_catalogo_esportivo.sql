-- ==============================================================================
-- 2. CATÁLOGO ESPORTIVO
-- ==============================================================================

CREATE TABLE IF NOT EXISTS operational.esportes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS operational.modalidades_catalogo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    esporte_id UUID NOT NULL REFERENCES operational.esportes(id),
    nome VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL,
    genero VARCHAR(20) NOT NULL, -- MASCULINO, FEMININO, MISTO
    motor_regras VARCHAR(50) NOT NULL, -- FUTSAL_V1, VOLEI_V1, BASQUETE_V1
    motor_configs_default JSONB,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE(esporte_id, slug, genero)
);
