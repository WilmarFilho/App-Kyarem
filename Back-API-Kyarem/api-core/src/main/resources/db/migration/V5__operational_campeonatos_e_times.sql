-- ==============================================================================
-- 4. CAMPEONATOS E INSCRIÇÕES
-- ==============================================================================

CREATE TABLE operational.campeonatos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(200) NOT NULL,
    ano INTEGER NOT NULL,
    logo_url VARCHAR(500),
    status VARCHAR(50) NOT NULL DEFAULT 'EM_PLANEJAMENTO',
    criado_em TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Quais modalidades serão disputadas neste campeonato
CREATE TABLE operational.campeonato_modalidades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campeonato_id UUID NOT NULL REFERENCES operational.campeonatos(id) ON DELETE CASCADE,
    modalidade_id UUID NOT NULL REFERENCES operational.modalidades_catalogo(id),
    fase_atual VARCHAR(50),
    configuracoes_especificas JSONB, -- Sobrescreve configs do motor se necessario
    UNIQUE(campeonato_id, modalidade_id)
);

-- Atleticas inscritas no campeonato geral
CREATE TABLE operational.campeonato_atleticas (
    campeonato_id UUID NOT NULL REFERENCES operational.campeonatos(id) ON DELETE CASCADE,
    atletica_id UUID NOT NULL REFERENCES operational.atleticas(id) ON DELETE CASCADE,
    status_inscricao VARCHAR(50) NOT NULL DEFAULT 'PENDENTE',
    PRIMARY KEY (campeonato_id, atletica_id)
);

-- Pool de times formados pela atlética
CREATE TABLE operational.times_atletica (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    atletica_id UUID NOT NULL REFERENCES operational.atleticas(id),
    modalidade_id UUID NOT NULL REFERENCES operational.modalidades_catalogo(id),
    nome_time VARCHAR(100) NOT NULL, -- Ex: "Medicina A", "Direito Principal"
    criado_em TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Elenco base do time (quais atletas compõem este time)
CREATE TABLE operational.time_atletica_atletas (
    time_id UUID NOT NULL REFERENCES operational.times_atletica(id) ON DELETE CASCADE,
    atleta_id UUID NOT NULL REFERENCES operational.atletas(id) ON DELETE CASCADE,
    numero_camisa INTEGER,
    posicao VARCHAR(50),
    PRIMARY KEY (time_id, atleta_id)
);

-- Inscrição de um time da atlética em uma modalidade do campeonato
CREATE TABLE operational.campeonato_times (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campeonato_modalidade_id UUID NOT NULL REFERENCES operational.campeonato_modalidades(id) ON DELETE CASCADE,
    time_id UUID NOT NULL REFERENCES operational.times_atletica(id) ON DELETE CASCADE,
    status_inscricao VARCHAR(50) NOT NULL DEFAULT 'CONFIRMADA',
    UNIQUE(campeonato_modalidade_id, time_id)
);

-- Relacionamento N:M para inscrições diretas de atletas (esportes individuais)
CREATE TABLE operational.campeonato_atletas (
    campeonato_modalidade_id UUID NOT NULL REFERENCES operational.campeonato_modalidades(id) ON DELETE CASCADE,
    atleta_id UUID NOT NULL REFERENCES operational.atletas(id) ON DELETE CASCADE,
    PRIMARY KEY (campeonato_modalidade_id, atleta_id)
);
