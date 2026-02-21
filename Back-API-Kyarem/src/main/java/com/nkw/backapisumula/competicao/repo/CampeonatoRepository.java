package com.nkw.backapisumula.competicao.repo;

import com.nkw.backapisumula.competicao.Campeonato;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface CampeonatoRepository extends JpaRepository<Campeonato, UUID> {}
