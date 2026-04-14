ALTER TABLE public.partidas
DROP CONSTRAINT IF EXISTS check_status_antes_pausa_partida;

ALTER TABLE public.partidas
ADD CONSTRAINT check_status_antes_pausa_partida
CHECK (status_antes_pausa IN (
    'agendada',
    '1° tempo',
    'acréscimo',
    'intervalo',
    'pausada',
    '2° tempo',
    'prorrogação',
    'pênaltis',
    'finalizada',
    'fechada'
));

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
    'pênaltis',
    'fechada',
    'finalizada'
));
