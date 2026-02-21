package com.nkw.backapisumula.cadastros.repo;

import com.nkw.backapisumula.cadastros.Atleta;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface AtletaRepository extends JpaRepository<Atleta, UUID> {
    List<Atleta> findAllByAtletica_IdOrderByNomeAsc(UUID atleticaId);
}
