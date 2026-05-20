package com.nkw.backapisumula.cadastros.api;

import com.nkw.backapisumula.cadastros.Atletica;
import com.nkw.backapisumula.cadastros.AtleticaMembro;
import com.nkw.backapisumula.cadastros.service.AtleticaMembroService;
import com.nkw.backapisumula.cadastros.service.AtleticaService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/atleticas")
public class AtleticasController {

    private final AtleticaService service;
    private final AtleticaMembroService membroService;
    private final com.nkw.backapisumula.storage.SupabaseImageUploadService imageUploadService;

    public AtleticasController(
            AtleticaService service,
            AtleticaMembroService membroService,
            com.nkw.backapisumula.storage.SupabaseImageUploadService imageUploadService
    ) {
        this.service = service;
        this.membroService = membroService;
        this.imageUploadService = imageUploadService;
    }

    @GetMapping
    @Transactional(readOnly = true)
    public List<AtleticaResponse> list() {
        return service.list().stream().map(AtleticaResponse::from).toList();
    }

    @GetMapping("/{id}")
    @Transactional(readOnly = true)
    public AtleticaResponse get(@PathVariable UUID id) {
        return AtleticaResponse.from(service.getOrThrow(id));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('ROLE_admin')")
    public AtleticaResponse create(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody CreateAtleticaRequest req
    ) {
        Atletica a = new Atletica();
        a.setNome(req.nome());
        a.setSigla(req.sigla());
        a.setCorPrincipal(req.corPrincipal());
        a.setEscudoUrl(req.escudoUrl());
        a.setCriadoPor(UUID.fromString(jwt.getSubject()));
        if (req.status() != null) {
            a.setStatus(req.status());
        } else {
            a.setStatus("ATIVA");
        }
        return AtleticaResponse.from(service.create(a));
    }

    @GetMapping("/minhas")
    @Transactional(readOnly = true)
    public List<MinhaAtleticaResponse> listMinhas(@AuthenticationPrincipal Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getSubject());
        return membroService.listByUser(userId).stream()
                .map(MinhaAtleticaResponse::from)
                .toList();
    }

    @PutMapping("/{id}")
    public AtleticaResponse update(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody UpdateAtleticaRequest req
    ) {
        checkManagerPermission(id, jwt);

        Atletica patch = new Atletica();
        patch.setNome(req.nome());
        patch.setSigla(req.sigla());
        patch.setCorPrincipal(req.corPrincipal());
        patch.setEscudoUrl(req.escudoUrl());
        patch.setStatus(req.status());
        return AtleticaResponse.from(service.update(id, patch));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAuthority('ROLE_admin')")
    public void delete(@PathVariable UUID id) {
        service.delete(id);
    }

    @GetMapping("/{id}/membros")
    @Transactional(readOnly = true)
    public List<AtleticaMembroResponse> listMembros(@PathVariable UUID id, @AuthenticationPrincipal Jwt jwt) {
        checkManagerPermission(id, jwt);
        return membroService.list(id).stream().map(AtleticaMembroResponse::from).toList();
    }

    @PostMapping("/{id}/membros")
    @ResponseStatus(HttpStatus.CREATED)
    public AtleticaMembroResponse associateMembro(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody AssociateAtleticaMembroRequest req
    ) {
        checkManagerPermission(id, jwt);
        AtleticaMembro membro = membroService.associateExistingUser(
                id,
                req.userId(),
                req.papelCodigo(),
                UUID.fromString(jwt.getSubject())
        );
        return AtleticaMembroResponse.from(membro);
    }

    @PostMapping("/{id}/membros/associar-por-email")
    @ResponseStatus(HttpStatus.CREATED)
    public AtleticaMembroResponse associateMembroByEmail(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody AssociateMembroByEmailRequest req
    ) {
        checkManagerPermission(id, jwt);
        AtleticaMembro membro = membroService.associateExistingUserByEmail(
                id,
                req.email(),
                req.papelCodigo(),
                UUID.fromString(jwt.getSubject())
        );
        return AtleticaMembroResponse.from(membro);
    }

    @PostMapping("/{id}/membros/criar-user")
    @ResponseStatus(HttpStatus.CREATED)
    public AtleticaMembroResponse createUserAndAssociateMembro(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody CreateAtleticaMembroUserRequest req
    ) {
        checkManagerPermission(id, jwt);
        AtleticaMembro membro = membroService.createUserAndAssociate(
                id,
                req.nomeExibicao(),
                req.email(),
                req.senha(),
                req.papelCodigo(),
                UUID.fromString(jwt.getSubject())
        );
        return AtleticaMembroResponse.from(membro);
    }

    @DeleteMapping("/{id}/membros/{membroId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void removeMembro(
            @PathVariable UUID id,
            @PathVariable UUID membroId,
            @AuthenticationPrincipal Jwt jwt
    ) {
        checkManagerPermission(id, jwt);
        membroService.remove(id, membroId);
    }

    @PostMapping("/upload-escudo")
    @PreAuthorize("hasAuthority('ROLE_admin')")
    public java.util.Map<String, String> uploadEscudo(@RequestParam("file") org.springframework.web.multipart.MultipartFile file) throws java.io.IOException {
        String originalName = file.getOriginalFilename();
        String ext = (originalName != null && originalName.contains("."))
                ? originalName.substring(originalName.lastIndexOf('.'))
                : ".jpg";
        String path = java.util.UUID.randomUUID() + ext;
        String contentType = file.getContentType() != null ? file.getContentType() : "image/jpeg";

        imageUploadService.uploadImage("atleticas", path, file.getBytes(), contentType);
        String publicUrl = imageUploadService.getPublicUrl("atleticas", path);

        return java.util.Map.of("url", publicUrl);
    }

    private void checkManagerPermission(UUID id, Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getSubject());
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        boolean isAdmin = authentication != null
                && authentication.getAuthorities().stream()
                .anyMatch(authority -> "ROLE_admin".equals(authority.getAuthority()));
        
        if (!isAdmin) {
            boolean isManager = membroService.listByUser(userId).stream()
                    .anyMatch(m -> m.getAtletica() != null && m.getAtletica().getId().equals(id) && 
                            ("PRESIDENT".equalsIgnoreCase(m.getPapelCodigo()) || "DIRECTOR".equalsIgnoreCase(m.getPapelCodigo())));
            if (!isManager) {
                throw new org.springframework.security.access.AccessDeniedException("Acesso negado: você não tem permissão para gerenciar esta atlética.");
            }
        }
    }

