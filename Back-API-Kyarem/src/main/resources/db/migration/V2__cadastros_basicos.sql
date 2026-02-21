-- Cadastros globais e identidade (subset MVP Semana 1)
CREATE TABLE IF NOT EXISTS esportes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL UNIQUE,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nome_exibicao TEXT,
    foto_url TEXT,
    telefone TEXT,
    role TEXT NOT NULL DEFAULT 'aluno',
    atualizado_em TIMESTAMPTZ DEFAULT NOW(),
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS atleticas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL,
    sigla TEXT,
    cor_principal TEXT,
    escudo_url TEXT,
    presidente_id UUID,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- FK presidente (idempotente via DO)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_presidente'
    ) THEN
        ALTER TABLE atleticas
        ADD CONSTRAINT fk_presidente
        FOREIGN KEY (presidente_id) REFERENCES profiles(id) ON DELETE SET NULL;
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS atletas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    atletica_id UUID REFERENCES atleticas(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    criado_em TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tipos_eventos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    esporte_id UUID REFERENCES esportes(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    criado_em TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(esporte_id, nome)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_atlet_atletica_id ON atletas(atletica_id);
