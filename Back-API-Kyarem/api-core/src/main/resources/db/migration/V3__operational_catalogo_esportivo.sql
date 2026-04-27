-- ==============================================================================
-- 2. CATÁLOGO ESPORTIVO
-- ==============================================================================

CREATE TABLE operational.esportes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(100) NOT NULL UNIQUE,
    slug VARCHAR(100) NOT NULL UNIQUE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE operational.modalidades_catalogo (
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

CREATE TABLE operational.tipos_eventos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    modalidade_id UUID NOT NULL REFERENCES operational.modalidades_catalogo(id),
    codigo VARCHAR(50) NOT NULL, -- Ex: GOL_A_FAVOR, FALTA_COMUM, CARTAO_AMARELO
    nome VARCHAR(100) NOT NULL,
    escopo VARCHAR(20) NOT NULL, -- PARTIDA, EQUIPE, ATLETA
    afeta_placar BOOLEAN NOT NULL DEFAULT FALSE,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE(modalidade_id, codigo)
);
