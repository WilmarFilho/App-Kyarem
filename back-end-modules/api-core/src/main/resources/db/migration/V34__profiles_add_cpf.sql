ALTER TABLE operational.profiles
    ADD COLUMN IF NOT EXISTS cpf VARCHAR(11);

UPDATE operational.profiles
SET cpf = NULL
WHERE cpf IS NOT NULL
  AND btrim(cpf) = '';

UPDATE operational.profiles
SET cpf = regexp_replace(cpf, '\D', '', 'g')
WHERE cpf IS NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'chk_profiles_cpf_format'
          AND connamespace = 'operational'::regnamespace
    ) THEN
        ALTER TABLE operational.profiles
            ADD CONSTRAINT chk_profiles_cpf_format
            CHECK (cpf IS NULL OR cpf ~ '^[0-9]{11}$');
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_profiles_cpf
    ON operational.profiles (cpf)
    WHERE cpf IS NOT NULL;

UPDATE operational.profiles p
SET cpf = regexp_replace(u.raw_user_meta_data ->> 'cpf', '\D', '', 'g')
FROM auth.users u
WHERE u.id = p.id
  AND p.cpf IS NULL
  AND u.raw_user_meta_data ? 'cpf';

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
        avatar_url,
        cpf
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
        NEW.raw_user_meta_data ->> 'avatar_url',
        NULLIF(regexp_replace(COALESCE(NEW.raw_user_meta_data ->> 'cpf', ''), '\D', '', 'g'), '')
    )
    ON CONFLICT (id) DO UPDATE
    SET
        nome_completo = COALESCE(EXCLUDED.nome_completo, operational.profiles.nome_completo),
        nome_exibicao = COALESCE(EXCLUDED.nome_exibicao, operational.profiles.nome_exibicao),
        email = COALESCE(EXCLUDED.email, operational.profiles.email),
        telefone = COALESCE(EXCLUDED.telefone, operational.profiles.telefone),
        avatar_url = COALESCE(EXCLUDED.avatar_url, operational.profiles.avatar_url),
        cpf = COALESCE(EXCLUDED.cpf, operational.profiles.cpf),
        atualizado_em = now();

    RETURN NEW;
END;
$$;
