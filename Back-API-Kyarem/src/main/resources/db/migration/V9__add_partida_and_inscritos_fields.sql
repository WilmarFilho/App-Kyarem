-- Add categoria and fase to partidas table
ALTER TABLE partidas ADD COLUMN IF NOT EXISTS categoria VARCHAR(255);
ALTER TABLE partidas ADD COLUMN IF NOT EXISTS fase VARCHAR(255);

-- Add boolean flags to equipe_atlet_inscritos table
ALTER TABLE equipe_atlet_inscritos ADD COLUMN IF NOT EXISTS is_goleiro BOOLEAN DEFAULT FALSE;
ALTER TABLE equipe_atlet_inscritos ADD COLUMN IF NOT EXISTS is_capitao BOOLEAN DEFAULT FALSE;
