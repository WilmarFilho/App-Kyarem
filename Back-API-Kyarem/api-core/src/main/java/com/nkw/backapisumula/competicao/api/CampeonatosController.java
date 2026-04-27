package com.nkw.backapisumula.competicao.api;

import com.nkw.backapisumula.competicao.Campeonato;
import com.nkw.backapisumula.competicao.service.CampeonatoService;
import com.nkw.backapisumula.storage.SupabaseImageUploadService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/campeonatos")
public class CampeonatosController {

    private final CampeonatoService service;
    private final SupabaseImageUploadService imageUploadService;

    public CampeonatosController(CampeonatoService service, SupabaseImageUploadService imageUploadService) {
        this.service = service;
        this.imageUploadService = imageUploadService;
    }

    @GetMapping
    public List<CampeonatoResponse> list() {
        return service.list().stream().map(CampeonatoResponse::from).toList();
    }

    @GetMapping("/{id}")
    public CampeonatoResponse get(@PathVariable UUID id) {
        return CampeonatoResponse.from(service.getOrThrow(id));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director')")
    public CampeonatoResponse create(@Valid @RequestBody CreateCampeonatoRequest r) {
        Campeonato c = new Campeonato();
        c.setNome(r.nome());
        c.setNivel(r.nivel());
        c.setDataInicio(r.dataInicio());
        c.setDataFim(r.dataFim());
        c.setEscudoUrl(r.escudoUrl());
        return CampeonatoResponse.from(service.create(c));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director')")
    public CampeonatoResponse update(@PathVariable UUID id, @Valid @RequestBody UpdateCampeonatoRequest r) {
        Campeonato patch = new Campeonato();
        patch.setNome(r.nome());
        patch.setNivel(r.nivel());
        patch.setDataInicio(r.dataInicio());
        patch.setDataFim(r.dataFim());
        patch.setEscudoUrl(r.escudoUrl());
        return CampeonatoResponse.from(service.update(id, patch));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director')")
    public void delete(@PathVariable UUID id) {
        service.delete(id);
    }

    @PostMapping("/upload-escudo")
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director')")
    public Map<String, String> uploadEscudo(@RequestParam("file") MultipartFile file) throws IOException {
        String originalName = file.getOriginalFilename();
        String ext = (originalName != null && originalName.contains("."))
                ? originalName.substring(originalName.lastIndexOf('.'))
                : ".jpg";
        String path = "campeonatos/" + UUID.randomUUID() + ext;
        String contentType = file.getContentType() != null ? file.getContentType() : "image/jpeg";

        imageUploadService.uploadImage("avatars", path, file.getBytes(), contentType);
        String publicUrl = imageUploadService.getPublicUrl("avatars", path);

        return Map.of("url", publicUrl);
    }

    public record CreateCampeonatoRequest(
            @NotBlank String nome,
            String nivel,
            LocalDate dataInicio,
            LocalDate dataFim,
            String escudoUrl
    ) {}

    public record UpdateCampeonatoRequest(
            String nome,
            String nivel,
            LocalDate dataInicio,
            LocalDate dataFim,
            String escudoUrl
    ) {}

    public record CampeonatoResponse(
            UUID id,
            String nome,
            String nivel,
            LocalDate dataInicio,
            LocalDate dataFim,
            String escudoUrl
    ) {
        public static CampeonatoResponse from(Campeonato c) {
            return new CampeonatoResponse(
                    c.getId(),
                    c.getNome(),
                    c.getNivel(),
                    c.getDataInicio(),
                    c.getDataFim(),
                    c.getEscudoUrl()
            );
        }
    }
}
