-- Add foto_url to atletas
ALTER TABLE public.atletas 
ADD COLUMN IF NOT EXISTS foto_url TEXT NULL;

-- Add status_antes_pausa to partidas
ALTER TABLE public.partidas 
ADD COLUMN IF NOT EXISTS status_antes_pausa TEXT NULL;

-- Add constraint for status_antes_pausa
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
    'finalizada',
    'fechada'
));

-- Update existing check_status_partida to include 'acréscimo' and 'pausada' and 'fechada'
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
            'fechada',
            'prorrogação', 
            'finalizada'
        ));
