-- =============================================================================
-- V19 - Preferencias de notificacao FCM e token no perfil do usuario
-- =============================================================================

ALTER TABLE operational.profiles
  ADD COLUMN IF NOT EXISTS notif_todas_partidas   BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS notif_minhas_partidas  BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS fcm_token              TEXT;

CREATE EXTENSION IF NOT EXISTS pg_net SCHEMA extensions;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'operational' AND tablename = 'partidas'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE operational.partidas;
  END IF;
END $$;
