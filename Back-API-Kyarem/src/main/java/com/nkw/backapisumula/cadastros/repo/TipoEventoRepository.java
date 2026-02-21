package com.nkw.backapisumula.cadastros.repo;

import com.nkw.backapisumula.cadastros.TipoEvento;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface TipoEventoRepository extends JpaRepository<TipoEvento, UUID> {
    List<TipoEvento> findAllByEsporte_IdOrderByNomeAsc(UUID esporteId);
}
