package com.nkw.backapisumula.cadastros.repo;

import com.nkw.backapisumula.cadastros.Atletica;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface AtleticaRepository extends JpaRepository<Atletica, UUID> {}
