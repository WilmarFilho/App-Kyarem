package com.nkw.backapisumula.identity.repo;

import com.nkw.backapisumula.identity.Profile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface ProfileRepository extends JpaRepository<Profile, UUID> {

    List<Profile> findAllByOrderByNomeExibicaoAsc();

    java.util.Optional<Profile> findByEmail(String email);


    @Query("""
            select p
            from Profile p
            join UsuarioRoleGlobal urg on urg.userId = p.id
            where lower(urg.role) = lower(:role)
            order by p.nomeExibicao asc
            """)
    List<Profile> findByGlobalRoleOrderByNomeExibicaoAsc(@Param("role") String role);

    @Query("""
            select p
            from Profile p
            where lower(p.nomeExibicao) like lower(concat('%', :query, '%'))
               or lower(p.email) like lower(concat('%', :query, '%'))
            order by p.nomeExibicao asc
            """)
    List<Profile> searchByNameOrEmail(@Param("query") String query);

    @Query("""
            select p
            from Profile p
            join QuadroArbitro qa on qa.userId = p.id
            where qa.status = 'ATIVO'
            order by p.nomeExibicao asc
            """)
    List<Profile> findRefereesOrderByNomeExibicaoAsc();

    @Query(value = """
            select role_name
            from (
                select upper(urg.role_codigo) as role_name
                from operational.usuarios_roles_globais urg
                where urg.user_id = :userId

                union

                select 'REFEREE' as role_name
                from operational.quadro_arbitros qa
                where qa.user_id = :userId
                  and qa.status = 'ATIVO'
            ) roles
            order by role_name asc
            """, nativeQuery = true)
    List<String> findRolesByUserId(@Param("userId") UUID userId);
}
