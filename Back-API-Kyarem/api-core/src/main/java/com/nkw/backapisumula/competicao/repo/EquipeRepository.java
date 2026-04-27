package com.nkw.backapisumula.competicao.repo;

import com.nkw.backapisumula.competicao.Equipe;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface EquipeRepository extends JpaRepository<Equipe, UUID> {

    @Override
    @EntityGraph(attributePaths = {"atletica", "campeonato", "modalidade"})
    List<Equipe> findAll();

    @Override
    @EntityGraph(attributePaths = {"atletica", "campeonato", "modalidade"})
    Optional<Equipe> findById(UUID id);

    @EntityGraph(attributePaths = {"atletica", "campeonato", "modalidade"})
    List<Equipe> findByCampeonato_Id(UUID campeonatoId);

    @EntityGraph(attributePaths = {"atletica", "campeonato", "modalidade"})
    List<Equipe> findByModalidade_Id(UUID modalidadeId);

    @EntityGraph(attributePaths = {"atletica", "campeonato", "modalidade"})
    List<Equipe> findByAtletica_Id(UUID atleticaId);

    @EntityGraph(attributePaths = {"atletica", "campeonato", "modalidade"})
    List<Equipe> findByCampeonato_IdAndModalidade_Id(UUID campeonatoId, UUID modalidadeId);

    @EntityGraph(attributePaths = {"atletica", "campeonato", "modalidade"})
    List<Equipe> findByCampeonato_IdAndAtletica_Id(UUID campeonatoId, UUID atleticaId);

    @EntityGraph(attributePaths = {"atletica", "campeonato", "modalidade"})
    List<Equipe> findByModalidade_IdAndAtletica_Id(UUID modalidadeId, UUID atleticaId);

    @EntityGraph(attributePaths = {"atletica", "campeonato", "modalidade"})
    List<Equipe> findByCampeonato_IdAndModalidade_IdAndAtletica_Id(UUID campeonatoId, UUID modalidadeId, UUID atleticaId);
}
