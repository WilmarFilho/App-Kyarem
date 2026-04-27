-- =============================================================================
-- V7 - Times da atletica, elenco permanente, inscricao no campeonato e staff
-- Referencia: nova_arquitetura.txt secoes 5.6, 5.7 e 5.8
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TIMES_ATLETICA
-- Times permanentes da atletica por modalidade
-- Existem independente de campeonatos
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.times_atletica (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    atletica_id             UUID        NOT NULL REFERENCES operational.atleticas(id) ON DELETE CASCADE,
    modalidade_catalogo_id  UUID        NOT NULL REFERENCES operational.modalidades_catalogo(id),
    nome                    VARCHAR(200) NOT NULL,
    categoria               VARCHAR(50),
    genero                  VARCHAR(30),
    status                  VARCHAR(30)  NOT NULL DEFAULT 'ATIVO',
    criado_por              UUID,
    criado_em               TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- TIME_ATLETICA_ATLETAS
-- Elenco do time permanente da atletica
-- O atleta deve possuir role ATHLETE (ATIVO) em atletica_membros
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.time_atletica_atletas (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    time_atletica_id    UUID        NOT NULL REFERENCES operational.times_atletica(id) ON DELETE CASCADE,
    atleta_id           UUID        NOT NULL REFERENCES operational.atletas(id),
    status              VARCHAR(20) NOT NULL DEFAULT 'ATIVO' CHECK (status IN ('ATIVO','REMOVIDO')),
    adicionado_por      UUID,
    adicionado_em       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (time_atletica_id, atleta_id)
);

-- -----------------------------------------------------------------------------
-- CAMPEONATO_TIMES
-- Time da atletica inscrito em uma modalidade especifica do campeonato
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.campeonato_times (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    campeonato_id           UUID        NOT NULL REFERENCES operational.campeonatos(id),
    campeonato_atletica_id  UUID        NOT NULL REFERENCES operational.campeonato_atleticas(id),
    campeonato_modalidade_id UUID       NOT NULL REFERENCES operational.campeonato_modalidades(id),
    time_atletica_id        UUID        NOT NULL REFERENCES operational.times_atletica(id),
    nome_exibicao           VARCHAR(150),
    grupo                   VARCHAR(50),
    seed                    INTEGER,
    status                  VARCHAR(30) NOT NULL DEFAULT 'CONFIRMADA',
    criado_em               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- CAMPEONATO_ATLETAS
-- Roster final do atleta no campeonato
-- Regra critica: um atleta NAO pode jogar por mais de uma atletica no mesmo campeonato
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.campeonato_atletas (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    campeonato_id       UUID        NOT NULL REFERENCES operational.campeonatos(id),
    atletica_id         UUID        NOT NULL REFERENCES operational.atleticas(id),
    campeonato_time_id  UUID        NOT NULL REFERENCES operational.campeonato_times(id),
    atleta_id           UUID        NOT NULL REFERENCES operational.atletas(id),
    status              VARCHAR(30) NOT NULL DEFAULT 'ATIVO',
    numero_camisa       INTEGER,
    is_capitao          BOOLEAN     NOT NULL DEFAULT FALSE,
    is_goleiro          BOOLEAN     NOT NULL DEFAULT FALSE,
    inscrito_em         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Unique parcial: atleta nao pode jogar em mais de uma atletica por campeonato (status ativos)
CREATE UNIQUE INDEX IF NOT EXISTS uq_campeonato_atleta_unico
    ON operational.campeonato_atletas (campeonato_id, atleta_id)
    WHERE status = 'ATIVO';

-- -----------------------------------------------------------------------------
-- EQUIPES_STAFF
-- Staff de apoio do time no campeonato
-- user_id pode ser nulo para staff externo sem conta
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.equipes_staff (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    campeonato_time_id  UUID        NOT NULL REFERENCES operational.campeonato_times(id) ON DELETE CASCADE,
    user_id             UUID        REFERENCES operational.profiles(id),
    nome                VARCHAR(200) NOT NULL,
    cargo               VARCHAR(100) NOT NULL,
    criado_em           TIMESTAMPTZ  NOT NULL DEFAULT now()
);
