-- =============================================================================
-- V13 - Backfill e trigger para profiles a partir de auth.users
-- =============================================================================

-- Backfill dos usuarios ja existentes no auth sem profile correspondente.
INSERT INTO operational.profiles (
    id,
    nome_completo,
    nome_exibicao,
    email,
    telefone,
    avatar_url
)
SELECT
    u.id,
    COALESCE(u.raw_user_meta_data ->> 'nome_completo', u.raw_user_meta_data ->> 'full_name'),
    COALESCE(
        u.raw_user_meta_data ->> 'nome_exibicao',
        u.raw_user_meta_data ->> 'display_name',
        u.raw_user_meta_data ->> 'name'
    ),
    u.email,
    COALESCE(u.phone, u.raw_user_meta_data ->> 'telefone'),
    u.raw_user_meta_data ->> 'avatar_url'
FROM auth.users u
LEFT JOIN operational.profiles p ON p.id = u.id
WHERE p.id IS NULL;

CREATE OR REPLACE FUNCTION operational.handle_auth_user_created()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO operational.profiles (
        id,
        nome_completo,
        nome_exibicao,
        email,
        telefone,
        avatar_url
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data ->> 'nome_completo', NEW.raw_user_meta_data ->> 'full_name'),
        COALESCE(
            NEW.raw_user_meta_data ->> 'nome_exibicao',
            NEW.raw_user_meta_data ->> 'display_name',
            NEW.raw_user_meta_data ->> 'name'
        ),
        NEW.email,
        COALESCE(NEW.phone, NEW.raw_user_meta_data ->> 'telefone'),
        NEW.raw_user_meta_data ->> 'avatar_url'
    )
    ON CONFLICT (id) DO UPDATE
    SET
        nome_completo = COALESCE(EXCLUDED.nome_completo, operational.profiles.nome_completo),
        nome_exibicao = COALESCE(EXCLUDED.nome_exibicao, operational.profiles.nome_exibicao),
        email = COALESCE(EXCLUDED.email, operational.profiles.email),
        telefone = COALESCE(EXCLUDED.telefone, operational.profiles.telefone),
        avatar_url = COALESCE(EXCLUDED.avatar_url, operational.profiles.avatar_url),
        atualizado_em = now();

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auth_user_created_profile ON auth.users;

CREATE TRIGGER trg_auth_user_created_profile
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION operational.handle_auth_user_created();
