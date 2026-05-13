-- =============================================================================
-- V2 - Identidade e autorizacao
-- Referencia: nova_arquitetura.txt secao 5.1
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PROFILES
-- 1:1 com auth.users. id = auth.users.id
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.profiles (
    id              UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nome_completo   VARCHAR(200),
    nome_exibicao   VARCHAR(100),
    email           VARCHAR(255),
    telefone        VARCHAR(30),
    avatar_url      VARCHAR(500),
    status          VARCHAR(30)     NOT NULL DEFAULT 'ATIVO',
    criado_em       TIMESTAMPTZ     NOT NULL DEFAULT now(),
    atualizado_em   TIMESTAMPTZ     NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- ROLES_GLOBAIS
-- Catalogo: USER, ADMIN
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.roles_globais (
    codigo  VARCHAR(30) PRIMARY KEY
);

INSERT INTO operational.roles_globais (codigo) VALUES ('USER'), ('ADMIN')
ON CONFLICT DO NOTHING;

-- -----------------------------------------------------------------------------
-- USUARIOS_ROLES_GLOBAIS
-- profiles 1:N usuarios_roles_globais
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.usuarios_roles_globais (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID        NOT NULL REFERENCES operational.profiles(id) ON DELETE CASCADE,
    role_codigo VARCHAR(30) NOT NULL REFERENCES operational.roles_globais(codigo),
    criado_em   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, role_codigo)
);

-- -----------------------------------------------------------------------------
-- PAPEIS_CONTEXTO
-- Catalogo: PRESIDENT, DIRECTOR, ATHLETE, REFEREE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.papeis_contexto (
    codigo  VARCHAR(30) PRIMARY KEY
);

INSERT INTO operational.papeis_contexto (codigo) VALUES
    ('PRESIDENT'), ('DIRECTOR'), ('ATHLETE'), ('REFEREE')
ON CONFLICT DO NOTHING;
