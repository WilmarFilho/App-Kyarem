-- =============================================================================
-- V43 - User Favorites (Partidas, Campeonatos, Atleticas)
-- =============================================================================

CREATE TABLE IF NOT EXISTS operational.user_favorites (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL,
    partida_id      UUID,
    campeonato_id   UUID,
    atletica_id     UUID,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- Ensuring exactly one type of favorite is provided
    CONSTRAINT chk_favorite_item CHECK (
        (partida_id IS NOT NULL AND campeonato_id IS NULL AND atletica_id IS NULL) OR
        (partida_id IS NULL AND campeonato_id IS NOT NULL AND atletica_id IS NULL) OR
        (partida_id IS NULL AND campeonato_id IS NULL AND atletica_id IS NOT NULL)
    ),

    CONSTRAINT fk_favorite_partida FOREIGN KEY (partida_id) REFERENCES operational.partidas(id) ON DELETE CASCADE,
    CONSTRAINT fk_favorite_campeonato FOREIGN KEY (campeonato_id) REFERENCES operational.campeonatos(id) ON DELETE CASCADE,
    CONSTRAINT fk_favorite_atletica FOREIGN KEY (atletica_id) REFERENCES operational.atleticas(id) ON DELETE CASCADE
);

-- Index for quick lookup of user's favorites
CREATE INDEX IF NOT EXISTS idx_user_favorites_user ON operational.user_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_partida ON operational.user_favorites(partida_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_campeonato ON operational.user_favorites(campeonato_id);
CREATE INDEX IF NOT EXISTS idx_user_favorites_atletica ON operational.user_favorites(atletica_id);

-- Enforce uniqueness to prevent duplicate favorites
CREATE UNIQUE INDEX IF NOT EXISTS unq_user_favorite_partida_user ON operational.user_favorites(user_id, partida_id) WHERE partida_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS unq_user_favorite_camp_user ON operational.user_favorites(user_id, campeonato_id) WHERE campeonato_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS unq_user_favorite_atl_user ON operational.user_favorites(user_id, atletica_id) WHERE atletica_id IS NOT NULL;

-- Since it's operational, we might not need RLS if accessed purely via backend,
-- but if we mirror it later or access via Supabase, RLS is good practice.
ALTER TABLE operational.user_favorites ENABLE ROW LEVEL SECURITY;

-- Allow users to read, insert and delete ONLY their own favorites
CREATE POLICY "Permitir leitura apenas dos proprios favoritos"
    ON operational.user_favorites
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Permitir insert dos proprios favoritos"
    ON operational.user_favorites
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Permitir delete dos proprios favoritos"
    ON operational.user_favorites
    FOR DELETE
    USING (auth.uid() = user_id);

-- Also allow the backend service role to bypass RLS (PostgreSQL superuser/service_role bypasses anyway)
GRANT SELECT, INSERT, DELETE ON operational.user_favorites TO authenticated;

ALTER PUBLICATION supabase_realtime ADD TABLE operational.user_favorites;
