package com.nkw.backapisumula.competicao.repo;

import com.nkw.backapisumula.competicao.Equipe;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface EquipeRepository extends JpaRepository<Equipe, UUID> {
    List<Equipe> findByCampeonato_Id(UUID campeonatoId);
    List<Equipe> findByModalidade_Id(UUID modalidadeId);
    List<Equipe> findByAtletica_Id(UUID atleticaId);

    List<Equipe> findByCampeonato_IdAndModalidade_Id(UUID campeonatoId, UUID modalidadeId);
    List<Equipe> findByCampeonato_IdAndAtletica_Id(UUID campeonatoId, UUID atleticaId);
    List<Equipe> findByModalidade_IdAndAtletica_Id(UUID modalidadeId, UUID atleticaId);
    List<Equipe> findByCampeonato_IdAndModalidade_IdAndAtletica_Id(UUID campeonatoId, UUID modalidadeId, UUID atleticaId);
}
