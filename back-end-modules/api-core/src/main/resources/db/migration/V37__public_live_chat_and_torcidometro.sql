-- =============================================================================
-- V37 - Chat ao vivo e torcidometro publico com realtime
-- =============================================================================

CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS public.partida_chat_participantes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partida_id      UUID        NOT NULL,
    device_id       VARCHAR(120) NOT NULL,
    display_name    VARCHAR(40) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (partida_id, device_id)
);

CREATE TABLE IF NOT EXISTS public.partida_chat_mensagens (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partida_id      UUID         NOT NULL,
    device_id       VARCHAR(120) NOT NULL,
    display_name    VARCHAR(40)  NOT NULL,
    message         VARCHAR(400) NOT NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.partida_torcida_votos (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partida_id      UUID         NOT NULL,
    atletica_id     UUID         NOT NULL,
    device_id       VARCHAR(120) NOT NULL,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),
    UNIQUE (partida_id, device_id)
);

CREATE TABLE IF NOT EXISTS public.atletica_torcida_votos (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campeonato_atletica_id UUID         NOT NULL,
    atletica_id            UUID         NOT NULL,
    device_id              VARCHAR(120) NOT NULL,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ  NOT NULL DEFAULT now(),
    UNIQUE (campeonato_atletica_id, device_id)
);

CREATE TABLE IF NOT EXISTS public.public_interaction_rate_logs (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    interaction_type VARCHAR(40)  NOT NULL,
    scope_id         VARCHAR(120) NOT NULL,
    device_id        VARCHAR(120),
    ip_address       VARCHAR(120),
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_partida_chat_participantes_partida
    ON public.partida_chat_participantes (partida_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_partida_chat_mensagens_partida
    ON public.partida_chat_mensagens (partida_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_partida_torcida_votos_partida
    ON public.partida_torcida_votos (partida_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_atletica_torcida_votos_campeonato_atletica
    ON public.atletica_torcida_votos (campeonato_atletica_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_public_interaction_rate_logs_lookup
    ON public.public_interaction_rate_logs (interaction_type, scope_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_public_interaction_rate_logs_ip
    ON public.public_interaction_rate_logs (ip_address, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_public_interaction_rate_logs_device
    ON public.public_interaction_rate_logs (device_id, created_at DESC);

DROP TRIGGER IF EXISTS trg_partida_chat_participantes_updated_at ON public.partida_chat_participantes;
CREATE TRIGGER trg_partida_chat_participantes_updated_at
BEFORE UPDATE ON public.partida_chat_participantes
FOR EACH ROW
EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS trg_partida_torcida_votos_updated_at ON public.partida_torcida_votos;
CREATE TRIGGER trg_partida_torcida_votos_updated_at
BEFORE UPDATE ON public.partida_torcida_votos
FOR EACH ROW
EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS trg_atletica_torcida_votos_updated_at ON public.atletica_torcida_votos;
CREATE TRIGGER trg_atletica_torcida_votos_updated_at
BEFORE UPDATE ON public.atletica_torcida_votos
FOR EACH ROW
EXECUTE FUNCTION public.touch_updated_at();

ALTER TABLE public.partida_chat_participantes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partida_chat_mensagens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partida_torcida_votos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.atletica_torcida_votos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.public_interaction_rate_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permitir leitura anon e auth em partida_chat_mensagens"
    ON public.partida_chat_mensagens
    FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura anon e auth em partida_torcida_votos"
    ON public.partida_torcida_votos
    FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura anon e auth em atletica_torcida_votos"
    ON public.atletica_torcida_votos
    FOR SELECT
    USING (true);

GRANT SELECT ON public.partida_chat_mensagens TO anon, authenticated;
GRANT SELECT ON public.partida_torcida_votos TO anon, authenticated;
GRANT SELECT ON public.atletica_torcida_votos TO anon, authenticated;

ALTER PUBLICATION supabase_realtime ADD TABLE public.partida_chat_mensagens;
ALTER PUBLICATION supabase_realtime ADD TABLE public.partida_torcida_votos;
ALTER PUBLICATION supabase_realtime ADD TABLE public.atletica_torcida_votos;
