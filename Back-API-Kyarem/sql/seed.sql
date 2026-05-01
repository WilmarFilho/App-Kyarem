-- ==============================================================================
-- SEED DE DADOS PARA TESTES E DESENVOLVIMENTO
-- Senha padrão para todos os usuários inseridos: 121212
-- ==============================================================================

DO $$
DECLARE
    -- Constantes de Autenticação
    -- crypt('121212', gen_salt('bf'))
    default_password TEXT := crypt('121212', gen_salt('bf'));

    -- Esportes e Modalidades
    esporte_futsal_id UUID;
    modalidade_futsal_masc_id UUID;

    -- Campeonato
    campeonato_id UUID := gen_random_uuid();
    campeonato_modalidade_id UUID := gen_random_uuid();

    -- Atlética 1 (Engenharia) e Presidência
    atletica1_id UUID := gen_random_uuid();
    pres1_user_id UUID := gen_random_uuid();
    
    -- Atlética 1 Atletas (auth.users)
    a1_u1_id UUID := gen_random_uuid();
    a1_u2_id UUID := gen_random_uuid();
    a1_u3_id UUID := gen_random_uuid();
    a1_u4_id UUID := gen_random_uuid();
    a1_u5_id UUID := gen_random_uuid();
    
    -- Atlética 1 Atletas (operational.atletas)
    a1_atl1_id UUID := gen_random_uuid();
    a1_atl2_id UUID := gen_random_uuid();
    a1_atl3_id UUID := gen_random_uuid();
    a1_atl4_id UUID := gen_random_uuid();
    a1_atl5_id UUID := gen_random_uuid();
    
    -- Atlética 1 Equipes/Inscrições
    time_atl1_id UUID := gen_random_uuid();
    camp_atl1_id UUID := gen_random_uuid();
    camp_time1_id UUID := gen_random_uuid();

    -- Atlética 2 (Medicina) e Presidência
    atletica2_id UUID := gen_random_uuid();
    pres2_user_id UUID := gen_random_uuid();
    
    -- Atlética 2 Atletas (auth.users)
    a2_u1_id UUID := gen_random_uuid();
    a2_u2_id UUID := gen_random_uuid();
    a2_u3_id UUID := gen_random_uuid();
    a2_u4_id UUID := gen_random_uuid();
    a2_u5_id UUID := gen_random_uuid();
    
    -- Atlética 2 Atletas (operational.atletas)
    a2_atl1_id UUID := gen_random_uuid();
    a2_atl2_id UUID := gen_random_uuid();
    a2_atl3_id UUID := gen_random_uuid();
    a2_atl4_id UUID := gen_random_uuid();
    a2_atl5_id UUID := gen_random_uuid();
    
    -- Atlética 2 Equipes/Inscrições
    time_atl2_id UUID := gen_random_uuid();
    camp_atl2_id UUID := gen_random_uuid();
    camp_time2_id UUID := gen_random_uuid();

