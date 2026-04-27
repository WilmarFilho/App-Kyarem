-- Schema compatível com H2 (substitui 'jsonb' por 'JSON', 'TIMESTAMPTZ' por 'TIMESTAMP WITH TIME ZONE').
-- Usado pelos @DataJpaTest quando ddl-auto=none.

CREATE TABLE IF NOT EXISTS esportes (
    id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
    nome TEXT NOT NULL,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY,
    nome_exibicao TEXT,
    foto_url TEXT,
    telefone TEXT,
    role TEXT NOT NULL DEFAULT 'aluno',
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS atleticas (
    id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
    nome TEXT NOT NULL,
    sigla TEXT,
    cor_principal TEXT,
    escudo_url TEXT,
    presidente_id UUID,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS campeonatos (
    id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
    nome TEXT NOT NULL,
    nivel_campeonato TEXT,
    data_inicio DATE,
    data_fim DATE,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS modalidades (
    id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
    campeonato_id UUID,
    campeonato_nome TEXT,
    esporte_id UUID,
    nome TEXT NOT NULL,
    tempo_partida_minutos INT DEFAULT 40,
    regras_json JSON,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS equipes (
    id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
    atletica_id UUID,
    campeonato_id UUID,
    modalidade_id UUID,
    nome_equipe TEXT NOT NULL,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS atletas (
    id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
    atletica_id UUID,
    nome TEXT NOT NULL,
    foto_url TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tipos_eventos (
    id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
    esporte_id UUID,
    nome TEXT NOT NULL,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS partidas (
    id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
    modalidade_id UUID,
    equipe_a_id UUID,
    equipe_b_id UUID,
    status TEXT,
    categoria TEXT,
    fase TEXT,
    iniciada_em TIMESTAMP WITH TIME ZONE,
    encerrada_em TIMESTAMP WITH TIME ZONE,
    agendado_para TIMESTAMP WITH TIME ZONE,
    local TEXT,
    placar_a INT DEFAULT 0,
    placar_b INT DEFAULT 0,
    snapshot_sumula JSON,
    sumula_pdf_url TEXT,
    hash_integridade TEXT,
    status_antes_pausa TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS partida_arbitros (
    id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
    partida_id UUID,
    arbitro_id UUID,
    funcao TEXT NOT NULL,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS equipe_atlet_inscritos (
    id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
    equipe_id UUID,
    atleta_id UUID,
    numero_camisa INT,
    ativo BOOLEAN DEFAULT TRUE,
    is_goleiro BOOLEAN DEFAULT FALSE,
    is_capitao BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS equipes_staff (
    id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
    equipe_id UUID NOT NULL,
    nome VARCHAR(255) NOT NULL,
    cargo VARCHAR(100) NOT NULL,
    criado_em TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS application_logs (
    id UUID DEFAULT RANDOM_UUID() PRIMARY KEY,
    level TEXT NOT NULL,
    category TEXT NOT NULL,
    message TEXT NOT NULL,
    source TEXT,
    exception_class TEXT,
    stack_trace TEXT,
    details JSON,
    http_method TEXT,
    path TEXT,
    status_code INT,
    user_id UUID,
    request_id TEXT,
    ip_address TEXT,
    user_agent TEXT,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
