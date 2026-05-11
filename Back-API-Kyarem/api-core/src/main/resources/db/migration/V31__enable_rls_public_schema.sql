-- =============================================================================
-- V31 - Enable RLS and add public read policies to all public mirror tables
-- =============================================================================

-- Enable RLS for public tables
ALTER TABLE public.campeonatos_vitrine ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.modalidades_vitrine ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partidas_ao_vivo ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partidas_historico ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eventos_partida_publicos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.perfis_atletas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.perfis_atleticas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.atletica_membros_publicos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campeonato_atleticas_publicos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campeonato_atletas_publicos ENABLE ROW LEVEL SECURITY;

-- Create SELECT policies for anon and authenticated roles
CREATE POLICY "Permitir leitura anon e auth em campeonatos_vitrine"
    ON public.campeonatos_vitrine
    FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura anon e auth em modalidades_vitrine"
    ON public.modalidades_vitrine
    FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura anon e auth em partidas_ao_vivo"
    ON public.partidas_ao_vivo
    FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura anon e auth em partidas_historico"
    ON public.partidas_historico
    FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura anon e auth em eventos_partida_publicos"
    ON public.eventos_partida_publicos
    FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura anon e auth em perfis_atletas"
    ON public.perfis_atletas
    FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura anon e auth em perfis_atleticas"
    ON public.perfis_atleticas
    FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura anon e auth em atletica_membros_publicos"
    ON public.atletica_membros_publicos
    FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura anon e auth em campeonato_atleticas_publicos"
    ON public.campeonato_atleticas_publicos
    FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura anon e auth em campeonato_atletas_publicos"
    ON public.campeonato_atletas_publicos
    FOR SELECT
    USING (true);
