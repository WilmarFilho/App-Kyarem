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
    @EntityGraph(attributePaths = {"campeonatoModalidade", "campeonatoModalidade.modalidade", "campeonatoModalidade.modalidade.esporte", "campeonatoTimeA", "campeonatoTimeA.time", "campeonatoTimeA.time.atletica", "campeonatoTimeB", "campeonatoTimeB.time", "campeonatoTimeB.time.atletica"})
    List<Partida> findAll();

    /**
     * Versão com EntityGraph para endpoints que retornam PartidaResponse.
     */
    @Override
    @EntityGraph(attributePaths = {"campeonatoModalidade", "campeonatoModalidade.modalidade", "campeonatoModalidade.modalidade.esporte", "campeonatoTimeA", "campeonatoTimeA.time", "campeonatoTimeA.time.atletica", "campeonatoTimeB", "campeonatoTimeB.time", "campeonatoTimeB.time.atletica"})
    java.util.Optional<Partida> findById(UUID id);

    List<Partida> findByCampeonatoModalidade_Id(UUID modalidadeId);

    List<Partida> findByStatus(String status);

    List<Partida> findByCampeonatoModalidade_IdAndStatus(UUID modalidadeId, String status);

    @EntityGraph(attributePaths = {"campeonatoModalidade", "campeonatoModalidade.modalidade", "campeonatoModalidade.modalidade.esporte", "campeonatoTimeA", "campeonatoTimeA.time", "campeonatoTimeA.time.atletica", "campeonatoTimeB", "campeonatoTimeB.time", "campeonatoTimeB.time.atletica"})
    List<Partida> findByCriadoPor(UUID criadoPor);
}
