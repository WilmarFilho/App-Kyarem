-- Adiciona o novo status "fechada" para partidas.
-- A partida pode ser "finalizada" (fim do jogo) e depois "fechada" (súmula fechada/publicada).

-- Atualiza constraint do status principal
ALTER TABLE public.partidas
DROP CONSTRAINT IF EXISTS check_status_partida;

ALTER TABLE public.partidas
    ADD CONSTRAINT check_status_partida
        CHECK (status IN (
            'agendada',
            '1° tempo',
            'acréscimo',
            'intervalo',
            'pausada',
            '2° tempo',
            'prorrogação',
            'finalizada',
            'fechada'
        ));

-- Atualiza constraint do status_antes_pausa para manter as mesmas validações
ALTER TABLE public.partidas
DROP CONSTRAINT IF EXISTS check_status_antes_pausa_partida;

ALTER TABLE public.partidas
    ADD CONSTRAINT check_status_antes_pausa_partida
        CHECK (status_antes_pausa IS NULL OR status_antes_pausa IN (
            'agendada',
            '1° tempo',
            'acréscimo',
            'intervalo',
            'pausada',
            '2° tempo',
            'prorrogação',
            'finalizada',
            'fechada'
        ));

