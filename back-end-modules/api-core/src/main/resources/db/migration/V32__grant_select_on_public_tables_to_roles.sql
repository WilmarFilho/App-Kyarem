-- =============================================================================
-- V32 - Grant SELECT permissions to anon and authenticated roles
-- =============================================================================

GRANT SELECT ON public.campeonatos_vitrine TO anon, authenticated;
GRANT SELECT ON public.modalidades_vitrine TO anon, authenticated;
GRANT SELECT ON public.partidas_ao_vivo TO anon, authenticated;
GRANT SELECT ON public.partidas_historico TO anon, authenticated;
GRANT SELECT ON public.eventos_partida_publicos TO anon, authenticated;
GRANT SELECT ON public.perfis_atletas TO anon, authenticated;
GRANT SELECT ON public.perfis_atleticas TO anon, authenticated;
GRANT SELECT ON public.atletica_membros_publicos TO anon, authenticated;
GRANT SELECT ON public.campeonato_atleticas_publicos TO anon, authenticated;
GRANT SELECT ON public.campeonato_atletas_publicos TO anon, authenticated;
