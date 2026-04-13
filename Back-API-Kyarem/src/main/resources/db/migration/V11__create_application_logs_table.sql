CREATE TABLE IF NOT EXISTS public.application_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    level TEXT NOT NULL,
    category TEXT NOT NULL,
    message TEXT NOT NULL,
    source TEXT,
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
