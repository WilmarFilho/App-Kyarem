-- Seed manual resiliente para esportes, modalidades de catalogo e atleticas.
-- Ele detecta colunas do schema atual antes de inserir, para funcionar tanto
-- no banco legado quanto no modelo mais novo.

BEGIN;

DO $$
DECLARE
    has_esporte_slug boolean;
    has_esporte_ativo boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'operational'
          AND table_name = 'esportes'
          AND column_name = 'slug'
    ) INTO has_esporte_slug;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'operational'
          AND table_name = 'esportes'
          AND column_name = 'ativo'
    ) INTO has_esporte_ativo;

    IF has_esporte_slug AND has_esporte_ativo THEN
        EXECUTE $dyn$
        INSERT INTO operational.esportes (nome, slug, ativo)
        VALUES
            ('Futsal', 'futsal', TRUE),
            ('Volei', 'volei', TRUE),
            ('Basquete', 'basquete', TRUE),
            ('Handebol', 'handebol', TRUE),
            ('Futebol', 'futebol', TRUE)
        ON CONFLICT (slug) DO UPDATE
        SET nome = EXCLUDED.nome,
            ativo = EXCLUDED.ativo;
        $dyn$;
    ELSE
        EXECUTE $dyn$
        INSERT INTO operational.esportes (nome)
        SELECT seed.nome
        FROM (
            VALUES
                ('Futsal'),
                ('Volei'),
                ('Basquete'),
                ('Handebol'),
                ('Futebol')
        ) AS seed(nome)
        WHERE NOT EXISTS (
            SELECT 1
            FROM operational.esportes e
            WHERE lower(e.nome) = lower(seed.nome)
        );
        $dyn$;
    END IF;
END $$;

DO $$
DECLARE
    esporte_futsal uuid;
    esporte_volei uuid;
    esporte_basquete uuid;
    esporte_handebol uuid;
    esporte_futebol uuid;
    uses_slug boolean;
    uses_motor_regras boolean;
    uses_motor_configs_default boolean;
BEGIN
    SELECT id INTO esporte_futsal FROM operational.esportes WHERE lower(nome) = 'futsal' LIMIT 1;
    SELECT id INTO esporte_volei FROM operational.esportes WHERE lower(nome) = 'volei' LIMIT 1;
    SELECT id INTO esporte_basquete FROM operational.esportes WHERE lower(nome) = 'basquete' LIMIT 1;
    SELECT id INTO esporte_handebol FROM operational.esportes WHERE lower(nome) = 'handebol' LIMIT 1;
    SELECT id INTO esporte_futebol FROM operational.esportes WHERE lower(nome) = 'futebol' LIMIT 1;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'operational'
          AND table_name = 'modalidades_catalogo'
          AND column_name = 'slug'
    ) INTO uses_slug;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'operational'
          AND table_name = 'modalidades_catalogo'
          AND column_name = 'motor_regras'
    ) INTO uses_motor_regras;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'operational'
          AND table_name = 'modalidades_catalogo'
          AND column_name = 'motor_configs_default'
    ) INTO uses_motor_configs_default;

    IF uses_slug AND uses_motor_regras AND uses_motor_configs_default THEN
        EXECUTE $dyn$
        INSERT INTO operational.modalidades_catalogo (
            esporte_id,
            nome,
            slug,
            genero,
            motor_regras,
            motor_configs_default,
            ativo
        )
        SELECT seed.esporte_id, seed.nome, seed.slug, seed.genero, seed.motor_regras, seed.configs::jsonb, TRUE
        FROM (
            VALUES
                (esporte_futsal, 'Futsal', 'futsal', 'MASCULINO', 'FUTSAL_V1', '{"tempoPartidaMinutos":20}'),
                (esporte_futsal, 'Futsal', 'futsal', 'FEMININO', 'FUTSAL_V1', '{"tempoPartidaMinutos":20}'),
                (esporte_futsal, 'Futsal', 'futsal', 'MISTO', 'FUTSAL_V1', '{"tempoPartidaMinutos":20}'),
                (esporte_volei, 'Volei Quadra', 'quadra', 'MASCULINO', 'VOLEI_V1', '{"setsParaVencer":3,"pontosPorSet":25}'),
                (esporte_volei, 'Volei Quadra', 'quadra', 'FEMININO', 'VOLEI_V1', '{"setsParaVencer":3,"pontosPorSet":25}'),
                (esporte_volei, 'Volei de Areia', 'areia', 'MISTO', 'VOLEI_V1', '{"setsParaVencer":3,"pontosPorSet":21}'),
                (esporte_basquete, 'Basquete', 'basquete', 'MASCULINO', 'BASQUETE_V1', '{"tempoPartidaMinutos":40}'),
                (esporte_basquete, 'Basquete', 'basquete', 'FEMININO', 'BASQUETE_V1', '{"tempoPartidaMinutos":40}'),
                (esporte_handebol, 'Handebol', 'handebol', 'MASCULINO', 'HANDEBOL_V1', '{"tempoPartidaMinutos":60}'),
                (esporte_handebol, 'Handebol', 'handebol', 'FEMININO', 'HANDEBOL_V1', '{"tempoPartidaMinutos":60}'),
                (esporte_futebol, 'Society', 'society', 'MASCULINO', 'SOCIETY_V1', '{"tempoPartidaMinutos":50}'),
                (esporte_futebol, 'Futebol de Campo', 'campo', 'MASCULINO', 'FUTEBOL_CAMPO_V1', '{"tempoPartidaMinutos":90}')
        ) AS seed(esporte_id, nome, slug, genero, motor_regras, configs)
        WHERE seed.esporte_id IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM operational.modalidades_catalogo mc
              WHERE mc.esporte_id = seed.esporte_id
                AND lower(mc.slug) = lower(seed.slug)
                AND upper(mc.genero) = upper(seed.genero)
          );
        $dyn$;
    ELSE
        INSERT INTO operational.modalidades_catalogo (
            esporte_id,
            nome,
            codigo,
            descricao,
            tipo_partida,
            regras_base_json,
            ativo
        )
        SELECT seed.esporte_id, seed.nome, seed.codigo, seed.genero, seed.tipo_partida, seed.configs::jsonb, TRUE
        FROM (
            VALUES
                (esporte_futsal, 'Futsal', 'futsal_masculino', 'MASCULINO', 'FUTSAL_V1', '{"tempoPartidaMinutos":20}'),
                (esporte_futsal, 'Futsal', 'futsal_feminino', 'FEMININO', 'FUTSAL_V1', '{"tempoPartidaMinutos":20}'),
                (esporte_futsal, 'Futsal', 'futsal_misto', 'MISTO', 'FUTSAL_V1', '{"tempoPartidaMinutos":20}'),
                (esporte_volei, 'Volei Quadra', 'quadra_masculino', 'MASCULINO', 'VOLEI_V1', '{"setsParaVencer":3,"pontosPorSet":25}'),
                (esporte_volei, 'Volei Quadra', 'quadra_feminino', 'FEMININO', 'VOLEI_V1', '{"setsParaVencer":3,"pontosPorSet":25}'),
                (esporte_volei, 'Volei de Areia', 'areia_misto', 'MISTO', 'VOLEI_V1', '{"setsParaVencer":3,"pontosPorSet":21}'),
                (esporte_basquete, 'Basquete', 'basquete_masculino', 'MASCULINO', 'BASQUETE_V1', '{"tempoPartidaMinutos":40}'),
                (esporte_basquete, 'Basquete', 'basquete_feminino', 'FEMININO', 'BASQUETE_V1', '{"tempoPartidaMinutos":40}'),
                (esporte_handebol, 'Handebol', 'handebol_masculino', 'MASCULINO', 'HANDEBOL_V1', '{"tempoPartidaMinutos":60}'),
                (esporte_handebol, 'Handebol', 'handebol_feminino', 'FEMININO', 'HANDEBOL_V1', '{"tempoPartidaMinutos":60}'),
                (esporte_futebol, 'Society', 'society_masculino', 'MASCULINO', 'SOCIETY_V1', '{"tempoPartidaMinutos":50}'),
                (esporte_futebol, 'Futebol de Campo', 'campo_masculino', 'MASCULINO', 'FUTEBOL_CAMPO_V1', '{"tempoPartidaMinutos":90}')
        ) AS seed(esporte_id, nome, codigo, genero, tipo_partida, configs)
        WHERE seed.esporte_id IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM operational.modalidades_catalogo mc
              WHERE mc.esporte_id = seed.esporte_id
                AND lower(mc.codigo) = lower(seed.codigo)
                AND upper(coalesce(mc.descricao, '')) = upper(seed.genero)
          );
    END IF;
