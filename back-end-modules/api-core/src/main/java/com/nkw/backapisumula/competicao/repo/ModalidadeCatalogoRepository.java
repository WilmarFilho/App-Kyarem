package com.nkw.backapisumula.competicao.repo;

import com.nkw.backapisumula.competicao.ModalidadeCatalogo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ModalidadeCatalogoRepository extends JpaRepository<ModalidadeCatalogo, UUID> {
    java.util.List<ModalidadeCatalogo> findAllByOrderByNomeAsc();
}
