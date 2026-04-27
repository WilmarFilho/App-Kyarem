package com.nkw.backapisumula.partidas.repo;

import com.nkw.backapisumula.partidas.PartidaArbitro;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.UUID;

public interface PartidaArbitroRepository extends JpaRepository<PartidaArbitro, UUID> {

    @EntityGraph(attributePaths = {
            "partida",
            "partida.modalidade",
            "partida.modalidade.esporte",
            "partida.equipeA",
            "partida.equipeB"
    })
    List<PartidaArbitro> findByPartida_Id(UUID partidaId);

    boolean existsByPartida_IdAndArbitro_Id(UUID partidaId, UUID arbitroId);

    @EntityGraph(attributePaths = {
            "partida",
            "partida.modalidade",
            "partida.modalidade.esporte",
            "partida.equipeA",
            "partida.equipeB"
    })
    List<PartidaArbitro> findByArbitro_Id(UUID arbitroId);

    /**
     * Usado para geração de snapshot (súmula) sem LazyInitializationException.
     */
    @Query("""
            select pa from PartidaArbitro pa
              join pa.partida p
              left join fetch pa.arbitro a
            where p.id = :partidaId
            order by pa.criadoEm asc
            """)
    List<PartidaArbitro> findByPartidaIdWithArbitro(UUID partidaId);

}