BEGIN
    ----------------------------------------------------------------------------
    -- 1. CATÁLOGO
    ----------------------------------------------------------------------------
    SELECT id INTO esporte_futsal_id FROM operational.esportes WHERE nome = 'Futsal' LIMIT 1;
    IF esporte_futsal_id IS NULL THEN
        esporte_futsal_id := gen_random_uuid();
        INSERT INTO operational.esportes (id, nome) VALUES (esporte_futsal_id, 'Futsal');
    END IF;

    SELECT id INTO modalidade_futsal_masc_id FROM operational.modalidades_catalogo WHERE codigo = 'futsal_masculino' LIMIT 1;
    IF modalidade_futsal_masc_id IS NULL THEN
        modalidade_futsal_masc_id := gen_random_uuid();
        INSERT INTO operational.modalidades_catalogo (id, esporte_id, codigo, nome, ativo)
        VALUES (modalidade_futsal_masc_id, esporte_futsal_id, 'futsal_masculino', 'Futsal Masculino', true);
    END IF;

    ----------------------------------------------------------------------------
    -- 2. AUTH USERS (Dispara trigger que cria operational.profiles)
    ----------------------------------------------------------------------------
    INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
    VALUES 
    -- Presidentes
    (pres1_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'pres.eng@seed.com', default_password, now(), '{"provider":"email","providers":["email"]}', '{"nome_completo": "Presidente Engenharia", "nome_exibicao": "Pres. Eng"}', now(), now()),
    (pres2_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'pres.med@seed.com', default_password, now(), '{"provider":"email","providers":["email"]}', '{"nome_completo": "Presidente Medicina", "nome_exibicao": "Pres. Med"}', now(), now()),
    
    -- Atletas Eng
    (a1_u1_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'atl1.eng@seed.com', default_password, now(), '{"provider":"email","providers":["email"]}', '{"nome_completo": "Atleta 1 Eng", "nome_exibicao": "A1 Eng"}', now(), now()),
    (a1_u2_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'atl2.eng@seed.com', default_password, now(), '{"provider":"email","providers":["email"]}', '{"nome_completo": "Atleta 2 Eng", "nome_exibicao": "A2 Eng"}', now(), now()),
    (a1_u3_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'atl3.eng@seed.com', default_password, now(), '{"provider":"email","providers":["email"]}', '{"nome_completo": "Atleta 3 Eng", "nome_exibicao": "A3 Eng"}', now(), now()),
    (a1_u4_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'atl4.eng@seed.com', default_password, now(), '{"provider":"email","providers":["email"]}', '{"nome_completo": "Atleta 4 Eng", "nome_exibicao": "A4 Eng"}', now(), now()),
    (a1_u5_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'atl5.eng@seed.com', default_password, now(), '{"provider":"email","providers":["email"]}', '{"nome_completo": "Atleta 5 Eng", "nome_exibicao": "A5 Eng"}', now(), now()),
    
    -- Atletas Med
    (a2_u1_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'atl1.med@seed.com', default_password, now(), '{"provider":"email","providers":["email"]}', '{"nome_completo": "Atleta 1 Med", "nome_exibicao": "A1 Med"}', now(), now()),
    (a2_u2_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'atl2.med@seed.com', default_password, now(), '{"provider":"email","providers":["email"]}', '{"nome_completo": "Atleta 2 Med", "nome_exibicao": "A2 Med"}', now(), now()),
    (a2_u3_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'atl3.med@seed.com', default_password, now(), '{"provider":"email","providers":["email"]}', '{"nome_completo": "Atleta 3 Med", "nome_exibicao": "A3 Med"}', now(), now()),
    (a2_u4_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'atl4.med@seed.com', default_password, now(), '{"provider":"email","providers":["email"]}', '{"nome_completo": "Atleta 4 Med", "nome_exibicao": "A4 Med"}', now(), now()),
    (a2_u5_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'atl5.med@seed.com', default_password, now(), '{"provider":"email","providers":["email"]}', '{"nome_completo": "Atleta 5 Med", "nome_exibicao": "A5 Med"}', now(), now());

    ----------------------------------------------------------------------------
    -- 3. ATLÉTICAS
    ----------------------------------------------------------------------------
    INSERT INTO operational.atleticas (id, nome, sigla, status, criado_por)
    VALUES 
    (atletica1_id, 'Atlética de Engenharia', 'ENG', 'ATIVA', pres1_user_id),
    (atletica2_id, 'Atlética de Medicina', 'MED', 'ATIVA', pres2_user_id);

    ----------------------------------------------------------------------------
    -- 4. ATLÉTICA MEMBROS (Papéis)
    ----------------------------------------------------------------------------
    INSERT INTO operational.atletica_membros (atletica_id, user_id, papel_codigo, status, criado_por)
    VALUES 
    -- Presidentes
    (atletica1_id, pres1_user_id, 'PRESIDENT', 'ATIVO', pres1_user_id),
    (atletica2_id, pres2_user_id, 'PRESIDENT', 'ATIVO', pres2_user_id),
    
    -- Membros Atletas (Eng)
    (atletica1_id, a1_u1_id, 'ATHLETE', 'ATIVO', pres1_user_id),
    (atletica1_id, a1_u2_id, 'ATHLETE', 'ATIVO', pres1_user_id),
    (atletica1_id, a1_u3_id, 'ATHLETE', 'ATIVO', pres1_user_id),
    (atletica1_id, a1_u4_id, 'ATHLETE', 'ATIVO', pres1_user_id),
    (atletica1_id, a1_u5_id, 'ATHLETE', 'ATIVO', pres1_user_id),
    
    -- Membros Atletas (Med)
    (atletica2_id, a2_u1_id, 'ATHLETE', 'ATIVO', pres2_user_id),
    (atletica2_id, a2_u2_id, 'ATHLETE', 'ATIVO', pres2_user_id),
    (atletica2_id, a2_u3_id, 'ATHLETE', 'ATIVO', pres2_user_id),
    (atletica2_id, a2_u4_id, 'ATHLETE', 'ATIVO', pres2_user_id),
    (atletica2_id, a2_u5_id, 'ATHLETE', 'ATIVO', pres2_user_id);

    ----------------------------------------------------------------------------
    -- 5. ATLETAS (Operational - Dados competitivos)
    ----------------------------------------------------------------------------
    INSERT INTO operational.atletas (id, user_id, nome_competicao, ativo)
    VALUES 
    (a1_atl1_id, a1_u1_id, 'A1 Eng', true),
    (a1_atl2_id, a1_u2_id, 'A2 Eng', true),
    (a1_atl3_id, a1_u3_id, 'A3 Eng', true),
    (a1_atl4_id, a1_u4_id, 'A4 Eng', true),
    (a1_atl5_id, a1_u5_id, 'A5 Eng', true),
    
    (a2_atl1_id, a2_u1_id, 'A1 Med', true),
    (a2_atl2_id, a2_u2_id, 'A2 Med', true),
    (a2_atl3_id, a2_u3_id, 'A3 Med', true),
    (a2_atl4_id, a2_u4_id, 'A4 Med', true),
    (a2_atl5_id, a2_u5_id, 'A5 Med', true);

    ----------------------------------------------------------------------------
    -- 6. CAMPEONATOS E MODALIDADES
    ----------------------------------------------------------------------------
    INSERT INTO operational.campeonatos (id, nome, nivel, status)
    VALUES (campeonato_id, 'Intermed 2026', 'UNIVERSITARIO', 'EM_ANDAMENTO');

    INSERT INTO operational.campeonato_modalidades (id, campeonato_id, modalidade_catalogo_id, nome_exibicao, status)
    VALUES (campeonato_modalidade_id, campeonato_id, modalidade_futsal_masc_id, 'Futsal Masc', 'ATIVA');

    ----------------------------------------------------------------------------
    -- 7. INSCRIÇÃO DAS ATLÉTICAS
    ----------------------------------------------------------------------------
    INSERT INTO operational.campeonato_atleticas (id, campeonato_id, atletica_id, status)
    VALUES 
    (camp_atl1_id, campeonato_id, atletica1_id, 'APROVADO'),
    (camp_atl2_id, campeonato_id, atletica2_id, 'APROVADO');

    ----------------------------------------------------------------------------
    -- 8. TIMES PERMANENTES (Roster) E ELENCO
    ----------------------------------------------------------------------------
    INSERT INTO operational.times_atletica (id, atletica_id, modalidade_catalogo_id, nome, status)
    VALUES 
    (time_atl1_id, atletica1_id, modalidade_futsal_masc_id, 'Engenharia Futsal', 'ATIVO'),
    (time_atl2_id, atletica2_id, modalidade_futsal_masc_id, 'Medicina Futsal', 'ATIVO');

    INSERT INTO operational.time_atletica_atletas (time_atletica_id, atleta_id, status)
    VALUES 
    (time_atl1_id, a1_atl1_id, 'ATIVO'),
    (time_atl1_id, a1_atl2_id, 'ATIVO'),
    (time_atl1_id, a1_atl3_id, 'ATIVO'),
    (time_atl1_id, a1_atl4_id, 'ATIVO'),
    (time_atl1_id, a1_atl5_id, 'ATIVO'),
    
    (time_atl2_id, a2_atl1_id, 'ATIVO'),
    (time_atl2_id, a2_atl2_id, 'ATIVO'),
    (time_atl2_id, a2_atl3_id, 'ATIVO'),
    (time_atl2_id, a2_atl4_id, 'ATIVO'),
    (time_atl2_id, a2_atl5_id, 'ATIVO');

    ----------------------------------------------------------------------------
    -- 9. INSCRIÇÃO DO TIME NO CAMPEONATO (Roster do Camp)
    ----------------------------------------------------------------------------
    INSERT INTO operational.campeonato_times (id, campeonato_id, campeonato_atletica_id, campeonato_modalidade_id, time_atletica_id, status)
    VALUES 
    (camp_time1_id, campeonato_id, camp_atl1_id, campeonato_modalidade_id, time_atl1_id, 'CONFIRMADA'),
    (camp_time2_id, campeonato_id, camp_atl2_id, campeonato_modalidade_id, time_atl2_id, 'CONFIRMADA');

    INSERT INTO operational.campeonato_atletas (campeonato_id, atletica_id, campeonato_time_id, atleta_id, numero_camisa, is_capitao, is_goleiro, status)
    VALUES 
    -- Eng
    (campeonato_id, atletica1_id, camp_time1_id, a1_atl1_id, 1, false, true, 'ATIVO'),
    (campeonato_id, atletica1_id, camp_time1_id, a1_atl2_id, 10, true, false, 'ATIVO'),
    (campeonato_id, atletica1_id, camp_time1_id, a1_atl3_id, 9, false, false, 'ATIVO'),
    (campeonato_id, atletica1_id, camp_time1_id, a1_atl4_id, 5, false, false, 'ATIVO'),
    (campeonato_id, atletica1_id, camp_time1_id, a1_atl5_id, 3, false, false, 'ATIVO'),
    -- Med
    (campeonato_id, atletica2_id, camp_time2_id, a2_atl1_id, 1, false, true, 'ATIVO'),
    (campeonato_id, atletica2_id, camp_time2_id, a2_atl2_id, 10, true, false, 'ATIVO'),
    (campeonato_id, atletica2_id, camp_time2_id, a2_atl3_id, 9, false, false, 'ATIVO'),
    (campeonato_id, atletica2_id, camp_time2_id, a2_atl4_id, 5, false, false, 'ATIVO'),
    (campeonato_id, atletica2_id, camp_time2_id, a2_atl5_id, 3, false, false, 'ATIVO');

END $$;
