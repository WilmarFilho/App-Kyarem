-- ==============================================================================
-- 5. PARTIDAS E ARBITRAGEM
-- ==============================================================================

CREATE TABLE operational.partidas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campeonato_modalidade_id UUID NOT NULL REFERENCES operational.campeonato_modalidades(id),
    
    -- Opcionais: se a modalidade usar times (maioria)
    campeonato_time_a_id UUID REFERENCES operational.campeonato_times(id),
    campeonato_time_b_id UUID REFERENCES operational.campeonato_times(id),
    
    status VARCHAR(50) NOT NULL DEFAULT 'AGENDADA', -- AGENDADA, ANDAMENTO, INTERVALO, ENCERRADA
    status_antes_pausa VARCHAR(50),
    data_hora_agendada TIMESTAMP,
    data_hora_inicio TIMESTAMP,
    data_hora_fim TIMESTAMP,
    
    -- Estado interno da engine
    periodo_atual VARCHAR(20),
    cronometro_segundos INTEGER DEFAULT 0,
    
    -- Placar oficial
    placar_time_a INTEGER DEFAULT 0,
    placar_time_b INTEGER DEFAULT 0,
    placar_penaltis_time_a INTEGER DEFAULT 0,
    placar_penaltis_time_b INTEGER DEFAULT 0,
    
    -- Contexto (fase de grupos, eliminatória)
    fase VARCHAR(50),
    grupo VARCHAR(20),
    local VARCHAR(150),
    
    criado_em TIMESTAMP NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Atribuição de árbitros e mesários para a partida
CREATE TABLE operational.partida_arbitros (
    partida_id UUID NOT NULL REFERENCES operational.partidas(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES operational.profiles(id),
    funcao VARCHAR(50) NOT NULL, -- ARBITRO_PRINCIPAL, ARBITRO_AUXILIAR, ANOTADOR, CRONOMETRISTA
    PRIMARY KEY (partida_id, user_id)
);

-- Eventos de jogo (Gols, cartões, faltas, tempos técnicos)
CREATE TABLE operational.eventos_partida (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    partida_id UUID NOT NULL REFERENCES operational.partidas(id) ON DELETE CASCADE,
    tipo_evento_id UUID NOT NULL REFERENCES operational.tipos_eventos(id),
    
    -- Quem sofreu/gerou a ação
    time_id UUID REFERENCES operational.campeonato_times(id),
    atleta_id UUID REFERENCES operational.atletas(id),
    
    -- Controle de tempo exato da ocorrência
    periodo VARCHAR(20),
    minuto_segundo VARCHAR(10),
    
    -- Payload flexível para extensibilidade (ex: lado do gol, tipo de falta)
    dados_extras JSONB,
    
    criado_por_user_id UUID NOT NULL REFERENCES operational.profiles(id),
    criado_em TIMESTAMP NOT NULL DEFAULT NOW()
);
