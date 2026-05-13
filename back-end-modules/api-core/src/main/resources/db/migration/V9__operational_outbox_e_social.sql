-- =============================================================================
-- V9 - Outbox de eventos de dominio e rede social
-- Referencia: nova_arquitetura.txt secoes 5.12 e 5.13
-- =============================================================================

-- -----------------------------------------------------------------------------
-- OUTBOX_EVENTS
-- Eventos de integracao gravados junto da transacao principal (Outbox Pattern)
-- Usos: MatchScoreUpdated, MatchFinished, ScoreSheetClosed, RankingRecalculationRequested
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.outbox_events (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type  VARCHAR(100) NOT NULL,
    aggregate_id    VARCHAR(100) NOT NULL,
    event_type      VARCHAR(100) NOT NULL,
    payload_json    JSONB        NOT NULL,
    occurred_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    published_at    TIMESTAMPTZ,
    status          VARCHAR(20)  NOT NULL DEFAULT 'PENDENTE' CHECK (status IN ('PENDENTE','PUBLICADO','ERRO')),
    retry_count     INTEGER      NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_outbox_status_occurred
    ON operational.outbox_events (status, occurred_at)
    WHERE status = 'PENDENTE';

-- -----------------------------------------------------------------------------
-- POSTS_SOCIAIS
-- Publicacoes dos usuarios no feed social
-- Escrita feita diretamente via Supabase SDK (sem api-core)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.posts_sociais (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    autor_user_id       UUID        NOT NULL REFERENCES operational.profiles(id),
    tipo                VARCHAR(30) NOT NULL CHECK (tipo IN ('TEXT','FOTO','VIDEO','RESULTADO_PARTIDA','HIGHLIGHT_ATLETA')),
    conteudo_texto      TEXT,
    midia_urls_json     JSONB,
    referencia_tipo     VARCHAR(30),
    referencia_id       UUID,
    visibilidade        VARCHAR(30) NOT NULL DEFAULT 'PUBLICO' CHECK (visibilidade IN ('PUBLICO','APENAS_ATLETICA')),
    status              VARCHAR(20) NOT NULL DEFAULT 'ATIVO',
    criado_em           TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- POSTS_CURTIDAS
-- Registro de curtidas em posts
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.posts_curtidas (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id     UUID        NOT NULL REFERENCES operational.posts_sociais(id) ON DELETE CASCADE,
    user_id     UUID        NOT NULL REFERENCES operational.profiles(id),
    criado_em   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (post_id, user_id)
);

-- -----------------------------------------------------------------------------
-- POSTS_COMENTARIOS
-- Comentarios em posts, suporta threads (parent_comentario_id nullable)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.posts_comentarios (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id                 UUID        NOT NULL REFERENCES operational.posts_sociais(id) ON DELETE CASCADE,
    autor_user_id           UUID        NOT NULL REFERENCES operational.profiles(id),
    conteudo                TEXT        NOT NULL,
    parent_comentario_id    UUID        REFERENCES operational.posts_comentarios(id),
    status                  VARCHAR(20) NOT NULL DEFAULT 'ATIVO',
    criado_em               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- SEGUIDORES
-- Vinculo de seguimento entre usuarios, atleticas e campeonatos
-- Regra: exatamente um dos campos seguido_* deve ser preenchido
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.seguidores (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    seguidor_user_id        UUID        NOT NULL REFERENCES operational.profiles(id),
    seguido_user_id         UUID        REFERENCES operational.profiles(id),
    seguido_atletica_id     UUID        REFERENCES operational.atleticas(id),
    seguido_campeonato_id   UUID        REFERENCES operational.campeonatos(id),
    criado_em               TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_seguido_exclusivo CHECK (
        (CASE WHEN seguido_user_id      IS NOT NULL THEN 1 ELSE 0 END +
         CASE WHEN seguido_atletica_id  IS NOT NULL THEN 1 ELSE 0 END +
         CASE WHEN seguido_campeonato_id IS NOT NULL THEN 1 ELSE 0 END) = 1
    )
);

-- -----------------------------------------------------------------------------
-- NOTIFICACOES
-- Notificacoes internas por evento social ou esportivo
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS operational.notificacoes (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    destinatario_user_id    UUID        NOT NULL REFERENCES operational.profiles(id),
    tipo                    VARCHAR(30) NOT NULL CHECK (tipo IN ('CURTIDA','COMENTARIO','SEGUIDOR','CONVOCACAO','RESULTADO','MENCAO')),
    referencia_tipo         VARCHAR(50),
    referencia_id           UUID,
    lida                    BOOLEAN     NOT NULL DEFAULT FALSE,
    criado_em               TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notificacoes_usuario_nao_lida
    ON operational.notificacoes (destinatario_user_id, criado_em DESC)
    WHERE lida = FALSE;
