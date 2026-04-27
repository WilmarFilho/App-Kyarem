package com.nkw.backapisumula.cadastros.api;

import com.nkw.backapisumula.cadastros.Atletica;
import com.nkw.backapisumula.cadastros.service.AtleticaService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/atleticas")
public class AtleticasController {

    private final AtleticaService service;
    private final com.nkw.backapisumula.storage.SupabaseImageUploadService imageUploadService;

    public AtleticasController(AtleticaService service, com.nkw.backapisumula.storage.SupabaseImageUploadService imageUploadService) {
        this.service = service;
        this.imageUploadService = imageUploadService;
    }

    @GetMapping
    public List<AtleticaResponse> list() {
        return service.list().stream().map(AtleticaResponse::from).toList();
    }

    @GetMapping("/{id}")
    public AtleticaResponse get(@PathVariable UUID id) {
        return AtleticaResponse.from(service.getOrThrow(id));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director','ROLE_president')")
    public AtleticaResponse create(@Valid @RequestBody CreateAtleticaRequest req) {
        Atletica a = new Atletica();
        a.setNome(req.nome());
        a.setSigla(req.sigla());
        a.setCorPrincipal(req.corPrincipal());
        a.setEscudoUrl(req.escudoUrl());
        a.setPresidenteId(req.presidenteId());
        return AtleticaResponse.from(service.create(a));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director','ROLE_president')")
    public AtleticaResponse update(@PathVariable UUID id, @Valid @RequestBody UpdateAtleticaRequest req) {
        Atletica patch = new Atletica();
        patch.setNome(req.nome());
        patch.setSigla(req.sigla());
        patch.setCorPrincipal(req.corPrincipal());
        patch.setEscudoUrl(req.escudoUrl());
        patch.setPresidenteId(req.presidenteId());
        return AtleticaResponse.from(service.update(id, patch));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director','ROLE_president')")
    public void delete(@PathVariable UUID id) {
        service.delete(id);
    }

    @PostMapping("/upload-escudo")
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director','ROLE_president')")
    public java.util.Map<String, String> uploadEscudo(@RequestParam("file") org.springframework.web.multipart.MultipartFile file) throws java.io.IOException {
        String originalName = file.getOriginalFilename();
        String ext = (originalName != null && originalName.contains("."))
                ? originalName.substring(originalName.lastIndexOf('.'))
                : ".jpg";
        String path = "atleticas/" + java.util.UUID.randomUUID() + ext;
        String contentType = file.getContentType() != null ? file.getContentType() : "image/jpeg";

        imageUploadService.uploadImage("avatars", path, file.getBytes(), contentType);
        String publicUrl = imageUploadService.getPublicUrl("avatars", path);

        return java.util.Map.of("url", publicUrl);
    }

    public record CreateAtleticaRequest(
            @NotBlank String nome,
            String sigla,
            String corPrincipal,
            String escudoUrl,
            UUID presidenteId
    ) {}

    public record UpdateAtleticaRequest(
            @NotBlank String nome,
            String sigla,
            String corPrincipal,
            String escudoUrl,
            UUID presidenteId
    ) {}

    public record AtleticaResponse(
            UUID id,
            String nome,
            String sigla,
            String corPrincipal,
            String escudoUrl,
            UUID presidenteId
    ) {
        static AtleticaResponse from(Atletica a) {
            return new AtleticaResponse(
                    a.getId(), a.getNome(), a.getSigla(),
                    a.getCorPrincipal(), a.getEscudoUrl(), a.getPresidenteId()
            );
        }
    }
}
