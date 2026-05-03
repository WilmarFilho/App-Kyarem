-- Seed resiliente para tipos de eventos da modalidade Futsal.
-- modalidade_catalogo_id fixo: d42896ba-67a1-4b65-af62-ed72c2d3083a
--
-- Campos da tabela operational.tipos_eventos:
--   id                  uuid  PK (gen_random_uuid())
--   modalidade_catalogo_id uuid NOT NULL (FK → modalidades_catalogo)
--   codigo              varchar(50)  NOT NULL
--   nome                varchar(150) NOT NULL
--   escopo              varchar(20)  NOT NULL  CHECK IN ('PARTIDA', 'EQUIPE', 'ATLETA')
--   impacta_placar      boolean      NOT NULL  DEFAULT false
--   pontos_pro          integer      NULLABLE
--   pontos_contra       integer      NULLABLE
--   payload_schema_json jsonb        NULLABLE
--   ordem_exibicao      integer      NULLABLE
--   ativo               boolean      NOT NULL  DEFAULT true
--
-- Escopos usados:
--   PARTIDA  → evento de controle de partida (cronômetro, fluxo, pausas)
--   EQUIPE   → evento que afeta uma equipe (gol, falta, cartão, tiro…)
--   ATLETA   → evento que afeta individualmente um atleta (substituição)

BEGIN;

DO $$
DECLARE
    v_mod_id uuid := 'd42896ba-67a1-4b65-af62-ed72c2d3083a';
