-- Align schema with existing Supabase database definition
-- tipos_eventos in Supabase does NOT have criado_em and does NOT enforce UNIQUE(esporte_id, nome) in this project DB dump.

ALTER TABLE public.tipos_eventos
    DROP COLUMN IF EXISTS criado_em;

-- Drop auto-generated unique constraint name (created when UNIQUE(esporte_id, nome) exists).
ALTER TABLE public.tipos_eventos
    DROP CONSTRAINT IF EXISTS tipos_eventos_esporte_id_nome_key;

-- If a named constraint was created by older scripts, drop it too.
ALTER TABLE public.tipos_eventos
    DROP CONSTRAINT IF EXISTS uk_tipos_eventos_esporte_nome;
