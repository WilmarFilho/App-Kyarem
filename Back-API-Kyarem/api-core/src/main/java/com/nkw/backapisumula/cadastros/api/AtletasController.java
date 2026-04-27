package com.nkw.backapisumula.cadastros.api;

import com.nkw.backapisumula.cadastros.Atleta;
import com.nkw.backapisumula.cadastros.Atletica;
import com.nkw.backapisumula.cadastros.service.AtletaService;
import com.nkw.backapisumula.cadastros.service.AtleticaService;
import com.nkw.backapisumula.storage.SupabaseImageUploadService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/atletas")
public class AtletasController {

    private final AtletaService atletaService;
    private final AtleticaService atleticaService;
    private final SupabaseImageUploadService imageUploadService;

    public AtletasController(AtletaService atletaService, AtleticaService atleticaService,
                             SupabaseImageUploadService imageUploadService) {
        this.atletaService = atletaService;
        this.atleticaService = atleticaService;
        this.imageUploadService = imageUploadService;
    }

    @GetMapping
    public List<AtletaResponse> list(@RequestParam UUID atleticaId) {
        return atletaService.listByAtletica(atleticaId).stream().map(AtletaResponse::from).toList();
    }

    @GetMapping("/{id}")
    public AtletaResponse get(@PathVariable UUID id) {
        return AtletaResponse.from(atletaService.getOrThrow(id));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado','ROLE_presidente_atletica')")
    public AtletaResponse create(@Valid @RequestBody CreateAtletaRequest req) {
        Atletica atletica = atleticaService.getOrThrow(req.atleticaId());
        Atleta a = atletaService.create(atletica, req.nome(), req.fotoUrl());
        return AtletaResponse.from(a);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado','ROLE_presidente_atletica')")
    public AtletaResponse update(@PathVariable UUID id, @Valid @RequestBody UpdateAtletaRequest req) {
        return AtletaResponse.from(atletaService.update(id, req.nome()));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado','ROLE_presidente_atletica')")
    public void delete(@PathVariable UUID id) {
        atletaService.delete(id);
    }

    @PostMapping("/upload-foto")
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado','ROLE_presidente_atletica')")
    public Map<String, String> uploadFoto(@RequestParam("file") MultipartFile file) throws IOException {
        String originalName = file.getOriginalFilename();
        String ext = (originalName != null && originalName.contains("."))
                ? originalName.substring(originalName.lastIndexOf('.'))
                : ".jpg";
        String path = "atletas/" + UUID.randomUUID() + ext;
        String contentType = file.getContentType() != null ? file.getContentType() : "image/jpeg";

        imageUploadService.uploadImage("avatars", path, file.getBytes(), contentType);
        String publicUrl = imageUploadService.getPublicUrl("avatars", path);

        return Map.of("url", publicUrl);
    }

    public record CreateAtletaRequest(@NotNull UUID atleticaId, @NotBlank String nome, String fotoUrl) {}
    public record UpdateAtletaRequest(@NotBlank String nome) {}

    public record AtletaResponse(UUID id, UUID atleticaId, String nome, String fotoUrl) {
        static AtletaResponse from(Atleta a) {
            UUID atleticaId = a.getAtletica() != null ? a.getAtletica().getId() : null;
            return new AtletaResponse(a.getId(), atleticaId, a.getNome(), a.getFotoUrl());
        }
    }
}

