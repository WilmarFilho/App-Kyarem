-- =============================================================================
-- V22 - Corrige a check constraint de outbox_events para usar valores em inglês
-- =============================================================================
-- Alinha a constraint com os valores usados pelo Java: PENDING, PUBLISHED, FAILED
-- (A V9 criou com PENDENTE, PUBLICADO, ERRO — incompatível com o api-core e outbox-publisher)

ALTER TABLE operational.outbox_events
  DROP CONSTRAINT IF EXISTS outbox_events_status_check;

ALTER TABLE operational.outbox_events
  ADD CONSTRAINT outbox_events_status_check
  CHECK (status IN ('PENDING', 'PUBLISHED', 'FAILED'));
