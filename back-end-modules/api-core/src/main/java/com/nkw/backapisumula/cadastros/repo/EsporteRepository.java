package com.nkw.backapisumula.cadastros.repo;

import com.nkw.backapisumula.cadastros.Esporte;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface EsporteRepository extends JpaRepository<Esporte, UUID> {
    Optional<Esporte> findByNomeIgnoreCase(String nome);
}
