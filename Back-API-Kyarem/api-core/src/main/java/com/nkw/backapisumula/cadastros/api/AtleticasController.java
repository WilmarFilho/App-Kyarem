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
import org.springframework.security.core.annotation.AuthenticationPrincipal;
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
    @PreAuthorize("hasAuthority('ROLE_admin')")
    @Transactional(readOnly = true)
    public List<AtleticaResponse> list() {
        return service.list().stream().map(AtleticaResponse::from).toList();
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('ROLE_admin')")
    @Transactional(readOnly = true)
    public AtleticaResponse get(@PathVariable UUID id) {
        return AtleticaResponse.from(service.getOrThrow(id));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('ROLE_admin')")
    public AtleticaResponse create(@Valid @RequestBody CreateAtleticaRequest req) {
        Atletica a = new Atletica();
        a.setNome(req.nome());
        a.setSigla(req.sigla());
        a.setCorPrincipal(req.corPrincipal());
        a.setEscudoUrl(req.escudoUrl());
        if (req.status() != null) {
            a.setStatus(req.status());
        } else {
            a.setStatus("ATIVA");
        }
        return AtleticaResponse.from(service.create(a));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('ROLE_admin')")
    public AtleticaResponse update(@PathVariable UUID id, @Valid @RequestBody UpdateAtleticaRequest req) {
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
    @PreAuthorize("hasAuthority('ROLE_admin')")
    @Transactional(readOnly = true)
    public List<AtleticaMembroResponse> listMembros(@PathVariable UUID id) {
        return membroService.list(id).stream().map(AtleticaMembroResponse::from).toList();
    }

    @PostMapping("/{id}/membros")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('ROLE_admin')")
    public AtleticaMembroResponse associateMembro(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody AssociateAtleticaMembroRequest req
    ) {
        AtleticaMembro membro = membroService.associateExistingUser(
                id,
                req.userId(),
                req.papelCodigo(),
                UUID.fromString(jwt.getSubject())
        );
        return AtleticaMembroResponse.from(membro);
    }

    @PostMapping("/{id}/membros/criar-user")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('ROLE_admin')")
    public AtleticaMembroResponse createUserAndAssociateMembro(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody CreateAtleticaMembroUserRequest req
    ) {
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
