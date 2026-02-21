package com.nkw.backapisumula.partidas.api;

import com.nkw.backapisumula.partidas.EventoPartida;
import com.nkw.backapisumula.partidas.service.EventoPartidaService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/partidas/{partidaId}/eventos")
public class EventosPartidaController {

    private final EventoPartidaService service;

    public EventosPartidaController(EventoPartidaService service) {
        this.service = service;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('admin','delegado','arbitro','presidente_atletica','aluno','publico_leitura')")
    public List<EventoPartidaResponse> list(@PathVariable UUID partidaId) {
        return service.list(partidaId).stream().map(EventoPartidaResponse::from).toList();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('admin','delegado','arbitro')")
    public List<EventoPartidaResponse> add(@PathVariable UUID partidaId,
                                          Authentication authentication,
                                          @AuthenticationPrincipal Jwt jwt,
                                          @NotEmpty @Valid @RequestBody List<@Valid AddEventoRequest> reqs) {

        UUID userId = UUID.fromString(jwt.getSubject());
        boolean arbitroOnly = isArbitroOnly(authentication);

        List<EventoPartidaService.AddEventoInput> inputs = reqs.stream()
                .map(r -> new EventoPartidaService.AddEventoInput(
                        r.equipeId(),
                        r.atletaId(),
                        r.tipoEventoId(),
                        r.tempoCronometro(),
                        r.descricaoDetalhada()
                ))
                .toList();

        List<EventoPartida> saved = service.addBatch(partidaId, userId, arbitroOnly, inputs);
        return saved.stream().map(EventoPartidaResponse::from).toList();
    }

    private boolean isArbitroOnly(Authentication authentication) {
        boolean isAdminOrDelegado = authentication.getAuthorities().stream().anyMatch(a ->
                a.getAuthority().equals("ROLE_admin") || a.getAuthority().equals("ROLE_delegado"));
        boolean isArbitro = authentication.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_arbitro"));
        return isArbitro && !isAdminOrDelegado;
    }

    public record AddEventoRequest(
            @NotNull UUID equipeId,
            UUID atletaId,
            @NotNull UUID tipoEventoId,
            @NotBlank String tempoCronometro,
            String descricaoDetalhada
    ) {}

    public record EventoPartidaResponse(
            UUID id,
            UUID partidaId,
            UUID equipeId,
            UUID atletaId,
            UUID tipoEventoId,
            String tempoCronometro,
            String descricaoDetalhada,
            OffsetDateTime criadoEm
    ) {
        public static EventoPartidaResponse from(EventoPartida ev) {
            return new EventoPartidaResponse(
                    ev.getId(),
                    ev.getPartida() == null ? null : ev.getPartida().getId(),
                    ev.getEquipe() == null ? null : ev.getEquipe().getId(),
                    ev.getAtleta() == null ? null : ev.getAtleta().getId(),
                    ev.getTipoEvento() == null ? null : ev.getTipoEvento().getId(),
                    ev.getTempoCronometro(),
                    ev.getDescricaoDetalhada(),
                    ev.getCriadoEm()
            );
        }
    }
}
