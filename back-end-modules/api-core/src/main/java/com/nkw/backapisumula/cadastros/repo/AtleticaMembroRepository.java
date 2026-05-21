package com.nkw.backapisumula.cadastros.repo;

import com.nkw.backapisumula.cadastros.AtleticaMembro;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AtleticaMembroRepository extends JpaRepository<AtleticaMembro, UUID> {

    @EntityGraph(attributePaths = {"user"})
    List<AtleticaMembro> findByAtletica_IdOrderByCriadoEmAsc(UUID atleticaId);

    @EntityGraph(attributePaths = {"atletica"})
    List<AtleticaMembro> findByUser_IdAndStatusOrderByCriadoEmAsc(UUID userId, String status);

    @EntityGraph(attributePaths = {"atletica"})
    List<AtleticaMembro> findByUser_IdOrderByCriadoEmDesc(UUID userId);

    @EntityGraph(attributePaths = {"atletica", "user"})
    Optional<AtleticaMembro> findDetailedById(UUID id);

    boolean existsByAtletica_IdAndUser_IdAndPapelCodigoAndStatus(
            UUID atleticaId,
            UUID userId,
            String papelCodigo,
            String status
    );

    boolean existsByAtletica_IdAndPapelCodigoAndStatus(UUID atleticaId, String papelCodigo, String status);

    boolean existsByAtletica_IdAndUser_IdAndPapelCodigoAndStatusIn(
            UUID atleticaId,
            UUID userId,
            String papelCodigo,
            java.util.Collection<String> statuses
    );

    boolean existsByAtletica_IdAndPapelCodigoAndStatusIn(
            UUID atleticaId,
            String papelCodigo,
            java.util.Collection<String> statuses
    );
}
