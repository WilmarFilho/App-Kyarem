-- =============================================================================
-- V8 - Partidas, arbitragem e eventos da partida
-- Referencia: nova_arquitetura.txt secoes 5.10 e 5.11
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PARTIDAS
-- Agregado principal de operacao critica da arbitragem
--
-- Status macro:
--   AGENDADA | EM_ANDAMENTO | INTERVALO | PAUSADA | FECHADA | FINALIZADA | CANCELADA | WO
--
-- periodo_atual (string livre por esporte):
--   futsal/futebol: 1_TEMPO, 2_TEMPO, PRORROGACAO, PENALTIS
--   basquete: Q1, Q2, Q3, Q4, OT
--   volei: SET1, SET2, SET3, SET4, TIE_BREAK
--
-- versao_estado: Optimistic Locking + sincronizacao realtime SSE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.partidas (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    campeonato_id           UUID        NOT NULL REFERENCES operational.campeonatos(id),
    campeonato_modalidade_id UUID       NOT NULL REFERENCES operational.campeonato_modalidades(id),
    campeonato_time_a_id    UUID        REFERENCES operational.campeonato_times(id),
    campeonato_time_b_id    UUID        REFERENCES operational.campeonato_times(id),
    status                  VARCHAR(30) NOT NULL DEFAULT 'AGENDADA',
    periodo_atual           VARCHAR(30),
    status_antes_pausa      VARCHAR(30),
    categoria               VARCHAR(50),
    fase                    VARCHAR(50),
    rodada                  VARCHAR(50),
    agendado_para           TIMESTAMPTZ,
    iniciada_em             TIMESTAMPTZ,
    encerrada_em            TIMESTAMPTZ,
    local                   VARCHAR(300),
    placar_a                INTEGER     NOT NULL DEFAULT 0,
    placar_b                INTEGER     NOT NULL DEFAULT 0,
    snapshot_sumula         JSONB,
    sumula_pdf_url          VARCHAR(500),
    hash_integridade        VARCHAR(255),
    versao_estado           BIGINT      NOT NULL DEFAULT 0,
    criado_por              UUID,
    criado_em               TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- PARTIDA_ARBITROS
-- Arbitros vinculados e autorizados a editar a sumula
-- is_criador: quem criou a partida (unico dono)
-- Apenas arbitros listados aqui tem acesso de escrita
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.partida_arbitros (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    partida_id      UUID        NOT NULL REFERENCES operational.partidas(id) ON DELETE CASCADE,
    arbitro_user_id UUID        NOT NULL REFERENCES operational.profiles(id),
    funcao          VARCHAR(30) NOT NULL CHECK (funcao IN ('PRINCIPAL','AUXILIAR','MESARIO')),
    is_criador      BOOLEAN     NOT NULL DEFAULT FALSE,
    adicionado_por  UUID,
    criado_em       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (partida_id, arbitro_user_id)
);

-- -----------------------------------------------------------------------------
-- EVENTOS_PARTIDA
-- Historico auditavel de todas as acoes registradas na sumula
-- local_evento_id: idempotencia (evita duplicatas de rede)
-- ordem_evento: ordenacao estavel
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.eventos_partida (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    partida_id          UUID        NOT NULL REFERENCES operational.partidas(id) ON DELETE CASCADE,
    tipo_evento_id      UUID        NOT NULL REFERENCES operational.tipos_eventos(id),
    equipe_id           UUID        REFERENCES operational.campeonato_times(id),
    atleta_id           UUID        REFERENCES operational.atletas(id),
    atleta_sai_id       UUID        REFERENCES operational.atletas(id),
    arbitro_user_id     UUID        NOT NULL REFERENCES operational.profiles(id),
    periodo             VARCHAR(30),
    minuto              INTEGER,
    segundo             INTEGER,
    tempo_cronometro    VARCHAR(20),
    descricao_detalhada TEXT,
    payload_json        JSONB,
    is_substitution     BOOLEAN     NOT NULL DEFAULT FALSE,
    local_evento_id     VARCHAR(100) UNIQUE,
    ordem_evento        BIGINT,
    criado_em           TIMESTAMPTZ NOT NULL DEFAULT now()
);
