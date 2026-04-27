-- ==============================================================================
-- 8. READ MODELS (SCHEMA PUBLIC)
-- ==============================================================================

-- Estas tabelas/views viverão no schema PUBLIC e servirão
-- para os apps do celular lerem diretamente sem passar pelo backend,
-- aproveitando o RLS (Row Level Security) do Supabase.

CREATE TABLE public.campeonatos_vitrine (
    id UUID PRIMARY KEY, -- Mesma ID do operational
    nome VARCHAR(200) NOT NULL,
    ano INTEGER NOT NULL,
    logo_url VARCHAR(500),
    status VARCHAR(50) NOT NULL,
    atualizado_em TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE public.partidas_ao_vivo (
    id UUID PRIMARY KEY,
    campeonato_id UUID NOT NULL,
    time_a_nome VARCHAR(100),
    time_b_nome VARCHAR(100),
    time_a_logo VARCHAR(500),
    time_b_logo VARCHAR(500),
    status VARCHAR(50),
    placar_time_a INTEGER,
    placar_time_b INTEGER,
    periodo_atual VARCHAR(20),
    cronometro_segundos INTEGER,
    atualizado_em TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Tabela para o motor de métricas calcular e gravar o Ranking e Classificações
CREATE TABLE public.classificacoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campeonato_modalidade_id UUID NOT NULL,
    time_id UUID NOT NULL,
    time_nome VARCHAR(100),
    pontos INTEGER DEFAULT 0,
    jogos INTEGER DEFAULT 0,
    vitorias INTEGER DEFAULT 0,
    empates INTEGER DEFAULT 0,
    derrotas INTEGER DEFAULT 0,
    gols_pro INTEGER DEFAULT 0,
    gols_contra INTEGER DEFAULT 0,
    saldo_gols INTEGER DEFAULT 0,
    atualizado_em TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(campeonato_modalidade_id, time_id)
);

CREATE TABLE public.artilharia (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campeonato_modalidade_id UUID NOT NULL,
    atleta_id UUID NOT NULL,
    atleta_nome VARCHAR(150),
    time_nome VARCHAR(100),
    gols_marcados INTEGER DEFAULT 0,
    atualizado_em TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(campeonato_modalidade_id, atleta_id)
);

-- Feed de Eventos Públicos (Social/Notificações)
CREATE TABLE public.feed_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    autor_nome VARCHAR(150),
    autor_foto_url VARCHAR(500),
    tipo_post VARCHAR(50), -- GOL, RESULTADO, FOTO
    conteudo TEXT,
    midia_url VARCHAR(500),
    referencia_partida_id UUID,
    criado_em TIMESTAMP NOT NULL DEFAULT NOW()
);
