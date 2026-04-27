-- ==============================================================================
-- 1. IDENTIDADE E CONTROLE DE ACESSO
-- ==============================================================================

-- auth.users já é provido pelo Supabase no schema auth.

CREATE TABLE operational.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nome_exibicao VARCHAR(150),
    foto_url VARCHAR(500),
    criado_em TIMESTAMP NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Tabela para roles globais (Substitui o antigo profile.role enum)
-- Roles possiveis: ADMIN_PLATAFORMA, ORGANIZADOR, ARBITRO_COMUM
CREATE TABLE operational.usuarios_roles_globais (
    user_id UUID NOT NULL REFERENCES operational.profiles(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL,
    criado_em TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, role)
);
