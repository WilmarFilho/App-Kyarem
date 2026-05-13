-- =============================================================================
-- V25 - Refinos no schema operational
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Chaves estrangeiras faltantes
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_atleticas_criado_por_profiles'
    ) THEN
        ALTER TABLE operational.atleticas
            ADD CONSTRAINT fk_atleticas_criado_por_profiles
            FOREIGN KEY (criado_por)
            REFERENCES operational.profiles(id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_partida_arbitros_adicionado_por_profiles'
    ) THEN
        ALTER TABLE operational.partida_arbitros
            ADD CONSTRAINT fk_partida_arbitros_adicionado_por_profiles
            FOREIGN KEY (adicionado_por)
            REFERENCES operational.profiles(id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_times_atletica_criado_por_profiles'
    ) THEN
        ALTER TABLE operational.times_atletica
            ADD CONSTRAINT fk_times_atletica_criado_por_profiles
            FOREIGN KEY (criado_por)
            REFERENCES operational.profiles(id);
    END IF;
END $$;

-- -----------------------------------------------------------------------------
-- Remoção de colunas operacionais descontinuadas
-- -----------------------------------------------------------------------------
ALTER TABLE IF EXISTS operational.atletica_membros
    DROP COLUMN IF EXISTS iniciado_em,
    DROP COLUMN IF EXISTS encerrado_em;

ALTER TABLE IF EXISTS operational.campeonato_atleticas
    DROP COLUMN IF EXISTS status,
    DROP COLUMN IF EXISTS aprovado_por;

ALTER TABLE IF EXISTS operational.campeonato_times
    DROP COLUMN IF EXISTS nome_exibicao,
    DROP COLUMN IF EXISTS grupo,
    DROP COLUMN IF EXISTS seed;

ALTER TABLE IF EXISTS operational.campeonatos
    DROP COLUMN IF EXISTS slug;

ALTER TABLE IF EXISTS operational.equipes_staff
    DROP COLUMN IF EXISTS nome;

ALTER TABLE IF EXISTS operational.modalidades_catalogo
    DROP COLUMN IF EXISTS eventos_base_json,
    DROP COLUMN IF EXISTS tipo_partida;

ALTER TABLE IF EXISTS operational.quadro_arbitros
    DROP COLUMN IF EXISTS iniciado_em,
    DROP COLUMN IF EXISTS encerrado_em,
    DROP COLUMN IF EXISTS observacoes;

-- -----------------------------------------------------------------------------
-- Remoção de tabelas duplicadas ou fora de escopo
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS operational.notificacoes;

DROP TABLE IF EXISTS operational.time_atletica_atletas CASCADE;

DROP TABLE IF EXISTS operational.posts_curtidas CASCADE;
DROP TABLE IF EXISTS operational.posts_comentarios CASCADE;
DROP TABLE IF EXISTS operational.posts_sociais CASCADE;
DROP TABLE IF EXISTS operational.seguidores CASCADE;
