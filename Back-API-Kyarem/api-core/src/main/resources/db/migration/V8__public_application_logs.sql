-- ==============================================================================
-- 7. APPLICATION LOGS (Múltiplos Containers)
-- ==============================================================================

-- Esta tabela PERMANECE NO SCHEMA PUBLIC, pois os 5 containers acessarão.
-- Ela é centralizada e serve de monitoramento da frota.

CREATE TABLE IF NOT EXISTS public.application_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    level TEXT NOT NULL,
    category TEXT NOT NULL,
    message TEXT NOT NULL,
    source TEXT, -- 'api-core', 'metrics-worker', 'projection-worker', 'realtime-gateway', 'outbox-publisher'
    exception_class TEXT,
    stack_trace TEXT,
    details JSONB,
    http_method TEXT,
    path TEXT,
    status_code INTEGER,
    user_id UUID,
    request_id TEXT,
    ip_address TEXT,
    user_agent TEXT,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT application_logs_level_check CHECK (level IN ('INFO', 'WARN', 'ERROR')),
    CONSTRAINT application_logs_status_code_check CHECK (
        status_code IS NULL OR (status_code >= 100 AND status_code <= 599)
    )
);

CREATE INDEX IF NOT EXISTS idx_application_logs_criado_em
    ON public.application_logs (criado_em DESC);

CREATE INDEX IF NOT EXISTS idx_application_logs_level_criado_em
    ON public.application_logs (level, criado_em DESC);

CREATE INDEX IF NOT EXISTS idx_application_logs_category_criado_em
    ON public.application_logs (category, criado_em DESC);

CREATE INDEX IF NOT EXISTS idx_application_logs_user_id_criado_em
    ON public.application_logs (user_id, criado_em DESC);

-- E vamos aproveitar o V8 para criar uma função utilitária para os RLS
-- do Supabase lerem informações dos profiles nas tabelas de leitura publica.
CREATE OR REPLACE FUNCTION public.get_current_user_profile_id()
RETURNS UUID AS $$
BEGIN
  RETURN auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
