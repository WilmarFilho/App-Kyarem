-- =============================================================================
-- V38 - Elenco dos times permanentes da atlética
-- =============================================================================

CREATE TABLE IF NOT EXISTS operational.time_atletica_atletas (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    time_atletica_id UUID NOT NULL REFERENCES operational.times_atletica(id) ON DELETE CASCADE,
    atleta_id        UUID NOT NULL REFERENCES operational.profiles(id) ON DELETE CASCADE,
    status           VARCHAR(20) NOT NULL DEFAULT 'ATIVO' CHECK (status IN ('ATIVO', 'REMOVIDO')),
    adicionado_por   UUID REFERENCES operational.profiles(id),
    adicionado_em    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (time_atletica_id, atleta_id)
);

CREATE INDEX IF NOT EXISTS idx_time_atletica_atletas_time
    ON operational.time_atletica_atletas (time_atletica_id);

CREATE INDEX IF NOT EXISTS idx_time_atletica_atletas_atleta
    ON operational.time_atletica_atletas (atleta_id);
