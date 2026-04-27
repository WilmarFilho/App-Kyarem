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
        return hydrateRoles(repo.findByGlobalRoleOrderByNomeExibicaoAsc("ARBITRO_COMUM"));
    }

    public List<Profile> listAll() {
        return hydrateRoles(repo.findAllByOrderByNomeExibicaoAsc());
    }

    public List<Profile> listByRole(String role) {
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
        if (roles.stream().anyMatch(role -> "ORGANIZADOR".equalsIgnoreCase(role))) {
            return "delegado";
        }
        if (roles.stream().anyMatch(role -> "ARBITRO_COMUM".equalsIgnoreCase(role) || "REFEREE".equalsIgnoreCase(role))) {
            return "arbitro";
        }
        return roles.get(0).toLowerCase();
    }
}
