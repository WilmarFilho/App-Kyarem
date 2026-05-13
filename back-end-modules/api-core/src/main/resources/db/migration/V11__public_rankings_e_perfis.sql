-- =============================================================================
-- V11 - Schema public: rankings, classificacoes e perfis publicos
-- Referencia: nova_arquitetura.txt secoes 6.3 e 6.4
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CLASSIFICACOES
-- Pontuacao generica para suportar qualquer esporte
-- pontos_pro = gols no futsal, cestas no basquete, pontos no volei, etc.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.classificacoes (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    campeonato_modalidade_id UUID,
    atletica_id             UUID,
    time_id                 UUID,
    time_nome               VARCHAR(200),
    escudo_url              VARCHAR(500),
    cor_principal           VARCHAR(50),
    grupo                   VARCHAR(50),
    posicao                 INTEGER,
    pontos                  INTEGER     NOT NULL DEFAULT 0,
    jogos                   INTEGER     NOT NULL DEFAULT 0,
    vitorias                INTEGER     NOT NULL DEFAULT 0,
    derrotas                INTEGER     NOT NULL DEFAULT 0,
    empates                 INTEGER     NOT NULL DEFAULT 0,
    jogos_em_casa           INTEGER     NOT NULL DEFAULT 0,
    jogos_fora              INTEGER     NOT NULL DEFAULT 0,
    pontos_pro              INTEGER     NOT NULL DEFAULT 0,
    pontos_contra           INTEGER     NOT NULL DEFAULT 0,
    saldo_pontos            INTEGER     NOT NULL DEFAULT 0,
    forma_recente_json      JSONB,
    partidas_ids_json       JSONB,
    atualizado_em           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- ARTILHARIA
-- Ranking de pontuadores por modalidade (gols, cestas, pontos...)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.artilharia (
    campeonato_modalidade_id UUID,
    atleta_id               UUID,
    user_id                 UUID,
    nome_exibicao           VARCHAR(200),
    foto_url                VARCHAR(500),
    atletica_id             UUID,
    atletica_nome           VARCHAR(200),
    atletica_escudo_url     VARCHAR(500),
    pontuacoes              INTEGER     NOT NULL DEFAULT 0,
    pontuacoes_json         JSONB,
    jogos                   INTEGER     NOT NULL DEFAULT 0,
    minutos_jogados         INTEGER,
    posicao_ranking         INTEGER,
    atualizado_em           TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (campeonato_modalidade_id, atleta_id)
);

-- -----------------------------------------------------------------------------
-- RANKING_ASSISTENCIAS
-- Ranking de assistencias por modalidade
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ranking_assistencias (
    campeonato_modalidade_id UUID,
    atleta_id               UUID,
    user_id                 UUID,
    nome_exibicao           VARCHAR(200),
    foto_url                VARCHAR(500),
    atletica_id             UUID,
    atletica_nome           VARCHAR(200),
    atletica_escudo_url     VARCHAR(500),
    assistencias            INTEGER     NOT NULL DEFAULT 0,
    jogos                   INTEGER     NOT NULL DEFAULT 0,
    posicao_ranking         INTEGER,
    atualizado_em           TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (campeonato_modalidade_id, atleta_id)
);

-- -----------------------------------------------------------------------------
-- RANKING_GERAL_CAMPEONATO
-- Pontuacao consolidada de atleticas across todas as modalidades
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ranking_geral_campeonato (
    campeonato_id           UUID,
    atletica_id             UUID,
    atletica_nome           VARCHAR(200),
    atletica_sigla          VARCHAR(20),
    atletica_escudo_url     VARCHAR(500),
    atletica_cor_principal  VARCHAR(50),
    pontos_totais           INTEGER     NOT NULL DEFAULT 0,
    ouro                    INTEGER     NOT NULL DEFAULT 0,
    prata                   INTEGER     NOT NULL DEFAULT 0,
    bronze                  INTEGER     NOT NULL DEFAULT 0,
    modalidades_participadas INTEGER    NOT NULL DEFAULT 0,
    posicao                 INTEGER,
    atualizado_em           TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (campeonato_id, atletica_id)
);

-- -----------------------------------------------------------------------------
-- METRICAS_ATLETAS
-- Metricas publicas agregadas por atleta
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.metricas_atletas (
    atleta_id               UUID        PRIMARY KEY,
    user_id                 UUID,
    nome_exibicao           VARCHAR(200),
    foto_url                VARCHAR(500),
    atletica_atual_id       UUID,
    atletica_atual_nome     VARCHAR(200),
    atletica_atual_escudo_url VARCHAR(500),
    esportes_json           JSONB,
    campeonatos_participados INTEGER     NOT NULL DEFAULT 0,
    titulos                 INTEGER     NOT NULL DEFAULT 0,
    metricas_por_campeonato_json JSONB,
    ultima_partida_em       TIMESTAMPTZ,
    atualizado_em           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- PERFIS_ATLETAS
-- Perfil publico completo do atleta
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.perfis_atletas (
    atleta_id               UUID        PRIMARY KEY,
    user_id                 UUID,
    nome_exibicao           VARCHAR(200),
    foto_url                VARCHAR(500),
    genero                  VARCHAR(30),
    data_nascimento_ano     INTEGER,
    bio                     TEXT,
    atletica_atual_id       UUID,
    atletica_atual_nome     VARCHAR(200),
    atletica_atual_escudo_url VARCHAR(500),
    atletica_atual_cor      VARCHAR(50),
    historico_atleticas_json JSONB,
    esportes_praticados_json JSONB,
    campeonatos_json        JSONB,
    stats_carreira_json     JSONB,
    atualizado_em           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- PERFIS_ATLETICAS
-- Perfil publico da atletica
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.perfis_atleticas (
    atletica_id             UUID        PRIMARY KEY,
    nome                    VARCHAR(200),
    sigla                   VARCHAR(20),
    slug                    VARCHAR(160),
    cor_principal           VARCHAR(50),
    escudo_url              VARCHAR(500),
    bio                     TEXT,
    universidade            VARCHAR(200),
    cidade                  VARCHAR(100),
    site_url                VARCHAR(500),
    instagram_url           VARCHAR(500),
    campeonatos_participados INTEGER     NOT NULL DEFAULT 0,
    titulos_json            JSONB,
    modalidades_ativas_json JSONB,
    atletas_ativos          INTEGER     NOT NULL DEFAULT 0,
    ultima_atividade_em     TIMESTAMPTZ,
    atualizado_em           TIMESTAMPTZ NOT NULL DEFAULT now()
);
