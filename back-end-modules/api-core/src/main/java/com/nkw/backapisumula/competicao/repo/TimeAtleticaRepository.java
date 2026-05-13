package com.nkw.backapisumula.competicao.repo;

import com.nkw.backapisumula.competicao.TimeAtletica;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface TimeAtleticaRepository extends JpaRepository<TimeAtletica, UUID> {
}
