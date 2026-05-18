package com.nkw.backapisumula.cadastros.repo;

import com.nkw.backapisumula.cadastros.AtleticaMembro;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface AtleticaMembroRepository extends JpaRepository<AtleticaMembro, UUID> {

    @EntityGraph(attributePaths = {"user"})
    List<AtleticaMembro> findByAtletica_IdOrderByCriadoEmAsc(UUID atleticaId);

    @EntityGraph(attributePaths = {"atletica"})
    List<AtleticaMembro> findByUser_IdAndStatusOrderByCriadoEmAsc(UUID userId, String status);

    boolean existsByAtletica_IdAndUser_IdAndPapelCodigoAndStatus(
            UUID atleticaId,
            UUID userId,
            String papelCodigo,
            String status
    );

    boolean existsByAtletica_IdAndPapelCodigoAndStatus(UUID atleticaId, String papelCodigo, String status);
}
