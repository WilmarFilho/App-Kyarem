package com.nkw.backapisumula.identity.api;

import com.nkw.backapisumula.identity.Profile;
import com.nkw.backapisumula.identity.service.ProfileService;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class MeController {

    private final ProfileService service;

    public MeController(ProfileService service) {
        this.service = service;
    }

    @GetMapping("/me")
    public MeResponse me(@AuthenticationPrincipal Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getSubject());
        Profile p = service.getOrThrow(userId);

        return new MeResponse(
                p.getId(),
                p.getNomeExibicao(),
                p.getFotoUrl(),
                p.getTelefone(),
                p.getRole()
        );
    }

    public record MeResponse(
            UUID id,
            String nomeExibicao,
            String fotoUrl,
            String telefone,
            String role
    ) {}
}
