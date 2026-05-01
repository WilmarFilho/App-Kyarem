-- =============================================================================
-- V21 - Fix Trigger em partidas que dispara Edge Function notify-partida via pg_net
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

  PERFORM net.http_post(
    url := edge_url,
    body := payload,
    headers := jsonb_build_object('Content-Type', 'application/json')
  );

  RETURN NEW;
END;
$$;

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

  PERFORM net.http_post(
    url := edge_url,
    body := payload,
    headers := jsonb_build_object('Content-Type', 'application/json')
  );

  RETURN NEW;
END;
$$;
