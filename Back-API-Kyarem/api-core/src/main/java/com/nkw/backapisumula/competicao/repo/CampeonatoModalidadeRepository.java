package com.nkw.backapisumula.competicao.repo;

import com.nkw.backapisumula.competicao.CampeonatoModalidade;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface CampeonatoModalidadeRepository extends JpaRepository<CampeonatoModalidade, UUID> {
}
