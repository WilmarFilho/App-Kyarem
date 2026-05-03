-- =============================================================================
-- V24 - Storage: bucket sumulas e políticas RLS
-- =============================================================================
-- Cria o bucket de Súmulas Oficiais (PDF) no Supabase Storage e define
-- as políticas de Row Level Security (RLS) necessárias.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Bucket: sumulas
-- -----------------------------------------------------------------------------
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'sumulas') THEN
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
        VALUES (
            'sumulas',
            'sumulas',
            true,                                        -- bucket público (URLs acessíveis sem autenticação)
            10485760,                                    -- 10 MB limite por arquivo
            ARRAY['application/pdf']
        );
    ELSE
        UPDATE storage.buckets
        SET public             = true,
            file_size_limit    = 10485760,
            allowed_mime_types = ARRAY['application/pdf']
        WHERE id = 'sumulas';
    END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 2. Políticas RLS — storage.objects
-- -----------------------------------------------------------------------------

-- 2a. Leitura pública: qualquer pessoa (anon ou authenticated) pode visualizar as súmulas
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
          AND tablename  = 'objects'
          AND policyname = 'sumulas_public_read'
    ) THEN
        CREATE POLICY "sumulas_public_read" ON storage.objects
            FOR SELECT TO public
            USING (bucket_id = 'sumulas');
    END IF;
END $$;
