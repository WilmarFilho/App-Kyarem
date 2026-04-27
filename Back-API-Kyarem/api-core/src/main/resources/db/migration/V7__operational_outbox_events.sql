-- ==============================================================================
-- 6. MOTOR DE EVENTOS (OUTBOX PATTERN)
-- ==============================================================================

-- Esta tabela é o coração do Outbox Pattern.
-- Sempre que o api-core gravar algo nas tabelas transacionais, ele insere
-- uma linha nesta tabela na mesma transação do banco.
-- O módulo outbox-publisher lerá daqui e publicará no RabbitMQ.

CREATE TABLE operational.outbox_events (
    id UUID PRIMARY KEY,
    aggregate_type VARCHAR(100) NOT NULL, -- Ex: 'partida'
    aggregate_id VARCHAR(100) NOT NULL,
    event_type VARCHAR(100) NOT NULL,     -- Ex: 'partida.criada', 'gol.marcado'
    payload JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMP,
    error_message TEXT
);

-- Indice para o poll do outbox-publisher rodar rápido
CREATE INDEX idx_outbox_events_unprocessed 
ON operational.outbox_events(created_at) 
WHERE processed_at IS NULL;