END $$;

DO $$
DECLARE
    has_atletica_slug boolean;
    has_atletica_status boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'operational'
          AND table_name = 'atleticas'
          AND column_name = 'slug'
    ) INTO has_atletica_slug;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'operational'
          AND table_name = 'atleticas'
          AND column_name = 'status'
    ) INTO has_atletica_status;

    IF has_atletica_slug AND has_atletica_status THEN
        EXECUTE $dyn$
        INSERT INTO operational.atleticas (
            nome,
            sigla,
            slug,
            cor_principal,
            status
        )
        SELECT seed.nome, seed.sigla, seed.slug, seed.cor_principal, seed.status
        FROM (
            VALUES
                ('Atletica Kraken', 'AKN', 'atletica-kraken', '#F85C39', 'ATIVA'),
                ('Atletica Fenix', 'AFN', 'atletica-fenix', '#6C5CE7', 'ATIVA'),
                ('Atletica Trovao', 'ATR', 'atletica-trovao', '#0984E3', 'ATIVA'),
                ('Atletica Onix', 'AON', 'atletica-onix', '#2D3436', 'ATIVA'),
                ('Atletica Aurora', 'AAU', 'atletica-aurora', '#00B894', 'ATIVA')
        ) AS seed(nome, sigla, slug, cor_principal, status)
        WHERE NOT EXISTS (
            SELECT 1
            FROM operational.atleticas a
            WHERE lower(a.slug) = lower(seed.slug)
        );
        $dyn$;
    ELSE
        EXECUTE $dyn$
        INSERT INTO operational.atleticas (
            nome,
            sigla,
            cor_principal
        )
        SELECT seed.nome, seed.sigla, seed.cor_principal
        FROM (
            VALUES
                ('Atletica Kraken', 'AKN', '#F85C39'),
                ('Atletica Fenix', 'AFN', '#6C5CE7'),
                ('Atletica Trovao', 'ATR', '#0984E3'),
                ('Atletica Onix', 'AON', '#2D3436'),
                ('Atletica Aurora', 'AAU', '#00B894')
        ) AS seed(nome, sigla, cor_principal)
        WHERE NOT EXISTS (
            SELECT 1
            FROM operational.atleticas a
            WHERE lower(a.nome) = lower(seed.nome)
        );
        $dyn$;
    END IF;
END $$;

COMMIT;
