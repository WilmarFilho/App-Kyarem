-- =============================================================================
-- V4 - Catalogo de tipos de eventos por modalidade
-- Referencia: nova_arquitetura.txt secao 5.9
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TIPOS_EVENTOS
-- Catalogo de eventos separados por escopo:
--   PARTIDA - gerenciam relogio/estado (INICIO_1_TEMPO, FIM_1_TEMPO...)
--   EQUIPE  - pertencem a um time, sem individuo (TIMEOUT, PONTO_CONTRA...)
--   ATLETA  - acoes diretas de jogador (GOL, CESTA, CARTAO_AMARELO, SUBSTITUICAO...)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.tipos_eventos (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    modalidade_catalogo_id  UUID        NOT NULL REFERENCES operational.modalidades_catalogo(id),
    codigo                  VARCHAR(50) NOT NULL,
    nome                    VARCHAR(150) NOT NULL,
    escopo                  VARCHAR(20)  NOT NULL CHECK (escopo IN ('PARTIDA', 'EQUIPE', 'ATLETA')),
    impacta_placar          BOOLEAN      NOT NULL DEFAULT FALSE,
    pontos_pro              INTEGER,
    pontos_contra           INTEGER,
    payload_schema_json     JSONB,
    ordem_exibicao          INTEGER,
    ativo                   BOOLEAN      NOT NULL DEFAULT TRUE,
    UNIQUE (modalidade_catalogo_id, codigo)
);
