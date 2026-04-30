-- =============================================================================
-- V16 - Storage: bucket avatars e políticas RLS
-- =============================================================================
-- Cria o bucket de fotos de perfil (avatares) no Supabase Storage e define
-- as políticas de Row Level Security (RLS) necessárias para:
--   - Leitura pública (qualquer pessoa pode ver avatares)
--   - Upload/Update/Delete restrito ao dono da pasta ({user_id}/avatar.ext)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Bucket: avatars
-- -----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
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
-- Convenção de path: {user_id}/avatar.{ext}
-- (storage.foldername(name))[1] extrai o primeiro segmento do path = user_id
-- -----------------------------------------------------------------------------

-- 2a. Leitura pública: qualquer pessoa (anon ou authenticated) pode visualizar avatares
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename  = 'objects'
          AND policyname = 'avatars_public_read'
    ) THEN
        CREATE POLICY "avatars_public_read" ON storage.objects
            FOR SELECT TO public
            USING (bucket_id = 'avatars');
    END IF;
END $$;

-- 2b. Insert: usuário autenticado só pode enviar na própria pasta
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename  = 'objects'
          AND policyname = 'avatars_insert_owner'
    ) THEN
        CREATE POLICY "avatars_insert_owner" ON storage.objects
            FOR INSERT TO authenticated
            WITH CHECK (
                bucket_id = 'avatars'
                AND (auth.uid())::text = (storage.foldername(name))[1]
            );
    END IF;
END $$;

-- 2c. Update: usuário autenticado só pode atualizar o próprio avatar
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename  = 'objects'
          AND policyname = 'avatars_update_owner'
    ) THEN
        CREATE POLICY "avatars_update_owner" ON storage.objects
            FOR UPDATE TO authenticated
            USING (
                bucket_id = 'avatars'
                AND (auth.uid())::text = (storage.foldername(name))[1]
            );
    END IF;
END $$;

-- 2d. Delete: usuário autenticado só pode remover o próprio avatar
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename  = 'objects'
          AND policyname = 'avatars_delete_owner'
    ) THEN
        CREATE POLICY "avatars_delete_owner" ON storage.objects
            FOR DELETE TO authenticated
            USING (
                bucket_id = 'avatars'
                AND (auth.uid())::text = (storage.foldername(name))[1]
            );
    END IF;
END $$;
