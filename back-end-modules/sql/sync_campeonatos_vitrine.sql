-- =============================================================================
-- Sincronização manual: operational.campeonatos → public.campeonatos_vitrine
-- Execute este script UMA VEZ para popular a vitrine com os campeonatos
-- que já existiam antes da replicação automática ser implementada.
--
-- Após isso, novos campeonatos criados/atualizados pelo back-end serão
-- replicados automaticamente via CampeonatoService.
-- =============================================================================

INSERT INTO public.campeonatos_vitrine (
    campeonato_id,
    nome,
    slug,
    escudo_url,
    data_inicio,
    data_fim,
    status,
    atualizado_em
)
SELECT
    id          AS campeonato_id,
    nome,
    NULL        AS slug,
    escudo_url,
    data_inicio,
    data_fim,
    status,
    NOW()       AS atualizado_em
FROM operational.campeonatos
ON CONFLICT (campeonato_id) DO UPDATE SET
    nome          = EXCLUDED.nome,
    slug          = EXCLUDED.slug,
    escudo_url    = EXCLUDED.escudo_url,
    data_inicio   = EXCLUDED.data_inicio,
    data_fim      = EXCLUDED.data_fim,
    status        = EXCLUDED.status,
    atualizado_em = NOW();

-- Verificação: lista o resultado após a sincronização
SELECT campeonato_id, nome, status, atualizado_em
FROM public.campeonatos_vitrine
ORDER BY atualizado_em DESC;