    public record CreateAtleticaRequest(
            @NotBlank String nome,
            String sigla,
            String corPrincipal,
            String escudoUrl,
            String status
    ) {}

    public record UpdateAtleticaRequest(
            @NotBlank String nome,
            String sigla,
            String corPrincipal,
            String escudoUrl,
            String status
    ) {}

    public record AssociateAtleticaMembroRequest(
            @NotNull UUID userId,
            @NotBlank String papelCodigo
    ) {}

    public record AssociateMembroByEmailRequest(
            @NotBlank @Email String email,
            @NotBlank String papelCodigo
    ) {}

    public record CreateAtleticaMembroUserRequest(
            @NotBlank String nomeExibicao,
            @NotBlank @Email String email,
            @NotBlank @Size(min = 6) String senha,
            @NotBlank String papelCodigo
    ) {}

    public record AtleticaResponse(
            UUID id,
            String nome,
            String sigla,
            String corPrincipal,
            String escudoUrl,
            String status
    ) {
        static AtleticaResponse from(Atletica a) {
            return new AtleticaResponse(
                    a.getId(), a.getNome(), a.getSigla(),
                    a.getCorPrincipal(), a.getEscudoUrl(), a.getStatus()
            );
        }
    }

    public record MinhaAtleticaResponse(
            UUID id,
            UUID atleticaId,
            String atleticaNome,
            String atleticaEscudoUrl,
            String papelCodigo,
            String status
    ) {
        static MinhaAtleticaResponse from(AtleticaMembro m) {
            return new MinhaAtleticaResponse(
                    m.getId(),
                    m.getAtletica() != null ? m.getAtletica().getId() : null,
                    m.getAtletica() != null ? m.getAtletica().getNome() : null,
                    m.getAtletica() != null ? m.getAtletica().getEscudoUrl() : null,
                    m.getPapelCodigo(),
                    m.getStatus()
            );
        }
    }

    public record AtleticaMembroResponse(
            UUID id,
            UUID atleticaId,
            UUID userId,
            String nomeExibicao,
            String email,
            String telefone,
            String fotoUrl,
            String papelCodigo,
            String status,
            OffsetDateTime criadoEm
    ) {
        static AtleticaMembroResponse from(AtleticaMembro membro) {
            return new AtleticaMembroResponse(
                    membro.getId(),
                    membro.getAtletica() != null ? membro.getAtletica().getId() : null,
                    membro.getUser() != null ? membro.getUser().getId() : null,
                    membro.getUser() != null ? membro.getUser().getNomeExibicao() : null,
                    membro.getUser() != null ? membro.getUser().getEmail() : null,
                    membro.getUser() != null ? membro.getUser().getTelefone() : null,
                    membro.getUser() != null ? membro.getUser().getFotoUrl() : null,
                    membro.getPapelCodigo(),
                    membro.getStatus(),
                    membro.getCriadoEm()
            );
        }
    }
}
