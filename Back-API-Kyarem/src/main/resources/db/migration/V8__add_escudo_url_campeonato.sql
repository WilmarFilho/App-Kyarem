-- Add escudo_url to campeonatos
ALTER TABLE public.campeonatos
ADD COLUMN IF NOT EXISTS escudo_url TEXT NULL;
