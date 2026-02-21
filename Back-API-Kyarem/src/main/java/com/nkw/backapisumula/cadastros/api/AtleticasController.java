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

    public AtleticasController(AtleticaService service) {
        this.service = service;
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
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado','ROLE_presidente_atletica')")
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
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado','ROLE_presidente_atletica')")
    public AtleticaResponse update(@PathVariable UUID id, @Valid @RequestBody UpdateAtleticaRequest req) {
        Atletica patch = new Atletica();
        patch.setNome(req.nome());
        patch.setSigla(req.sigla());
        patch.setCorPrincipal(req.corPrincipal());
        patch.setEscudoUrl(req.escudoUrl());
        patch.setPresidenteId(req.presidenteId());
        return AtleticaResponse.from(service.update(id, patch));
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
