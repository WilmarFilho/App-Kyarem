package com.nkw.backapisumula.competicao.repo;

import com.nkw.backapisumula.competicao.Modalidade;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ModalidadeRepository extends JpaRepository<Modalidade, UUID> {
    @EntityGraph(attributePaths = {"esporte","campeonato"})
    List<Modalidade> findByCampeonato_Id(UUID campeonatoId);
}
