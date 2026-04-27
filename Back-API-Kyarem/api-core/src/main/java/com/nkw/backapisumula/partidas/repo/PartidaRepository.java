package com.nkw.backapisumula.partidas.repo;

import com.nkw.backapisumula.partidas.Partida;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface PartidaRepository extends JpaRepository<Partida, UUID> {

    /**
     * Carrega o grafo necessário para montar os DTOs de Partida sem estourar LazyInitializationException.
     */
    @Override
    @EntityGraph(attributePaths = {"modalidade", "modalidade.esporte", "equipeA", "equipeB"})
    List<Partida> findAll();

    /**
     * Versão com EntityGraph para endpoints que retornam PartidaResponse.
     */
    @Override
    @EntityGraph(attributePaths = {"modalidade", "modalidade.esporte", "equipeA", "equipeB"})
    java.util.Optional<Partida> findById(UUID id);

    List<Partida> findByModalidade_Id(UUID modalidadeId);

    List<Partida> findByStatus(String status);

    List<Partida> findByModalidade_IdAndStatus(UUID modalidadeId, String status);
}
