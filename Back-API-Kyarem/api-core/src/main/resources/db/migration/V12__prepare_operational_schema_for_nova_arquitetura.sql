-- Prepara o schema operacional para a nova arquitetura descrita em
-- nova_arquitetura.txt. Esta migration e incremental: adiciona colunas novas,
-- preserva colunas legadas e faz backfill basico quando ha renomeacoes claras.

-- -----------------------------------------------------------------------------
-- PROFILES
-- -----------------------------------------------------------------------------
ALTER TABLE operational.profiles
    ADD COLUMN IF NOT EXISTS nome_completo VARCHAR(200),
    ADD COLUMN IF NOT EXISTS email VARCHAR(255),
    ADD COLUMN IF NOT EXISTS avatar_url VARCHAR(500),
    ADD COLUMN IF NOT EXISTS status VARCHAR(30) NOT NULL DEFAULT 'ATIVO';

UPDATE operational.profiles
SET avatar_url = foto_url
WHERE avatar_url IS NULL
  AND foto_url IS NOT NULL;

-- -----------------------------------------------------------------------------
-- ATLETICAS
-- -----------------------------------------------------------------------------
ALTER TABLE operational.atleticas
    ADD COLUMN IF NOT EXISTS slug VARCHAR(160),
    ADD COLUMN IF NOT EXISTS criado_por UUID,
    ADD COLUMN IF NOT EXISTS status VARCHAR(30) NOT NULL DEFAULT 'ATIVA';

-- -----------------------------------------------------------------------------
-- ATLETAS
-- Mantemos atletica_id como coluna transitória para o código atual, mas
-- adicionamos os campos do novo desenho orientado a auth.users/profile.
-- -----------------------------------------------------------------------------
ALTER TABLE operational.atletas
    ADD COLUMN IF NOT EXISTS nome_competicao VARCHAR(200),
    ADD COLUMN IF NOT EXISTS foto_url VARCHAR(500),
    ADD COLUMN IF NOT EXISTS genero VARCHAR(30),
    ADD COLUMN IF NOT EXISTS ativo BOOLEAN NOT NULL DEFAULT TRUE;

UPDATE operational.atletas
SET nome_competicao = COALESCE(nome_competicao, nome)
WHERE nome_competicao IS NULL
  AND nome IS NOT NULL;

UPDATE operational.atletas
SET genero = genero_esportivo
WHERE genero IS NULL
  AND genero_esportivo IS NOT NULL;

-- -----------------------------------------------------------------------------
-- CAMPEONATOS
-- -----------------------------------------------------------------------------
ALTER TABLE operational.campeonatos
    ADD COLUMN IF NOT EXISTS slug VARCHAR(160),
    ADD COLUMN IF NOT EXISTS nivel VARCHAR(50),
    ADD COLUMN IF NOT EXISTS status VARCHAR(30) NOT NULL DEFAULT 'EM_PLANEJAMENTO';

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'operational'
          AND table_name = 'campeonatos'
          AND column_name = 'nivel_campeonato'
    ) THEN
        EXECUTE '
            UPDATE operational.campeonatos
            SET nivel = nivel_campeonato
            WHERE nivel IS NULL
              AND nivel_campeonato IS NOT NULL
        ';
    END IF;
END $$;

-- -----------------------------------------------------------------------------
-- CAMPEONATO_MODALIDADES
-- O código ainda usa modalidade_id; por enquanto adicionamos os campos do
-- desenho novo sem quebrar a estrutura atual.
-- -----------------------------------------------------------------------------
ALTER TABLE operational.campeonato_modalidades
    ADD COLUMN IF NOT EXISTS nome_exibicao VARCHAR(150),
    ADD COLUMN IF NOT EXISTS categoria VARCHAR(50),
    ADD COLUMN IF NOT EXISTS genero VARCHAR(30),
    ADD COLUMN IF NOT EXISTS regras_json JSONB,
    ADD COLUMN IF NOT EXISTS formato_fases_json JSONB,
    ADD COLUMN IF NOT EXISTS tempo_partida_minutos INTEGER,
    ADD COLUMN IF NOT EXISTS permite_prorrogacao BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS permite_penaltis BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS status VARCHAR(30) NOT NULL DEFAULT 'ATIVA';

-- -----------------------------------------------------------------------------
-- TIMES_ATLETICA
-- -----------------------------------------------------------------------------
ALTER TABLE operational.times_atletica
    ADD COLUMN IF NOT EXISTS categoria VARCHAR(50),
    ADD COLUMN IF NOT EXISTS genero VARCHAR(30),
    ADD COLUMN IF NOT EXISTS status VARCHAR(30) NOT NULL DEFAULT 'ATIVO',
    ADD COLUMN IF NOT EXISTS criado_por UUID;

