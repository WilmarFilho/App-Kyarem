package com.nkw.backapisumula.identity.service;

import com.nkw.backapisumula.identity.Profile;
import com.nkw.backapisumula.identity.repo.ProfileRepository;
import org.springframework.stereotype.Service;
import java.util.UUID;

@Service
public class ProfileService {

    private final ProfileRepository repo;

    public ProfileService(ProfileRepository repo) {
        this.repo = repo;
    }

    public Profile getOrThrow(UUID userId) {
        return repo.findById(userId)
                .orElseThrow(() -> new IllegalStateException("Profile não encontrado para o usuário logado."));
    }
}
