-- =============================================================================
-- V42 - Corrige exclusao em cascata ao deletar modalidades_catalogo
--
-- Problema: ao tentar excluir uma modalidade do catalogo que possui
-- tipos_eventos, campeonato_modalidades ou times_atletica vinculados,
-- o banco lanava violacao de FK porque essas FKs nao tinham ON DELETE CASCADE.
--
-- Solucao: recriar as FKs com ON DELETE CASCADE para que a exclusao de uma
-- modalidade_catalogo apague automaticamente todos os registros dependentes.
-- =============================================================================

-- ─── tipos_eventos ────────────────────────────────────────────────────────────
-- Tipos de eventos de uma modalidade devem ser apagados junto com a modalidade
ALTER TABLE operational.tipos_eventos
    DROP CONSTRAINT IF EXISTS tipos_eventos_modalidade_catalogo_id_fkey;

ALTER TABLE operational.tipos_eventos
    ADD CONSTRAINT tipos_eventos_modalidade_catalogo_id_fkey
        FOREIGN KEY (modalidade_catalogo_id)
        REFERENCES operational.modalidades_catalogo(id)
        ON DELETE CASCADE;

-- ─── campeonato_modalidades ───────────────────────────────────────────────────
-- Associacoes de modalidade a campeonatos devem ser apagadas junto
ALTER TABLE operational.campeonato_modalidades
    DROP CONSTRAINT IF EXISTS campeonato_modalidades_modalidade_catalogo_id_fkey;

ALTER TABLE operational.campeonato_modalidades
    ADD CONSTRAINT campeonato_modalidades_modalidade_catalogo_id_fkey
        FOREIGN KEY (modalidade_catalogo_id)
        REFERENCES operational.modalidades_catalogo(id)
        ON DELETE CASCADE;

-- ─── times_atletica ───────────────────────────────────────────────────────────
-- Times permanentes de uma modalidade devem ser apagados junto
-- Nota: campeonato_times.campeonato_modalidade_id ja tem CASCADE (V36)
--       então as inscrições de times em campeonatos já serão apagadas em cascata
ALTER TABLE operational.times_atletica
    DROP CONSTRAINT IF EXISTS times_atletica_modalidade_catalogo_id_fkey;

ALTER TABLE operational.times_atletica
    ADD CONSTRAINT times_atletica_modalidade_catalogo_id_fkey
        FOREIGN KEY (modalidade_catalogo_id)
        REFERENCES operational.modalidades_catalogo(id)
        ON DELETE CASCADE;
