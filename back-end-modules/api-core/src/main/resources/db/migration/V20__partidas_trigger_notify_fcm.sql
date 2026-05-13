-- =============================================================================
-- V20 - Trigger em partidas que dispara Edge Function notify-partida via pg_net
-- =============================================================================

CREATE OR REPLACE FUNCTION operational.fn_notify_partida_changed()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  payload JSONB;
  edge_url TEXT;
BEGIN
  edge_url := 'https://hlgnackuzfhkhloemtey.supabase.co/functions/v1/notify-partida';

  IF TG_OP = 'INSERT' THEN
    payload := jsonb_build_object(
      'type', 'INSERT',
      'table', TG_TABLE_NAME,
      'record', row_to_json(NEW)::jsonb,
      'old_record', NULL
    );
  ELSE
    IF (NEW.status IS DISTINCT FROM OLD.status) OR (NEW.periodo_atual IS DISTINCT FROM OLD.periodo_atual) THEN
      payload := jsonb_build_object(
        'type', 'UPDATE',
        'table', TG_TABLE_NAME,
        'record', row_to_json(NEW)::jsonb,
        'old_record', row_to_json(OLD)::jsonb
      );
    ELSE
      RETURN NEW;
    END IF;
  END IF;

  PERFORM extensions.http_post(
    url := edge_url,
    body := payload::text,
    headers := jsonb_build_object('Content-Type', 'application/json')
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_partidas_notify ON operational.partidas;
CREATE TRIGGER trg_partidas_notify
  AFTER INSERT OR UPDATE OF status, periodo_atual
  ON operational.partidas
  FOR EACH ROW
  EXECUTE FUNCTION operational.fn_notify_partida_changed();

-- Trigger para notificar arbitro quando vinculado a uma partida
CREATE OR REPLACE FUNCTION operational.fn_notify_arbitro_vinculado()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  payload JSONB;
  edge_url TEXT;
  partida_record RECORD;
BEGIN
  edge_url := 'https://hlgnackuzfhkhloemtey.supabase.co/functions/v1/notify-partida';

  SELECT * INTO partida_record FROM operational.partidas WHERE id = NEW.partida_id;

  IF NOT FOUND THEN
    RETURN NEW;
  END IF;

  payload := jsonb_build_object(
    'type', 'INSERT',
    'table', 'partida_arbitros',
    'record', row_to_json(partida_record)::jsonb,
    'old_record', NULL,
    'arbitro_user_id', NEW.arbitro_user_id
  );

  PERFORM extensions.http_post(
    url := edge_url,
    body := payload::text,
    headers := jsonb_build_object('Content-Type', 'application/json')
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_partida_arbitros_notify ON operational.partida_arbitros;
CREATE TRIGGER trg_partida_arbitros_notify
  AFTER INSERT
  ON operational.partida_arbitros
  FOR EACH ROW
  EXECUTE FUNCTION operational.fn_notify_arbitro_vinculado();
