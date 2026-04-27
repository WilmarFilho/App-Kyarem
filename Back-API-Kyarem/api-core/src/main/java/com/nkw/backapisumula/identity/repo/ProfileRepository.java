package com.nkw.backapisumula.identity.repo;

import com.nkw.backapisumula.identity.Profile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface ProfileRepository extends JpaRepository<Profile, UUID> {

    List<Profile> findAllByOrderByNomeExibicaoAsc();

    @Query("""
            select p
            from Profile p
            join UsuarioRoleGlobal urg on urg.userId = p.id
            where lower(urg.role) = lower(:role)
            order by p.nomeExibicao asc
            """)
    List<Profile> findByGlobalRoleOrderByNomeExibicaoAsc(@Param("role") String role);

    @Query("""
            select urg.role
            from UsuarioRoleGlobal urg
            where urg.userId = :userId
            order by urg.role asc
            """)
    List<String> findRolesByUserId(@Param("userId") UUID userId);
}
