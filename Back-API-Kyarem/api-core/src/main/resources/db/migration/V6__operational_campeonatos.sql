-- =============================================================================
-- V6 - Campeonatos, modalidades e participacao das atleticas
-- Referencia: nova_arquitetura.txt secoes 5.3 e 5.5
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CAMPEONATOS
-- Campeonato base
-- Status: EM_PLANEJAMENTO | INSCRICOES_ABERTAS | EM_ANDAMENTO | ENCERRADO | CANCELADO
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.campeonatos (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    nome        VARCHAR(200) NOT NULL,
    slug        VARCHAR(160),
    nivel       VARCHAR(50),
    data_inicio DATE,
    data_fim    DATE,
    status      VARCHAR(30)  NOT NULL DEFAULT 'EM_PLANEJAMENTO',
    escudo_url  VARCHAR(500),
    criado_em   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- CAMPEONATO_MODALIDADES
-- Instancia de uma modalidade dentro de um campeonato especifico
-- Permite regras diferentes por campeonato
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.campeonato_modalidades (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    campeonato_id           UUID        NOT NULL REFERENCES operational.campeonatos(id) ON DELETE CASCADE,
    modalidade_catalogo_id  UUID        NOT NULL REFERENCES operational.modalidades_catalogo(id),
    nome_exibicao           VARCHAR(150),
    categoria               VARCHAR(50),
    genero                  VARCHAR(30),
    regras_json             JSONB,
    formato_fases_json      JSONB,
    tempo_partida_minutos   INTEGER,
    permite_prorrogacao     BOOLEAN     NOT NULL DEFAULT FALSE,
    permite_penaltis        BOOLEAN     NOT NULL DEFAULT FALSE,
    status                  VARCHAR(30) NOT NULL DEFAULT 'ATIVA'
);

-- -----------------------------------------------------------------------------
-- CAMPEONATO_ATLETICAS
-- Vinculo da atletica com o campeonato
-- campeonatos N:N atleticas
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.campeonato_atleticas (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    campeonato_id   UUID        NOT NULL REFERENCES operational.campeonatos(id) ON DELETE CASCADE,
    atletica_id     UUID        NOT NULL REFERENCES operational.atleticas(id),
    status          VARCHAR(30) NOT NULL DEFAULT 'PENDENTE',
    aprovado_por    UUID,
    criado_em       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (campeonato_id, atletica_id)
);
