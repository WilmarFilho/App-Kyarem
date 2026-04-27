package com.nkw.backapisumula.partidas.repo;

import com.nkw.backapisumula.partidas.EventoPartida;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param; // ← ADD

import java.util.Collection; // ← ADD
import java.util.List;
import java.util.Set;        // ← ADD
import java.util.UUID;

public interface EventoPartidaRepository extends JpaRepository<EventoPartida, UUID> {

    List<EventoPartida> findByPartida_IdOrderByCriadoEmAsc(UUID partidaId);

    boolean existsByLocalEventoId(String localEventoId);

    @Query("SELECT e.localEventoId FROM EventoPartida e WHERE e.localEventoId IN :ids")
    Set<String> findExistingLocalEventoIds(@Param("ids") Collection<String> ids);

    @Query("""
            select e from EventoPartida e
              join e.partida p
              left join fetch e.atleta a
              left join fetch e.atletaSai asai
              left join fetch e.equipe eq
              left join fetch e.tipoEvento te
            where p.id = :partidaId
            order by e.criadoEm asc
            """)
    List<EventoPartida> findByPartidaIdWithDetails(UUID partidaId);
}