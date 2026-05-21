-- =============================================================================
-- V40 - Permissoes de escrita do chat publico de partidas para Edge Functions
-- =============================================================================

GRANT USAGE ON SCHEMA public TO service_role;

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
