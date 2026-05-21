-- =============================================================================
-- V39 - Corrige permissoes de escrita das interacoes publicas para Edge Functions
-- =============================================================================

GRANT USAGE ON SCHEMA public TO service_role;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = 'atletica_torcida_votos'
    ) THEN
        ALTER TABLE public.atletica_torcida_votos ENABLE ROW LEVEL SECURITY;

        GRANT SELECT ON public.atletica_torcida_votos TO anon, authenticated;
        GRANT SELECT, INSERT, UPDATE, DELETE ON public.atletica_torcida_votos TO service_role;

        DROP POLICY IF EXISTS "Service role pode escrever em atletica_torcida_votos"
            ON public.atletica_torcida_votos;

        CREATE POLICY "Service role pode escrever em atletica_torcida_votos"
            ON public.atletica_torcida_votos
            FOR ALL
            TO service_role
            USING (true)
            WITH CHECK (true);
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = 'partida_chat_participantes'
    ) THEN
        ALTER TABLE public.partida_chat_participantes ENABLE ROW LEVEL SECURITY;

        GRANT SELECT, INSERT, UPDATE ON public.partida_chat_participantes TO service_role;

        DROP POLICY IF EXISTS "Service role pode escrever em partida_chat_participantes"
            ON public.partida_chat_participantes;

        CREATE POLICY "Service role pode escrever em partida_chat_participantes"
            ON public.partida_chat_participantes
            FOR ALL
            TO service_role
            USING (true)
            WITH CHECK (true);
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = 'partida_chat_mensagens'
    ) THEN
        ALTER TABLE public.partida_chat_mensagens ENABLE ROW LEVEL SECURITY;

        GRANT SELECT ON public.partida_chat_mensagens TO anon, authenticated;
        GRANT SELECT, INSERT ON public.partida_chat_mensagens TO service_role;

        DROP POLICY IF EXISTS "Service role pode escrever em partida_chat_mensagens"
            ON public.partida_chat_mensagens;

        CREATE POLICY "Service role pode escrever em partida_chat_mensagens"
            ON public.partida_chat_mensagens
            FOR ALL
            TO service_role
            USING (true)
            WITH CHECK (true);
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = 'partida_torcida_votos'
    ) THEN
        ALTER TABLE public.partida_torcida_votos ENABLE ROW LEVEL SECURITY;

        GRANT SELECT ON public.partida_torcida_votos TO anon, authenticated;
        GRANT SELECT, INSERT, UPDATE, DELETE ON public.partida_torcida_votos TO service_role;

        DROP POLICY IF EXISTS "Service role pode escrever em partida_torcida_votos"
            ON public.partida_torcida_votos;

        CREATE POLICY "Service role pode escrever em partida_torcida_votos"
            ON public.partida_torcida_votos
            FOR ALL
            TO service_role
            USING (true)
            WITH CHECK (true);
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = 'public_interaction_rate_logs'
    ) THEN
        ALTER TABLE public.public_interaction_rate_logs ENABLE ROW LEVEL SECURITY;

        GRANT SELECT, INSERT ON public.public_interaction_rate_logs TO service_role;

        DROP POLICY IF EXISTS "Service role pode escrever em public_interaction_rate_logs"
            ON public.public_interaction_rate_logs;

        CREATE POLICY "Service role pode escrever em public_interaction_rate_logs"
            ON public.public_interaction_rate_logs
            FOR ALL
            TO service_role
            USING (true)
            WITH CHECK (true);
    END IF;
END $$;
