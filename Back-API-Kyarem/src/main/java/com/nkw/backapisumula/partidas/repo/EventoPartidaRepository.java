package com.nkw.backapisumula.partidas.repo;

import com.nkw.backapisumula.partidas.EventoPartida;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.UUID;

public interface EventoPartidaRepository extends JpaRepository<EventoPartida, UUID> {

    List<EventoPartida> findByPartida_IdOrderByCriadoEmAsc(UUID partidaId);

    /**
     * Usado para geração de snapshot (súmula) sem LazyInitializationException.
     */
    @Query("""
            select e from EventoPartida e
              join e.partida p
              left join fetch e.atleta a
              left join fetch e.equipe eq
              left join fetch e.tipoEvento te
            where p.id = :partidaId
            order by e.criadoEm asc
            """)
    List<EventoPartida> findByPartidaIdWithDetails(UUID partidaId);
}
