-- =============================================================================
-- V5 - Atleticas, membros e atletas
-- Referencia: nova_arquitetura.txt secao 5.4
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ATLETICAS
-- Entidade principal da atletica universitaria
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.atleticas (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    nome            VARCHAR(200) NOT NULL,
    sigla           VARCHAR(20)  NOT NULL,
    slug            VARCHAR(160),
    cor_principal   VARCHAR(50),
    escudo_url      VARCHAR(500),
    criado_por      UUID,
    status          VARCHAR(30)  NOT NULL DEFAULT 'ATIVA',
    criado_em       TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- ATLETICA_MEMBROS
-- Vinculo entre usuario e atletica com papel contextual
-- Papeis: PRESIDENT, DIRECTOR, ATHLETE
-- Status: CONVOCADO | ATIVO | INATIVO | RECUSADO
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.atletica_membros (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    atletica_id     UUID        NOT NULL REFERENCES operational.atleticas(id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES operational.profiles(id),
    papel_codigo    VARCHAR(30) NOT NULL REFERENCES operational.papeis_contexto(codigo),
    status          VARCHAR(20) NOT NULL DEFAULT 'CONVOCADO'
                        CHECK (status IN ('CONVOCADO','ATIVO','INATIVO','RECUSADO')),
    criado_por      UUID,
    criado_em       TIMESTAMPTZ NOT NULL DEFAULT now(),
    iniciado_em     TIMESTAMPTZ,
    encerrado_em    TIMESTAMPTZ
);

-- Garante no maximo um PRESIDENT ativo por atletica
CREATE UNIQUE INDEX IF NOT EXISTS uq_atletica_president_ativo
    ON operational.atletica_membros (atletica_id)
    WHERE papel_codigo = 'PRESIDENT' AND status = 'ATIVO';

-- -----------------------------------------------------------------------------
-- ATLETAS
-- Extensao de um profile para contexto esportivo
-- user_id unico: uma pessoa = um atleta
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.atletas (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID        UNIQUE REFERENCES operational.profiles(id),
    nome_competicao     VARCHAR(200),
    foto_url            VARCHAR(500),
    data_nascimento     DATE,
    genero              VARCHAR(30),
    ativo               BOOLEAN     NOT NULL DEFAULT TRUE,
    criado_em           TIMESTAMPTZ NOT NULL DEFAULT now()
);
