-- =============================================================================
-- V17 - Storage: bucket campeonatos e políticas RLS
-- =============================================================================
-- Cria o bucket de escudos de campeonatos no Supabase Storage e define
-- as políticas de Row Level Security (RLS) necessárias.
-- Diferente de avatares de usuário (que usam a UUID do usuário como pasta),
-- escudos de campeonatos podem ser gerenciados livremente por usuários autenticados
-- (pois o backend, ao usar Service Role Key, burla RLS, e as leituras públicas
-- precisam ser permitidas para todos).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Bucket: campeonatos
-- -----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'campeonatos',
    'campeonatos',
    true,                                        -- bucket público (URLs acessíveis sem autenticação)
    2097152,                                     -- 2 MB limite por arquivo
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE
    SET public             = EXCLUDED.public,
        file_size_limit    = EXCLUDED.file_size_limit,
        allowed_mime_types = EXCLUDED.allowed_mime_types;

-- -----------------------------------------------------------------------------
-- 2. Políticas RLS — storage.objects
-- -----------------------------------------------------------------------------

-- 2a. Leitura pública: qualquer pessoa (anon ou authenticated) pode visualizar os escudos
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename  = 'objects'
          AND policyname = 'campeonatos_public_read'
    ) THEN
        CREATE POLICY "campeonatos_public_read" ON storage.objects
            FOR SELECT TO public
            USING (bucket_id = 'campeonatos');
    END IF;
END $$;