BEGIN
    -- Verifica se a modalidade existe antes de inserir
    IF NOT EXISTS (
        SELECT 1 FROM operational.modalidades_catalogo WHERE id = v_mod_id
    ) THEN
        RAISE WARNING 'modalidade_catalogo_id % não encontrada. Seed de tipos_eventos abortado.', v_mod_id;
        RETURN;
    END IF;

    INSERT INTO operational.tipos_eventos (
        modalidade_catalogo_id,
        codigo,
        nome,
        escopo,
        impacta_placar,
        pontos_pro,
        pontos_contra,
        payload_schema_json,
        ordem_exibicao,
        ativo
    )
    SELECT
        v_mod_id,
        seed.codigo,
        seed.nome,
        seed.escopo,
        seed.impacta_placar,
        seed.pontos_pro,
        seed.pontos_contra,
        seed.payload_schema_json::jsonb,
        seed.ordem_exibicao,
        TRUE
    FROM (
        VALUES
        -- ─── Controle de fluxo da partida ───────────────────────────────────────
        ( 1, 'INICIO_1_TEMPO',      'Início do 1° Tempo',         'PARTIDA', false, NULL, NULL, NULL),
        ( 2, 'FIM_1_TEMPO',         'Fim do 1° Tempo',            'PARTIDA', false, NULL, NULL, NULL),
        ( 3, 'INTERVALO',           '⏸️ Intervalo',               'PARTIDA', false, NULL, NULL, NULL),
        ( 4, 'INICIO_2_TEMPO',      'Início do 2° Tempo',         'PARTIDA', false, NULL, NULL, NULL),
        ( 5, 'FIM_2_TEMPO',         'Fim do 2° Tempo',            'PARTIDA', false, NULL, NULL, NULL),
        ( 6, 'FIM_PARTIDA',         'Fim da Partida',             'PARTIDA', false, NULL, NULL, NULL),

        -- ─── Pausas e controle de tempo ─────────────────────────────────────────
        ( 7, 'PARTIDA_PAUSADA',     '⏸️ Partida Pausada',         'PARTIDA', false, NULL, NULL, NULL),
        ( 8, 'PARTIDA_RETOMADA',    '▶️ Partida Retomada',        'PARTIDA', false, NULL, NULL, NULL),
        ( 9, 'PAUSA_TECNICA',       '⏸️ Pausa Técnica',           'PARTIDA', false, NULL, NULL, NULL),
        (10, 'FIM_PAUSA_TECNICA',   '▶️ Fim da Pausa Técnica',    'PARTIDA', false, NULL, NULL, NULL),

        -- ─── Acréscimos e prorrogação ────────────────────────────────────────────
        (11, 'ACRESCIMO_DADO',      '⏱️ Acréscimo Definido',      'PARTIDA', false, NULL, NULL,
             '{"required":["minutos"],"properties":{"minutos":{"type":"integer","minimum":0}}}'),
        (12, 'ACRESCIMO',           '⏱️ Acréscimo',               'PARTIDA', false, NULL, NULL, NULL),
        (13, 'PRORROGACAO_DADA',    '⏱️ Prorrogação Definida',    'PARTIDA', false, NULL, NULL,
             '{"required":["minutos"],"properties":{"minutos":{"type":"integer","minimum":0}}}'),
        (14, 'PRORROGACAO',         '⏱️ Prorrogação',             'PARTIDA', false, NULL, NULL, NULL),

        -- ─── Eventos de equipe: gols e penáltis ─────────────────────────────────
        (15, 'GOL',                 '⚽ Gol',                      'EQUIPE',  true,  1,    0,
             '{"required":["atleta_id"],"properties":{"atleta_id":{"type":"string","format":"uuid"},"assistencia_atleta_id":{"type":"string","format":"uuid"},"contra":{"type":"boolean"}}}'),
        (16, 'PENALTI',             '⚽ Pênalti',                  'EQUIPE',  false, NULL, NULL,
             '{"required":["atleta_id"],"properties":{"atleta_id":{"type":"string","format":"uuid"}}}'),
        (17, 'PENALTI_MARCADO',     'Pênalti Marcado',             'EQUIPE',  true,  1,    0,
             '{"required":["atleta_id"],"properties":{"atleta_id":{"type":"string","format":"uuid"}}}'),
        (18, 'PENALTI_PERDIDO',     'Pênalti Perdido',             'EQUIPE',  false, NULL, NULL,
             '{"required":["atleta_id"],"properties":{"atleta_id":{"type":"string","format":"uuid"}}}'),

        -- ─── Eventos de equipe: infrações e disciplinar ──────────────────────────
        (19, 'FALTA',               'Falta',                       'EQUIPE',  false, NULL, NULL,
             '{"required":["atleta_id"],"properties":{"atleta_id":{"type":"string","format":"uuid"}}}'),
        (20, 'CARTAO_AMARELO',      '🟨 Cartão Amarelo',           'ATLETA',  false, NULL, NULL,
             '{"required":["atleta_id"],"properties":{"atleta_id":{"type":"string","format":"uuid"}}}'),
        (21, 'CARTAO_VERMELHO',     '🟥 Cartão Vermelho',          'ATLETA',  false, NULL, NULL,
             '{"required":["atleta_id"],"properties":{"atleta_id":{"type":"string","format":"uuid"}}}'),

        -- ─── Eventos de atleta: substituição ────────────────────────────────────
        (22, 'SUBSTITUICAO',        '🔄 Substituição',             'ATLETA',  false, NULL, NULL,
             '{"required":["atleta_saiu_id","atleta_entrou_id"],"properties":{"atleta_saiu_id":{"type":"string","format":"uuid"},"atleta_entrou_id":{"type":"string","format":"uuid"}}}'),

        -- ─── Tiros e bolas paradas ───────────────────────────────────────────────
        (23, 'ARREMESO_DE_META',    'Arremesso de Meta',           'EQUIPE',  false, NULL, NULL, NULL),
        (24, 'TIRO_DE_CANTO',       'Tiro de Canto',               'EQUIPE',  false, NULL, NULL, NULL),
        (25, 'TIRO_DE_SAIDA',       'Tiro de Saída',               'EQUIPE',  false, NULL, NULL, NULL),
        (26, 'TIRO_LATERAL',        'Tiro Lateral',                'EQUIPE',  false, NULL, NULL, NULL),
        (27, 'TIRO_LIVRE_DIRETO',   'Tiro Livre Direto',           'EQUIPE',  false, NULL, NULL,
             '{"required":["atleta_id"],"properties":{"atleta_id":{"type":"string","format":"uuid"}}}'),
        (28, 'TIRO_LIVRE_INDIRETO', 'Tiro Livre Indireto',         'EQUIPE',  false, NULL, NULL,
             '{"required":["atleta_id"],"properties":{"atleta_id":{"type":"string","format":"uuid"}}}')

    ) AS seed(
        ordem_exibicao,
        codigo,
        nome,
        escopo,
        impacta_placar,
        pontos_pro,
        pontos_contra,
        payload_schema_json
    )
    WHERE NOT EXISTS (
        SELECT 1
        FROM operational.tipos_eventos te
        WHERE te.modalidade_catalogo_id = v_mod_id
          AND upper(te.codigo) = upper(seed.codigo)
    );

    RAISE NOTICE 'Seed tipos_eventos (Futsal) concluído. Registros inseridos para modalidade_catalogo_id = %.', v_mod_id;
END $$;

COMMIT;
