package com.nkw.backapisumula.identity.api;

import com.nkw.backapisumula.identity.Profile;
import com.nkw.backapisumula.identity.repo.ProfileRepository;
import com.nkw.backapisumula.identity.service.ProfileService;
import com.nkw.backapisumula.identity.service.SupabaseAdminUserService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Endpoints para listagem e criação de profiles (usuários cadastrados).
 * Usado pela tela de seleção de presidente de atlética no app admin.
 */
@RestController
@RequestMapping("/api/v1/profiles")
public class ProfilesController {

    private final ProfileService profileService;
    private final SupabaseAdminUserService adminUserService;
    private final ProfileRepository profileRepository;

    public ProfilesController(
            ProfileService profileService,
            SupabaseAdminUserService adminUserService,
            ProfileRepository profileRepository
    ) {
        this.profileService = profileService;
        this.adminUserService = adminUserService;
        this.profileRepository = profileRepository;
    }

    /**
     * Lista todos os profiles, opcionalmente filtrado por role.
     * GET /api/v1/profiles?role=presidente_atletica
     */
    @GetMapping
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado')")
    public List<ProfileResponse> list(@RequestParam(required = false) String role) {
        List<Profile> profiles = (role != null && !role.isBlank())
                ? profileService.listByRole(role)
                : profileService.listAll();
        return profiles.stream().map(ProfileResponse::from).toList();
    }

    /**
     * Cria um novo usuário no Supabase Auth com role presidente_atletica.
     * O trigger do banco cria o profile automaticamente; depois atualizamos
     * nome_exibicao e role diretamente na tabela profiles.
     *
     * POST /api/v1/profiles/criar-presidente
     */
    @PostMapping("/criar-presidente")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado')")
    public ProfileResponse criarPresidente(@Valid @RequestBody CriarPresidenteRequest req) {
        // 1. Cria o auth user via Supabase Admin API
        UUID userId = adminUserService.createAuthUser(
                req.email(),
                req.senha(),
                req.nomeExibicao(),
                "presidente_atletica"
        );

        // 2. Aguarda um breve instante para o trigger criar o profile (fallback manual)
        // Tenta buscar o profile criado pelo trigger (máximo 3 tentativas)
        Profile profile = null;
        for (int i = 0; i < 3; i++) {
            try { Thread.sleep(500); } catch (InterruptedException ignored) {}
            profile = profileRepository.findById(userId).orElse(null);
            if (profile != null) break;
        }

        // 3. Se o trigger não criou (timing), cria manualmente
        if (profile == null) {
            profile = new Profile();
            profile.setId(userId);
            profile.setNomeExibicao(req.nomeExibicao());
            profile.setRole("presidente_atletica");
            profile.setCriadoEm(OffsetDateTime.now());
            profile.setAtualizadoEm(OffsetDateTime.now());
            profileRepository.save(profile);
        } else {
            // 4. Atualiza nome e role no profile existente
            profile.setNomeExibicao(req.nomeExibicao());
            profile.setRole("presidente_atletica");
            profile.setAtualizadoEm(OffsetDateTime.now());
            profileRepository.save(profile);
        }

        return ProfileResponse.from(profile);
    }

    public record CriarPresidenteRequest(
            @NotBlank @Email String email,
            @NotBlank @Size(min = 6) String senha,
            @NotBlank String nomeExibicao
    ) {}

    public record ProfileResponse(
            UUID id,
            String nomeExibicao,
            String fotoUrl,
            String telefone,
            String role,
            OffsetDateTime criadoEm
    ) {
        public static ProfileResponse from(Profile p) {
            return new ProfileResponse(
                    p.getId(),
                    p.getNomeExibicao(),
                    p.getFotoUrl(),
                    p.getTelefone(),
                    p.getRole(),
                    p.getCriadoEm()
            );
        }
    }
}
