-- ==============================================================================
-- 3. ATLÉTICAS E ATLETAS
-- ==============================================================================

CREATE TABLE operational.atleticas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(150) NOT NULL,
    sigla VARCHAR(20) NOT NULL,
    logo_url VARCHAR(500),
    universidade VARCHAR(150),
    criado_em TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE operational.atletica_membros (
    atletica_id UUID NOT NULL REFERENCES operational.atleticas(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES operational.profiles(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL, -- PRESIDENTE, DIRETOR, DIRETOR_ESPORTES
    criado_em TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (atletica_id, user_id)
);

-- Atleta é a extensão esportiva de um usuário (profile).
-- É opcional. Um profile pode existir sem ser atleta.
CREATE TABLE operational.atletas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES operational.profiles(id) ON DELETE SET NULL,
    documento_identidade VARCHAR(50),
    data_nascimento DATE,
    genero_esportivo VARCHAR(20), -- MASCULINO, FEMININO
    criado_em TIMESTAMP NOT NULL DEFAULT NOW()
);
