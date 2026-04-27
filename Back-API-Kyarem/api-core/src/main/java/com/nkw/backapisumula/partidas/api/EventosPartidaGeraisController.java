package com.nkw.backapisumula.partidas.api;

import com.nkw.backapisumula.partidas.EventoPartida;
import com.nkw.backapisumula.partidas.service.EventoPartidaService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/partidas/{partidaId}/eventos-gerais")
public class EventosPartidaGeraisController {

    private final EventoPartidaService service;

    public EventosPartidaGeraisController(EventoPartidaService service) {
        this.service = service;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('admin','director','referee')")
    public List<EventosPartidaController.EventoPartidaResponse> add(@PathVariable UUID partidaId,
                                                                    Authentication authentication,
                                                                    @AuthenticationPrincipal Jwt jwt,
                                                                    @NotEmpty @Valid @RequestBody List<@Valid AddEventoGeralRequest> reqs) {

        UUID userId = UUID.fromString(jwt.getSubject());
        boolean arbitroOnly = isArbitroOnly(authentication);

        List<EventoPartidaService.AddEventoGeralInput> inputs = reqs.stream()
                .map(r -> new EventoPartidaService.AddEventoGeralInput(
                        r.tipoEventoId(),
                        r.tempoCronometro(),
                        r.descricaoDetalhada(),
                        r.localEventoId(),
                        r.equipeId()
                ))
                .toList();

        List<EventoPartida> saved = service.addBatchGerais(partidaId, userId, arbitroOnly, inputs);
        return saved.stream().map(EventosPartidaController.EventoPartidaResponse::from).toList();
    }

    private boolean isArbitroOnly(Authentication authentication) {
        boolean isAdminOrDirector = authentication.getAuthorities().stream().anyMatch(a ->
                a.getAuthority().equals("ROLE_admin") || a.getAuthority().equals("ROLE_director"));
        boolean isReferee = authentication.getAuthorities().stream().anyMatch(a ->
                a.getAuthority().equals("ROLE_referee"));
        return isReferee && !isAdminOrDirector;
    }

    public record AddEventoGeralRequest(
            @NotNull UUID tipoEventoId,
            @NotBlank String tempoCronometro,
            String descricaoDetalhada,
            String localEventoId,
            UUID equipeId
    ) {}
}
