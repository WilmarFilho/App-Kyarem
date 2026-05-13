package com.nkw.backapisumula.identity.repo;

import com.nkw.backapisumula.identity.UsuarioRoleGlobal;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface UsuarioRoleGlobalRepository extends JpaRepository<UsuarioRoleGlobal, UUID> {
    boolean existsByUserIdAndRole(UUID userId, String role);
}
