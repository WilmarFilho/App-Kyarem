CREATE TABLE IF NOT EXISTS equipes_staff (
    id UUID PRIMARY KEY,
    equipe_id UUID NOT NULL,
    nome VARCHAR(255) NOT NULL,
    cargo VARCHAR(100) NOT NULL,
    criado_em TIMESTAMP WITH TIME ZONE,
    CONSTRAINT fk_equipes_staff_equipe FOREIGN KEY (equipe_id) REFERENCES equipes(id) ON DELETE CASCADE
);
