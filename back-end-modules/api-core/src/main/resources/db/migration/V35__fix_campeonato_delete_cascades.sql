-- =============================================================================
-- V35 - Corrige exclusao de campeonatos com dependencias operacionais
-- =============================================================================

-- Campeonato -> Times inscritos
ALTER TABLE operational.campeonato_times
    DROP CONSTRAINT IF EXISTS campeonato_times_campeonato_id_fkey;

ALTER TABLE operational.campeonato_times
    ADD CONSTRAINT campeonato_times_campeonato_id_fkey
        FOREIGN KEY (campeonato_id)
        REFERENCES operational.campeonatos(id)
        ON DELETE CASCADE;

-- Campeonato -> Atletas inscritos
ALTER TABLE operational.campeonato_atletas
    DROP CONSTRAINT IF EXISTS campeonato_atletas_campeonato_id_fkey;

ALTER TABLE operational.campeonato_atletas
    ADD CONSTRAINT campeonato_atletas_campeonato_id_fkey
        FOREIGN KEY (campeonato_id)
        REFERENCES operational.campeonatos(id)
        ON DELETE CASCADE;

-- Campeonato -> Partidas
ALTER TABLE operational.partidas
    DROP CONSTRAINT IF EXISTS partidas_campeonato_id_fkey;

ALTER TABLE operational.partidas
    ADD CONSTRAINT partidas_campeonato_id_fkey
        FOREIGN KEY (campeonato_id)
        REFERENCES operational.campeonatos(id)
        ON DELETE CASCADE;