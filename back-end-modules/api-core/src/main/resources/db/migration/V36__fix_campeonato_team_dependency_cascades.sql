-- =============================================================================
-- V36 - Corrige dependencias remanescentes na exclusao de campeonatos
-- =============================================================================

-- Campeonato -> Times por atletica/modalidade
ALTER TABLE operational.campeonato_times
    DROP CONSTRAINT IF EXISTS campeonato_times_campeonato_atletica_id_fkey;

ALTER TABLE operational.campeonato_times
    ADD CONSTRAINT campeonato_times_campeonato_atletica_id_fkey
        FOREIGN KEY (campeonato_atletica_id)
        REFERENCES operational.campeonato_atleticas(id)
        ON DELETE CASCADE;

ALTER TABLE operational.campeonato_times
    DROP CONSTRAINT IF EXISTS campeonato_times_campeonato_modalidade_id_fkey;

ALTER TABLE operational.campeonato_times
    ADD CONSTRAINT campeonato_times_campeonato_modalidade_id_fkey
        FOREIGN KEY (campeonato_modalidade_id)
        REFERENCES operational.campeonato_modalidades(id)
        ON DELETE CASCADE;

-- Time inscrito -> Atletas/staff do campeonato
ALTER TABLE operational.campeonato_atletas
    DROP CONSTRAINT IF EXISTS campeonato_atletas_campeonato_time_id_fkey;

ALTER TABLE operational.campeonato_atletas
    ADD CONSTRAINT campeonato_atletas_campeonato_time_id_fkey
        FOREIGN KEY (campeonato_time_id)
        REFERENCES operational.campeonato_times(id)
        ON DELETE CASCADE;

-- Partida -> Modalidade do campeonato
ALTER TABLE operational.partidas
    DROP CONSTRAINT IF EXISTS partidas_campeonato_modalidade_id_fkey;

ALTER TABLE operational.partidas
    ADD CONSTRAINT partidas_campeonato_modalidade_id_fkey
        FOREIGN KEY (campeonato_modalidade_id)
        REFERENCES operational.campeonato_modalidades(id)
        ON DELETE CASCADE;

-- Partida -> Times do campeonato
ALTER TABLE operational.partidas
    DROP CONSTRAINT IF EXISTS partidas_campeonato_time_a_id_fkey;

ALTER TABLE operational.partidas
    ADD CONSTRAINT partidas_campeonato_time_a_id_fkey
        FOREIGN KEY (campeonato_time_a_id)
        REFERENCES operational.campeonato_times(id)
        ON DELETE SET NULL;

ALTER TABLE operational.partidas
    DROP CONSTRAINT IF EXISTS partidas_campeonato_time_b_id_fkey;

ALTER TABLE operational.partidas
    ADD CONSTRAINT partidas_campeonato_time_b_id_fkey
        FOREIGN KEY (campeonato_time_b_id)
        REFERENCES operational.campeonato_times(id)
        ON DELETE SET NULL;

-- Eventos -> Time do campeonato
ALTER TABLE operational.eventos_partida
    DROP CONSTRAINT IF EXISTS eventos_partida_equipe_id_fkey;

ALTER TABLE operational.eventos_partida
    ADD CONSTRAINT eventos_partida_equipe_id_fkey
        FOREIGN KEY (equipe_id)
        REFERENCES operational.campeonato_times(id)
        ON DELETE SET NULL;
