package com.nkw.backapisumula.competicao.api;

import com.nkw.backapisumula.competicao.Campeonato;
import com.nkw.backapisumula.competicao.service.CampeonatoService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/campeonatos")
public class CampeonatosController {

    private final CampeonatoService service;

    public CampeonatosController(CampeonatoService service) {
        this.service = service;
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
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado')")
    public CampeonatoResponse create(@Valid @RequestBody CreateCampeonatoRequest r) {
        Campeonato c = new Campeonato();
        c.setNome(r.nome());
        c.setNivelCampeonato(r.nivelCampeonato());
        c.setDataInicio(r.dataInicio());
        c.setDataFim(r.dataFim());
        return CampeonatoResponse.from(service.create(c));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado')")
    public CampeonatoResponse update(@PathVariable UUID id, @Valid @RequestBody UpdateCampeonatoRequest r) {
        Campeonato patch = new Campeonato();
        patch.setNome(r.nome());
        patch.setNivelCampeonato(r.nivelCampeonato());
        patch.setDataInicio(r.dataInicio());
        patch.setDataFim(r.dataFim());
        return CampeonatoResponse.from(service.update(id, patch));
    }

    public record CreateCampeonatoRequest(
            @NotBlank String nome,
            String nivelCampeonato,
            LocalDate dataInicio,
            LocalDate dataFim
    ) {}

    public record UpdateCampeonatoRequest(
            String nome,
            String nivelCampeonato,
            LocalDate dataInicio,
            LocalDate dataFim
    ) {}

    public record CampeonatoResponse(
            UUID id,
            String nome,
            String nivelCampeonato,
            LocalDate dataInicio,
            LocalDate dataFim
    ) {
        public static CampeonatoResponse from(Campeonato c) {
            return new CampeonatoResponse(
                    c.getId(),
                    c.getNome(),
                    c.getNivelCampeonato(),
                    c.getDataInicio(),
                    c.getDataFim()
            );
        }
    }
}
