package com.nkw.backapisumula.competicao.repo;

import com.nkw.backapisumula.competicao.EquipeAtletaInscrito;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface EquipeAtletaInscritoRepository extends JpaRepository<EquipeAtletaInscrito, UUID> {

    /**
     * Carrega também os relacionamentos necessários para montar a resposta (atleta, atlética e equipe),
     * evitando LazyInitializationException fora da sessão.
     */
    @EntityGraph(attributePaths = {"equipe", "atleta", "atleta.atletica"})
    List<EquipeAtletaInscrito> findByEquipe_Id(UUID equipeId);

    boolean existsByEquipe_IdAndAtleta_Id(UUID equipeId, UUID atletaId);

    /**
     * Retorna apenas os IDs dos atletas inscritos em uma equipe dentro de um conjunto de atletas.
     * Útil para validações em lote sem carregar entidades completas.
     */
    @Query("select e.atleta.id from EquipeAtletaInscrito e where e.equipe.id = :equipeId and e.atleta.id in :atletaIds")
    List<UUID> findAtletaIdsInscritos(@Param("equipeId") UUID equipeId,
                                      @Param("atletaIds") List<UUID> atletaIds);
}
