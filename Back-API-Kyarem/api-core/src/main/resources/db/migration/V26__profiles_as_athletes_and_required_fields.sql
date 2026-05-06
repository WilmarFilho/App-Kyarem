ALTER TABLE operational.profiles
    ADD COLUMN IF NOT EXISTS data_nascimento DATE,
    ADD COLUMN IF NOT EXISTS genero VARCHAR(30);

UPDATE operational.profiles p
SET data_nascimento = COALESCE(p.data_nascimento, a.data_nascimento),
    genero = COALESCE(p.genero, a.genero),
    avatar_url = COALESCE(NULLIF(p.avatar_url, ''), a.foto_url)
FROM operational.atletas a
WHERE a.user_id = p.id;

UPDATE operational.campeonato_atletas ca
SET atleta_id = a.user_id
FROM operational.atletas a
WHERE ca.atleta_id = a.id
  AND a.user_id IS NOT NULL;

UPDATE operational.eventos_partida ep
SET atleta_id = a.user_id
FROM operational.atletas a
WHERE ep.atleta_id = a.id
  AND a.user_id IS NOT NULL;

UPDATE operational.eventos_partida ep
SET atleta_sai_id = a.user_id
FROM operational.atletas a
WHERE ep.atleta_sai_id = a.id
  AND a.user_id IS NOT NULL;

DO $$
DECLARE
    target_table text;
    constraint_name text;
BEGIN
    FOR target_table, constraint_name IN
        SELECT tc.table_name, tc.constraint_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu
          ON tc.constraint_name = ccu.constraint_name
         AND tc.constraint_schema = ccu.constraint_schema
        WHERE tc.constraint_schema = 'operational'
          AND tc.table_name IN ('campeonato_atletas', 'eventos_partida')
          AND tc.constraint_type = 'FOREIGN KEY'
          AND ccu.table_schema = 'operational'
          AND ccu.table_name = 'atletas'
    LOOP
        EXECUTE format(
            'ALTER TABLE operational.%I DROP CONSTRAINT IF EXISTS %I',
            target_table,
            constraint_name
        );
    END LOOP;
END $$;

ALTER TABLE operational.campeonato_atletas
    ADD CONSTRAINT fk_campeonato_atletas_atleta_profiles
        FOREIGN KEY (atleta_id) REFERENCES operational.profiles(id);

ALTER TABLE operational.eventos_partida
    ADD CONSTRAINT fk_eventos_partida_atleta_profiles
        FOREIGN KEY (atleta_id) REFERENCES operational.profiles(id),
    ADD CONSTRAINT fk_eventos_partida_atleta_sai_profiles
        FOREIGN KEY (atleta_sai_id) REFERENCES operational.profiles(id);

UPDATE operational.campeonatos
SET data_inicio = COALESCE(data_inicio, data_fim, CURRENT_DATE),
    data_fim = COALESCE(data_fim, data_inicio, CURRENT_DATE);

ALTER TABLE operational.campeonatos
    ALTER COLUMN data_inicio SET NOT NULL,
    ALTER COLUMN data_fim SET NOT NULL;

UPDATE operational.atleticas a
SET criado_por = COALESCE(
    a.criado_por,
    (
        SELECT am.user_id
        FROM operational.atletica_membros am
        WHERE am.atletica_id = a.id
          AND am.papel_codigo = 'PRESIDENT'
        ORDER BY am.criado_em
        LIMIT 1
    ),
    (
        SELECT am.user_id
        FROM operational.atletica_membros am
        WHERE am.atletica_id = a.id
        ORDER BY am.criado_em
        LIMIT 1
    )
);

ALTER TABLE operational.atleticas
    ALTER COLUMN criado_por SET NOT NULL;

DROP TABLE IF EXISTS operational.atletas CASCADE;
