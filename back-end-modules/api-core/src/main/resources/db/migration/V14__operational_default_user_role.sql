-- =============================================================================
-- V14 - Role global padrao USER para novos auth.users e backfill
-- =============================================================================

-- Garante que todo profile existente possua a role global padrao USER.
INSERT INTO operational.usuarios_roles_globais (
    user_id,
    role_codigo
)
SELECT
    p.id,
    'USER'
FROM operational.profiles p
LEFT JOIN operational.usuarios_roles_globais urg
    ON urg.user_id = p.id
   AND urg.role_codigo = 'USER'
WHERE urg.id IS NULL;

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

    INSERT INTO operational.usuarios_roles_globais (
        user_id,
        role_codigo
    )
    VALUES (
        NEW.id,
        'USER'
    )
    ON CONFLICT (user_id, role_codigo) DO NOTHING;

    RETURN NEW;
END;
$$;
