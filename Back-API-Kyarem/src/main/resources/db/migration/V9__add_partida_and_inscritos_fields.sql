-- Add categoria and fase to partidas table
ALTER TABLE partidas ADD COLUMN IF NOT EXISTS categoria VARCHAR(255);
ALTER TABLE partidas ADD COLUMN IF NOT EXISTS fase VARCHAR(255);

-- Add boolean flags to equipe_atlet_inscritos table
ALTER TABLE equipe_atlet_inscritos ADD COLUMN IF NOT EXISTS is_goleiro BOOLEAN DEFAULT FALSE;
ALTER TABLE equipe_atlet_inscritos ADD COLUMN IF NOT EXISTS is_capitao BOOLEAN DEFAULT FALSE;


CREATE TABLE IF NOT EXISTS equipes_staff (
    id UUID PRIMARY KEY,
    equipe_id UUID NOT NULL,
    nome VARCHAR(255) NOT NULL,
    cargo VARCHAR(100) NOT NULL,
    criado_em TIMESTAMP WITH TIME ZONE,
    CONSTRAINT fk_equipes_staff_equipe FOREIGN KEY (equipe_id) REFERENCES equipes(id) ON DELETE CASCADE
);
