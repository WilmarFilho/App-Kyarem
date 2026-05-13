-- =============================================================================
-- V12 - Schema public: comparacoes, rede social e timeline
-- Referencia: nova_arquitetura.txt secoes 6.5, 6.6 e 6.7
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SNAPSHOT_COMPARACAO_ATLETAS
-- Pre-calculado pelo metrics-worker sob demanda
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.snapshot_comparacao_atletas (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    atleta_a_id             UUID        NOT NULL,
    atleta_b_id             UUID        NOT NULL,
    campeonato_modalidade_id UUID,
    stats_a_json            JSONB,
    stats_b_json            JSONB,
    gerado_em               TIMESTAMPTZ NOT NULL DEFAULT now(),
    valido_ate              TIMESTAMPTZ
);

-- -----------------------------------------------------------------------------
-- SNAPSHOT_COMPARACAO_TIMES
-- Pre-calculado pelo metrics-worker sob demanda
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.snapshot_comparacao_times (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    time_a_id               UUID        NOT NULL,
    time_b_id               UUID        NOT NULL,
    campeonato_modalidade_id UUID        NOT NULL,
    stats_a_json            JSONB,
    stats_b_json            JSONB,
    confrontos_diretos_json JSONB,
    gerado_em               TIMESTAMPTZ NOT NULL DEFAULT now(),
    valido_ate              TIMESTAMPTZ
);

-- -----------------------------------------------------------------------------
-- FEED_POSTS
-- Read model desnormalizado do feed social
-- Populado pelo projection-worker a partir de operational.posts_sociais
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.feed_posts (
    post_id                 UUID        PRIMARY KEY,
    autor_user_id           UUID,
    autor_nome_exibicao     VARCHAR(200),
    autor_foto_url          VARCHAR(500),
    autor_atletica_nome     VARCHAR(200),
    tipo_post               VARCHAR(30),
    conteudo_texto          TEXT,
    midia_urls_json         JSONB,
    referencia_tipo         VARCHAR(30),
    referencia_id           UUID,
    referencia_preview_json JSONB,
    curtidas_count          INTEGER     NOT NULL DEFAULT 0,
    comentarios_count       INTEGER     NOT NULL DEFAULT 0,
    visibilidade            VARCHAR(30),
    criado_em               TIMESTAMPTZ,
    atualizado_em           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_feed_posts_autor
    ON public.feed_posts (autor_user_id, criado_em DESC);

-- -----------------------------------------------------------------------------
-- COMENTARIOS_PUBLICOS
-- Read model de comentarios, populado pelo projection-worker
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.comentarios_publicos (
    comentario_id           UUID        PRIMARY KEY,
    post_id                 UUID,
    autor_user_id           UUID,
    autor_nome_exibicao     VARCHAR(200),
    autor_foto_url          VARCHAR(500),
    conteudo                TEXT,
    parent_comentario_id    UUID,
    curtidas_count          INTEGER     NOT NULL DEFAULT 0,
    criado_em               TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_comentarios_publicos_post
    ON public.comentarios_publicos (post_id, criado_em);

-- -----------------------------------------------------------------------------
-- CONTADORES_SOCIAIS
-- Contadores agregados por entidade para evitar COUNT ao vivo
-- entidade_tipo: USUARIO | ATLETICA | CAMPEONATO
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.contadores_sociais (
    entidade_tipo   VARCHAR(20) NOT NULL CHECK (entidade_tipo IN ('USUARIO','ATLETICA','CAMPEONATO')),
    entidade_id     UUID        NOT NULL,
    seguidores_count INTEGER    NOT NULL DEFAULT 0,
    seguindo_count  INTEGER     NOT NULL DEFAULT 0,
    posts_count     INTEGER     NOT NULL DEFAULT 0,
    curtidas_totais INTEGER     NOT NULL DEFAULT 0,
    atualizado_em   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (entidade_tipo, entidade_id)
);

-- -----------------------------------------------------------------------------
-- TIMELINE_CAMPEONATO
-- Feed cronologico de eventos relevantes do campeonato
-- tipo_evento: PONTUACAO | CARTAO | RESULTADO | INICIO_PARTIDA | FIM_PARTIDA | DESTAQUE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.timeline_campeonato (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    campeonato_id           UUID        NOT NULL,
    tipo_evento             VARCHAR(30) NOT NULL CHECK (tipo_evento IN ('PONTUACAO','CARTAO','RESULTADO','INICIO_PARTIDA','FIM_PARTIDA','DESTAQUE')),
    referencia_partida_id   UUID,
    referencia_time_id      UUID,
    referencia_atleta_id    UUID,
    titulo                  VARCHAR(300),
    descricao_curta         TEXT,
    payload_json            JSONB,
    ocorrido_em             TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_timeline_campeonato_id
    ON public.timeline_campeonato (campeonato_id, ocorrido_em DESC);
