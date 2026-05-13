-- =============================================================================
-- V10 - Schema public: vitrine de campeonatos e partidas
-- Referencia: nova_arquitetura.txt secoes 6.1 e 6.2
-- Populado pelo projection-worker, consumido via Supabase SDK com RLS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CAMPEONATOS_VITRINE
-- Vitrine publica dos campeonatos ativos
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.campeonatos_vitrine (
    campeonato_id       UUID        PRIMARY KEY,
    nome                VARCHAR(200),
    slug                VARCHAR(160),
    escudo_url          VARCHAR(500),
    data_inicio         DATE,
    data_fim            DATE,
    status              VARCHAR(30),
    modalidades_ativas  JSONB,
    atualizado_em       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- MODALIDADES_VITRINE
-- Modalidades ativas dentro de cada campeonato
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.modalidades_vitrine (
    campeonato_modalidade_id    UUID        PRIMARY KEY,
    campeonato_id               UUID,
    esporte_nome                VARCHAR(100),
    modalidade_nome             VARCHAR(150),
    nome_exibicao               VARCHAR(150),
    categoria                   VARCHAR(50),
    genero                      VARCHAR(30),
    status                      VARCHAR(30),
    atualizado_em               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- PARTIDAS_AO_VIVO
-- Read model de partidas em andamento para exibicao em tempo real
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.partidas_ao_vivo (
    partida_id              UUID        PRIMARY KEY,
    campeonato_id           UUID,
    campeonato_modalidade_id UUID,
    time_a_nome             VARCHAR(200),
    time_b_nome             VARCHAR(200),
    time_a_escudo_url       VARCHAR(500),
    time_b_escudo_url       VARCHAR(500),
    time_a_atletica_id      UUID,
    time_b_atletica_id      UUID,
    time_a_cor_principal    VARCHAR(50),
    time_b_cor_principal    VARCHAR(50),
    placar_a                INTEGER     NOT NULL DEFAULT 0,
    placar_b                INTEGER     NOT NULL DEFAULT 0,
    status                  VARCHAR(30),
    periodo_atual           VARCHAR(30),
    cronometro              VARCHAR(20),
    local                   VARCHAR(300),
    agendado_para           TIMESTAMPTZ,
    versao_estado           BIGINT      NOT NULL DEFAULT 0,
    atualizado_em           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- PARTIDAS_HISTORICO
-- Read model completo de partidas encerradas ou finalizadas
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.partidas_historico (
    partida_id              UUID        PRIMARY KEY,
    campeonato_id           UUID,
    campeonato_slug         VARCHAR(160),
    campeonato_nome         VARCHAR(200),
    campeonato_modalidade_id UUID,
    esporte_nome            VARCHAR(100),
    modalidade_nome         VARCHAR(150),
    fase                    VARCHAR(50),
    rodada                  VARCHAR(50),
    categoria               VARCHAR(50),
    genero                  VARCHAR(30),
    time_a_id               UUID,
    time_a_nome             VARCHAR(200),
    time_a_sigla            VARCHAR(20),
    time_a_escudo_url       VARCHAR(500),
    time_a_atletica_id      UUID,
    time_a_atletica_nome    VARCHAR(200),
    time_a_cor_principal    VARCHAR(50),
    time_b_id               UUID,
    time_b_nome             VARCHAR(200),
    time_b_sigla            VARCHAR(20),
    time_b_escudo_url       VARCHAR(500),
    time_b_atletica_id      UUID,
    time_b_atletica_nome    VARCHAR(200),
    time_b_cor_principal    VARCHAR(50),
    placar_a                INTEGER,
    placar_b                INTEGER,
    resultado               VARCHAR(20) CHECK (resultado IN ('VITORIA_A','EMPATE','VITORIA_B')),
    houve_prorrogacao       BOOLEAN     NOT NULL DEFAULT FALSE,
    houve_penaltis          BOOLEAN     NOT NULL DEFAULT FALSE,
    placar_penaltis_a       INTEGER,
    placar_penaltis_b       INTEGER,
    local                   VARCHAR(300),
    agendado_para           TIMESTAMPTZ,
    iniciada_em             TIMESTAMPTZ,
    encerrada_em            TIMESTAMPTZ,
    duracao_minutos         INTEGER,
    sumula_pdf_url          VARCHAR(500),
    atualizado_em           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- EVENTOS_PARTIDA_PUBLICOS
-- Linha do tempo de eventos de qualquer partida (ao vivo e historico)
-- Generalizado para qualquer modalidade
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.eventos_partida_publicos (
    evento_id               UUID        PRIMARY KEY,
    partida_id              UUID,
    tipo_evento_codigo      VARCHAR(50),
    tipo_evento_nome        VARCHAR(150),
    impacta_placar          BOOLEAN     NOT NULL DEFAULT FALSE,
    equipe_id               UUID,
    equipe_nome             VARCHAR(200),
    equipe_cor              VARCHAR(50),
    atleta_id               UUID,
    atleta_nome_exibicao    VARCHAR(200),
    atleta_foto_url         VARCHAR(500),
    atleta_sai_id           UUID,
    atleta_sai_nome         VARCHAR(200),
    periodo                 VARCHAR(30),
    minuto                  INTEGER,
    segundo                 INTEGER,
    descricao               TEXT,
    payload_json            JSONB,
    criado_em               TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_eventos_publicos_partida
    ON public.eventos_partida_publicos (partida_id, criado_em);

-- -----------------------------------------------------------------------------
-- ESTATISTICAS_PARTIDA
-- Estatisticas agregadas por partida via JSON (flexivel por modalidade)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.estatisticas_partida (
    partida_id              UUID        PRIMARY KEY,
    campeonato_modalidade_id UUID,
    time_a_id               UUID,
    time_b_id               UUID,
    stats_time_a_json       JSONB,
    stats_time_b_json       JSONB,
    top_atletas_json        JSONB,
    atualizado_em           TIMESTAMPTZ NOT NULL DEFAULT now()
);
