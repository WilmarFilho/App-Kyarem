package com.nkw.backapisumula.competicao.repo;

import com.nkw.backapisumula.competicao.CampeonatoAtleta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CampeonatoAtletaRepository extends JpaRepository<CampeonatoAtleta, UUID> {
    
    @Query("SELECT ca FROM CampeonatoAtleta ca " +
           "JOIN FETCH ca.atleta a " +
           "WHERE ca.campeonatoTime.id = :campeonatoTimeId")
    List<CampeonatoAtleta> findByCampeonatoTime_Id(UUID campeonatoTimeId);
}
