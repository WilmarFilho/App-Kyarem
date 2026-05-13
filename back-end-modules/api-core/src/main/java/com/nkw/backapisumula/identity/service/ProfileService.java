package com.nkw.backapisumula.identity.service;

import com.nkw.backapisumula.identity.Profile;
import com.nkw.backapisumula.identity.repo.ProfileRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class ProfileService {

    private final ProfileRepository repo;

    public ProfileService(ProfileRepository repo) {
        this.repo = repo;
    }

    public Profile getOrThrow(UUID userId) {
        Profile profile = repo.findById(userId)
                .orElseThrow(() -> new IllegalStateException("Profile não encontrado para o usuário logado."));
        profile.setRole(resolvePrimaryRole(repo.findRolesByUserId(userId)));
        return profile;
    }

    public List<Profile> listArbitros() {
        return hydrateRoles(repo.findRefereesOrderByNomeExibicaoAsc());
    }

    public List<Profile> listAll() {
        return hydrateRoles(repo.findAllByOrderByNomeExibicaoAsc());
    }

    public List<Profile> listByRole(String role) {
        if ("REFEREE".equalsIgnoreCase(role) || "ARBITRO_COMUM".equalsIgnoreCase(role)) {
            return listArbitros();
        }
        return hydrateRoles(repo.findByGlobalRoleOrderByNomeExibicaoAsc(role));
    }

    private List<Profile> hydrateRoles(List<Profile> profiles) {
        profiles.forEach(profile -> {
            List<String> roles = repo.findRolesByUserId(profile.getId());
            profile.setRole(resolvePrimaryRole(roles));
        });
        return profiles;
    }

    private String resolvePrimaryRole(List<String> roles) {
        if (roles == null || roles.isEmpty()) {
            return "user";
        }
        if (roles.stream().anyMatch(role -> "ADMIN_PLATAFORMA".equalsIgnoreCase(role) || "ADMIN".equalsIgnoreCase(role))) {
            return "admin";
        }
        if (roles.stream().anyMatch(role -> "DIRECTOR".equalsIgnoreCase(role) || "ORGANIZADOR".equalsIgnoreCase(role))) {
            return "director";
        }
        if (roles.stream().anyMatch(role -> "PRESIDENT".equalsIgnoreCase(role) || "PRESIDENTE_ATLETICA".equalsIgnoreCase(role))) {
            return "president";
        }
        if (roles.stream().anyMatch(role -> "ATHLETE".equalsIgnoreCase(role) || "ALUNO".equalsIgnoreCase(role))) {
            return "athlete";
        }
        if (roles.stream().anyMatch(role -> "ARBITRO_COMUM".equalsIgnoreCase(role) || "REFEREE".equalsIgnoreCase(role))) {
            return "referee";
        }
        return roles.get(0).toLowerCase();
    }

    public AccessInfo resolveAccess(UUID userId) {
        Profile profile = getOrThrow(userId);
        String role = profile.getRole();
        boolean isAdmin = "admin".equalsIgnoreCase(role);
        boolean isReferee = "referee".equalsIgnoreCase(role);
        boolean allowedAdminApp = isAdmin || isReferee;
        return new AccessInfo(profile, role, isAdmin, isReferee, allowedAdminApp);
    }

    /**
     * Verifica se o email tem permissão de acesso ao app administrativo.
     * Retorna false se o email não existir no sistema.
     */
    public boolean isEmailAllowedAdminApp(String email) {
        return repo.findByEmail(email.trim().toLowerCase()).map(profile -> {
            List<String> roles = repo.findRolesByUserId(profile.getId());
            String role = resolvePrimaryRole(roles);
            return "admin".equalsIgnoreCase(role) || "referee".equalsIgnoreCase(role);
        }).orElse(false);
    }

    public record AccessInfo(
            Profile profile,
            String role,
            boolean isAdmin,
            boolean isReferee,
            boolean allowedAdminApp
    ) {
    }
}