-- -----------------------------------------------------------------------------
-- CAMPEONATO_TIMES
-- Mantemos time_id para o código atual e adicionamos colunas do desenho novo.
-- -----------------------------------------------------------------------------
ALTER TABLE operational.campeonato_times
    ADD COLUMN IF NOT EXISTS campeonato_id UUID REFERENCES operational.campeonatos(id),
    ADD COLUMN IF NOT EXISTS campeonato_atletica_id UUID,
    ADD COLUMN IF NOT EXISTS time_atletica_id UUID REFERENCES operational.times_atletica(id),
    ADD COLUMN IF NOT EXISTS nome_exibicao VARCHAR(150),
    ADD COLUMN IF NOT EXISTS grupo VARCHAR(50),
    ADD COLUMN IF NOT EXISTS seed INTEGER,
    ADD COLUMN IF NOT EXISTS status VARCHAR(30) NOT NULL DEFAULT 'CONFIRMADA',
    ADD COLUMN IF NOT EXISTS criado_em TIMESTAMP NOT NULL DEFAULT NOW();

UPDATE operational.campeonato_times ct
SET campeonato_id = cm.campeonato_id
FROM operational.campeonato_modalidades cm
WHERE ct.campeonato_id IS NULL
  AND ct.campeonato_modalidade_id = cm.id;

UPDATE operational.campeonato_times
SET time_atletica_id = time_id
WHERE time_atletica_id IS NULL
  AND time_id IS NOT NULL;

UPDATE operational.campeonato_times ct
SET nome_exibicao = ta.nome_time
FROM operational.times_atletica ta
WHERE ct.nome_exibicao IS NULL
  AND ct.time_atletica_id = ta.id;

UPDATE operational.campeonato_times
SET status = status_inscricao
WHERE status IS NULL
  AND status_inscricao IS NOT NULL;

-- -----------------------------------------------------------------------------
-- PARTIDAS
-- -----------------------------------------------------------------------------
ALTER TABLE operational.partidas
    ADD COLUMN IF NOT EXISTS campeonato_id UUID REFERENCES operational.campeonatos(id),
    ADD COLUMN IF NOT EXISTS rodada VARCHAR(50),
    ADD COLUMN IF NOT EXISTS snapshot_sumula JSONB,
    ADD COLUMN IF NOT EXISTS sumula_pdf_url VARCHAR(500),
    ADD COLUMN IF NOT EXISTS hash_integridade VARCHAR(255),
    ADD COLUMN IF NOT EXISTS versao_estado BIGINT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS criado_por UUID;

UPDATE operational.partidas p
SET campeonato_id = cm.campeonato_id
FROM operational.campeonato_modalidades cm
WHERE p.campeonato_id IS NULL
  AND p.campeonato_modalidade_id = cm.id;

-- -----------------------------------------------------------------------------
-- PARTIDA_ARBITROS
-- -----------------------------------------------------------------------------
ALTER TABLE operational.partida_arbitros
    ADD COLUMN IF NOT EXISTS arbitro_user_id UUID REFERENCES operational.profiles(id),
    ADD COLUMN IF NOT EXISTS is_criador BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS adicionado_por UUID;

UPDATE operational.partida_arbitros
SET arbitro_user_id = user_id
WHERE arbitro_user_id IS NULL
  AND user_id IS NOT NULL;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'operational'
          AND table_name = 'partida_arbitros'
          AND column_name = 'arbitro_id'
    ) THEN
        EXECUTE '
            UPDATE operational.partida_arbitros
            SET arbitro_user_id = arbitro_id
            WHERE arbitro_user_id IS NULL
              AND arbitro_id IS NOT NULL
        ';
    END IF;
END $$;

-- -----------------------------------------------------------------------------
-- EVENTOS_PARTIDA
-- -----------------------------------------------------------------------------
ALTER TABLE operational.eventos_partida
    ADD COLUMN IF NOT EXISTS equipe_id UUID REFERENCES operational.campeonato_times(id),
    ADD COLUMN IF NOT EXISTS arbitro_user_id UUID REFERENCES operational.profiles(id),
    ADD COLUMN IF NOT EXISTS minuto INTEGER,
    ADD COLUMN IF NOT EXISTS segundo INTEGER,
    ADD COLUMN IF NOT EXISTS tempo_cronometro VARCHAR(20),
    ADD COLUMN IF NOT EXISTS payload_json JSONB,
    ADD COLUMN IF NOT EXISTS ordem_evento BIGINT;

UPDATE operational.eventos_partida
SET equipe_id = time_id
WHERE equipe_id IS NULL
  AND time_id IS NOT NULL;

UPDATE operational.eventos_partida
SET arbitro_user_id = criado_por_user_id
WHERE arbitro_user_id IS NULL
  AND criado_por_user_id IS NOT NULL;

UPDATE operational.eventos_partida
SET tempo_cronometro = minuto_segundo
WHERE tempo_cronometro IS NULL
  AND minuto_segundo IS NOT NULL;

UPDATE operational.eventos_partida
SET payload_json = dados_extras
WHERE payload_json IS NULL
  AND dados_extras IS NOT NULL;
