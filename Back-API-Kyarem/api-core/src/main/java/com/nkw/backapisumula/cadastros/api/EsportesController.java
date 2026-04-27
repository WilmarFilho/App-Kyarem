package com.nkw.backapisumula.cadastros.api;

import com.nkw.backapisumula.cadastros.Esporte;
import com.nkw.backapisumula.cadastros.TipoEvento;
import com.nkw.backapisumula.cadastros.service.EsporteService;
import com.nkw.backapisumula.cadastros.service.TipoEventoService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/esportes")
public class EsportesController {

    private final EsporteService esporteService;
    private final TipoEventoService tipoEventoService;

    public EsportesController(EsporteService esporteService, TipoEventoService tipoEventoService) {
        this.esporteService = esporteService;
        this.tipoEventoService = tipoEventoService;
    }

    @GetMapping
    public List<EsporteResponse> list() {
        return esporteService.list().stream().map(EsporteResponse::from).toList();
    }

    @GetMapping("/{id}")
    public EsporteResponse get(@PathVariable UUID id) {
        return EsporteResponse.from(esporteService.getOrThrow(id));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado')")
    public EsporteResponse create(@Valid @RequestBody CreateEsporteRequest req) {
        Esporte e = esporteService.create(req.nome());
        return EsporteResponse.from(e);
    }

    @GetMapping("/{id}/tipos-eventos")
    public List<TipoEventoResponse> listTiposEventos(@PathVariable UUID id) {
        return tipoEventoService.listByEsporte(id).stream().map(TipoEventoResponse::from).toList();
    }

    @PostMapping("/{id}/tipos-eventos")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado')")
    public TipoEventoResponse createTipoEvento(@PathVariable UUID id, @Valid @RequestBody CreateTipoEventoRequest req) {
        Esporte esporte = esporteService.getOrThrow(id);
        TipoEvento te = tipoEventoService.create(esporte, req.nome());
        return TipoEventoResponse.from(te);
    }

    public record CreateEsporteRequest(@NotBlank String nome) {}
    public record CreateTipoEventoRequest(@NotBlank String nome) {}

    public record EsporteResponse(UUID id, String nome) {
        static EsporteResponse from(Esporte e) { return new EsporteResponse(e.getId(), e.getNome()); }
    }

    public record TipoEventoResponse(UUID id, UUID esporteId, String nome) {
        static TipoEventoResponse from(TipoEvento te) {
            return new TipoEventoResponse(te.getId(), te.getEsporte().getId(), te.getNome());
        }
    }
}
