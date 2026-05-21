package com.nkw.backapisumula.identity.api;

import com.nkw.backapisumula.common.outbox.EventPublisherService;
import com.nkw.backapisumula.identity.Profile;
import com.nkw.backapisumula.identity.UsuarioRoleGlobal;
import com.nkw.backapisumula.identity.repo.ProfileRepository;
import com.nkw.backapisumula.identity.repo.UsuarioRoleGlobalRepository;
import com.nkw.backapisumula.identity.service.ProfileService;
import com.nkw.backapisumula.identity.service.SupabaseAdminUserService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
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
    private final UsuarioRoleGlobalRepository usuarioRoleGlobalRepository;
    private final EventPublisherService eventPublisherService;

    public ProfilesController(
            ProfileService profileService,
            SupabaseAdminUserService adminUserService,
            ProfileRepository profileRepository,
            UsuarioRoleGlobalRepository usuarioRoleGlobalRepository,
            EventPublisherService eventPublisherService
    ) {
        this.profileService = profileService;
        this.adminUserService = adminUserService;
        this.profileRepository = profileRepository;
        this.usuarioRoleGlobalRepository = usuarioRoleGlobalRepository;
        this.eventPublisherService = eventPublisherService;
    }

    @GetMapping("/me/access")
    @PreAuthorize("isAuthenticated()")
    public AccessResponse myAccess(@AuthenticationPrincipal Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getSubject());
        var access = profileService.resolveAccess(userId);
        return AccessResponse.from(access);
    }

    /**
     * Verifica se um e-mail pertence a um usuário com acesso ao app admin.
     * Endpoint público (sem autenticação) — retorna apenas true/false.
     * GET /api/v1/profiles/check-admin-access?email=...
     */
    @GetMapping("/check-admin-access")
    public AdminAccessCheckResponse checkAdminAccess(@RequestParam @Email String email) {
        boolean allowed = profileService.isEmailAllowedAdminApp(email);
        return new AdminAccessCheckResponse(allowed);
    }

    public record AdminAccessCheckResponse(boolean allowed) {}

    /** Atualiza nome de exibição e telefone do usuário autenticado. */
    @PutMapping("/me")
    @PreAuthorize("isAuthenticated()")
    @Transactional
    public AccessResponse updateMe(
            @AuthenticationPrincipal Jwt jwt,
            @RequestBody UpdateMeRequest req
    ) {
        UUID userId = UUID.fromString(jwt.getSubject());
        Profile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new IllegalStateException("Perfil não encontrado."));

        if (req.nomeExibicao() != null && !req.nomeExibicao().isBlank()) {
            profile.setNomeExibicao(req.nomeExibicao().trim());
        }
        if (req.telefone() != null) {
            profile.setTelefone(req.telefone().isBlank() ? null : req.telefone().trim());
        }
        if (req.cpf() != null) {
            String cpfNormalizado = req.cpf().replaceAll("\\D", "");
            profile.setCpf(cpfNormalizado.isBlank() ? null : cpfNormalizado);
        }
        if (req.dataNascimento() != null) {
            profile.setDataNascimento(req.dataNascimento());
        }
        if (req.genero() != null) {
            profile.setGenero(req.genero().isBlank() ? null : req.genero().trim());
        }
        if (req.avatarUrl() != null) {
            String url = req.avatarUrl().isBlank() ? null : req.avatarUrl().trim();
            profile.setFotoUrl(url);
        }
        profile.setAtualizadoEm(OffsetDateTime.now());
        profileRepository.save(profile);
        publishProfileProjection(profile, "ProfileAtualizado");

        var access = profileService.resolveAccess(userId);
        return AccessResponse.from(access);
    }

    public record UpdateMeRequest(String nomeExibicao, String telefone, String cpf, String avatarUrl, LocalDate dataNascimento, String genero) {}

    /** Atualiza apenas o avatar do usuário autenticado. */
    @PatchMapping("/me/avatar")
    @PreAuthorize("isAuthenticated()")
    @Transactional
    public AccessResponse updateAvatar(
            @AuthenticationPrincipal Jwt jwt,
            @RequestBody UpdateAvatarRequest req
    ) {
        UUID userId = UUID.fromString(jwt.getSubject());
        Profile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new IllegalStateException("Perfil não encontrado."));

        profile.setFotoUrl(req.avatarUrl());
        profile.setAtualizadoEm(OffsetDateTime.now());
        profileRepository.save(profile);
        publishProfileProjection(profile, "ProfileAtualizado");

        var access = profileService.resolveAccess(userId);
        return AccessResponse.from(access);
    }

    public record UpdateAvatarRequest(String avatarUrl) {}

    /** Obtém as preferências de notificação do usuário autenticado. */
    @GetMapping("/me/notifications/prefs")
    @PreAuthorize("isAuthenticated()")
    public NotificationPrefsResponse getNotifPrefs(@AuthenticationPrincipal Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getSubject());
        Profile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new IllegalStateException("Perfil não encontrado."));

        return new NotificationPrefsResponse(
                profile.getNotifTodasPartidas() != null ? profile.getNotifTodasPartidas() : true,
                profile.getNotifMinhasPartidas() != null ? profile.getNotifMinhasPartidas() : true,
                profile.getFcmToken()
        );
    }

    /** Atualiza as preferências de notificação. */
    @PatchMapping("/me/notifications/prefs")
    @PreAuthorize("isAuthenticated()")
    @Transactional
    public NotificationPrefsResponse updateNotifPrefs(
            @AuthenticationPrincipal Jwt jwt,
            @RequestBody UpdateNotifPrefsRequest req
    ) {
        UUID userId = UUID.fromString(jwt.getSubject());
        Profile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new IllegalStateException("Perfil não encontrado."));

        if (req.notifTodasPartidas() != null) profile.setNotifTodasPartidas(req.notifTodasPartidas());
        if (req.notifMinhasPartidas() != null) profile.setNotifMinhasPartidas(req.notifMinhasPartidas());

        profile.setAtualizadoEm(OffsetDateTime.now());
        profileRepository.save(profile);

        return new NotificationPrefsResponse(
                profile.getNotifTodasPartidas(),
                profile.getNotifMinhasPartidas(),
                profile.getFcmToken()
        );
    }

    /** Atualiza o token FCM (pode ser null para limpar ao fazer logout). */
    @PatchMapping("/me/notifications/token")
    @PreAuthorize("isAuthenticated()")
    @Transactional
    public void updateFcmToken(
            @AuthenticationPrincipal Jwt jwt,
            @RequestBody UpdateFcmTokenRequest req
    ) {
        UUID userId = UUID.fromString(jwt.getSubject());
        Profile profile = profileRepository.findById(userId)
                .orElseThrow(() -> new IllegalStateException("Perfil não encontrado."));

        profile.setFcmToken(req.fcmToken());
        profile.setAtualizadoEm(OffsetDateTime.now());
        profileRepository.save(profile);
    }

    public record UpdateNotifPrefsRequest(Boolean notifTodasPartidas, Boolean notifMinhasPartidas) {}
    public record NotificationPrefsResponse(Boolean notifTodasPartidas, Boolean notifMinhasPartidas, String fcmToken) {}
    public record UpdateFcmTokenRequest(String fcmToken) {}

    /**
     * Lista todos os profiles, opcionalmente filtrado por role.
     * GET /api/v1/profiles?role=president
     */
    @GetMapping
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director')")
    public List<ProfileResponse> list(@RequestParam(required = false) String role) {
        List<Profile> profiles = (role != null && !role.isBlank())
                ? profileService.listByRole(role)
                : profileService.listAll();
        return profiles.stream().map(ProfileResponse::from).toList();
    }

    /**
     * Busca perfis por nome de exibição ou email.
     * GET /api/v1/profiles/search?query=...
     */
    @GetMapping("/search")
    @PreAuthorize("isAuthenticated()")
    public List<ProfileResponse> searchProfiles(@RequestParam String query) {
        if (query == null || query.isBlank()) {
            return List.of();
        }
        List<Profile> profiles = profileService.searchByNameOrEmail(query);
        return profiles.stream().limit(50).map(ProfileResponse::from).toList();
    }

    /**
     * Cria um novo usuário base no Supabase Auth.
     * Pela nova arquitetura, o cadastro nasce como USER e os papéis
     * contextuais são atribuídos posteriormente.
     *
     * POST /api/v1/profiles/criar-presidente
     */
    @PostMapping("/criar-presidente")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director')")
    @Transactional
    public ProfileResponse criarPresidente(@Valid @RequestBody CriarPresidenteRequest req) {
        // 1. Cria o auth user via Supabase Admin API
        UUID userId = adminUserService.createAuthUser(
                req.email(),
                req.senha(),
                req.nomeExibicao(),
                null,
                "USER"
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
            profile.setStatus("ATIVO");
            profile.setCriadoEm(OffsetDateTime.now());
            profile.setAtualizadoEm(OffsetDateTime.now());
            profileRepository.save(profile);
        } else {
            // 4. Atualiza dados básicos do profile existente
            profile.setNomeExibicao(req.nomeExibicao());
            profile.setStatus("ATIVO");
            profile.setAtualizadoEm(OffsetDateTime.now());
            profileRepository.save(profile);
        }

        if (!usuarioRoleGlobalRepository.existsByUserIdAndRole(userId, "USER")) {
            UsuarioRoleGlobal role = new UsuarioRoleGlobal();
            role.setUserId(userId);
            role.setRole("USER");
            role.setCriadoEm(OffsetDateTime.now());
            usuarioRoleGlobalRepository.save(role);
        }

        profile.setRole("user");
        publishProfileProjection(profile, "ProfileCriado");

        return ProfileResponse.from(profile);
    }

    private void publishProfileProjection(Profile profile, String eventType) {
        eventPublisherService.publish("Profile", profile.getId().toString(), eventType, java.util.Map.of(
                "profileId", profile.getId().toString(),
                "status", profile.getStatus() == null ? "" : profile.getStatus()
        ));
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
            String cpf,
            LocalDate dataNascimento,
            String genero,
            String role,
            OffsetDateTime criadoEm
    ) {
        public static ProfileResponse from(Profile p) {
            return new ProfileResponse(
                    p.getId(),
                    p.getNomeExibicao(),
                    p.getFotoUrl(),
                    p.getTelefone(),
                    p.getCpf(),
                    p.getDataNascimento(),
                    p.getGenero(),
                    p.getRole(),
                    p.getCriadoEm()
            );
        }
    }

    public record AccessResponse(
            UUID id,
            String nomeExibicao,
            String fotoUrl,
            String telefone,
            String email,
            String cpf,
            LocalDate dataNascimento,
            String genero,
            String role,
            boolean isAdmin,
            boolean isReferee,
            boolean allowedAdminApp
    ) {
        public static AccessResponse from(ProfileService.AccessInfo access) {
            Profile p = access.profile();
            return new AccessResponse(
                    p.getId(),
                    p.getNomeExibicao(),
                    p.getFotoUrl(),
                    p.getTelefone(),
                    p.getEmail(),
                    p.getCpf(),
                    p.getDataNascimento(),
                    p.getGenero(),
                    access.role(),
                    access.isAdmin(),
                    access.isReferee(),
                    access.allowedAdminApp()
            );
        }
    }
}
