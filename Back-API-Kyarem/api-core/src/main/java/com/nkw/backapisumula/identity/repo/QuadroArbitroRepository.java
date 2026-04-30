package com.nkw.backapisumula.identity.repo;

import com.nkw.backapisumula.identity.QuadroArbitro;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface QuadroArbitroRepository extends JpaRepository<QuadroArbitro, UUID> {
    Optional<QuadroArbitro> findByUserId(UUID userId);
    boolean existsByUserIdAndStatus(UUID userId, String status);
}
