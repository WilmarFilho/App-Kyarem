package com.nkw.backapisumula.partidas.api;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.JsonNode;
import com.nkw.backapisumula.partidas.Partida;
import com.nkw.backapisumula.partidas.service.PartidaService;
import com.nkw.backapisumula.partidas.service.SumulaOficialPdfService;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/partidas")
public class PartidasController {

    private final PartidaService service;
    private final SumulaOficialPdfService sumulaOficialPdfService;

    public PartidasController(PartidaService service, SumulaOficialPdfService sumulaOficialPdfService) {
        this.service = service;
        this.sumulaOficialPdfService = sumulaOficialPdfService;
    }

    @GetMapping("/minhas")
    @PreAuthorize("hasAnyRole('admin','arbitro')")
    public List<PartidaResponse> minhas(@AuthenticationPrincipal Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getSubject());
        return service.listByArbitro(userId).stream().map(PartidaResponse::from).toList();
    }

    @GetMapping
    public List<PartidaResponse> list(@RequestParam(required = false) UUID modalidadeId,
                                     @RequestParam(required = false) String status) {
        service.validateStatus(status);
        return service.list(modalidadeId, status == null ? null : status.trim().toLowerCase()).stream()
                .map(PartidaResponse::from)
                .toList();
    }

    @GetMapping("/{id}")
    public PartidaResponse get(@PathVariable UUID id) {
        return PartidaResponse.from(service.getOrThrow(id));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('admin','delegado','arbitro')")
    public PartidaResponse create(@Valid @RequestBody CreatePartidaRequest req) {
        Partida p = service.create(req.modalidadeId(), req.equipeAId(), req.equipeBId(), req.agendadoPara(), req.local());
        return PartidaResponse.from(p);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('admin','delegado')")
    public PartidaResponse update(@PathVariable UUID id,
                                 Authentication authentication,
                                 @AuthenticationPrincipal Jwt jwt,
                                 @Valid @RequestBody UpdatePartidaRequest req) {
        UUID userId = UUID.fromString(jwt.getSubject());
        boolean arbitroOnly = isArbitroOnly(authentication);
        Partida p = service.update(id, userId, arbitroOnly, req.modalidadeId(), req.equipeAId(), req.equipeBId(), req.agendadoPara(), req.local(), req.snapshotSumula(), req.sumulaPdfUrl());
        return PartidaResponse.from(p);
    }

    @GetMapping(value = "/{id}/sumula-oficial.pdf", produces = MediaType.APPLICATION_PDF_VALUE)
    @PreAuthorize("hasAnyRole('admin','delegado','arbitro')")
    public ResponseEntity<byte[]> getOfficialPdf(@PathVariable UUID id) {
        byte[] pdf = sumulaOficialPdfService.gerarPdf(id);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=sumula-oficial-" + id + ".pdf")
                .contentType(MediaType.APPLICATION_PDF)
                .body(pdf);
    }

    @PostMapping("/{id}/start")
    @PreAuthorize("hasAnyRole('admin','delegado','arbitro')")
    public PartidaResponse start(@PathVariable UUID id,
                                 Authentication authentication,
                                 @AuthenticationPrincipal Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getSubject());
        boolean arbitroOnly = isArbitroOnly(authentication);
        return PartidaResponse.from(service.start(id, userId, arbitroOnly));
    }

    @PostMapping("/{id}/end")
    @PreAuthorize("hasAnyRole('admin','delegado','arbitro')")
    public PartidaResponse end(@PathVariable UUID id,
                               Authentication authentication,
                               @AuthenticationPrincipal Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getSubject());
        boolean arbitroOnly = isArbitroOnly(authentication);
        return PartidaResponse.from(service.end(id, userId, arbitroOnly));
    }


    @PatchMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('admin','delegado','arbitro')")
    public PartidaResponse updateStatus(@PathVariable UUID id,
                                        Authentication authentication,
                                        @AuthenticationPrincipal Jwt jwt,
                                        @Valid @RequestBody UpdateStatusRequest req) {
        UUID userId = UUID.fromString(jwt.getSubject());
        boolean arbitroOnly = isArbitroOnly(authentication);
        Partida p = service.updateStatus(id, userId, arbitroOnly, req.status(), req.statusAntesPausa());
        return PartidaResponse.from(p);
    }

    private boolean isArbitroOnly(Authentication authentication) {
        boolean isAdminOrDelegado = authentication.getAuthorities().stream().anyMatch(a ->
                a.getAuthority().equals("ROLE_admin") || a.getAuthority().equals("ROLE_delegado"));
        boolean isArbitro = authentication.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_arbitro"));
        return isArbitro && !isAdminOrDelegado;
    }

    public record CreatePartidaRequest(
            @NotNull UUID modalidadeId,
            @NotNull UUID equipeAId,
            @NotNull UUID equipeBId,
            OffsetDateTime agendadoPara,
            String local
    ) {}

    public record UpdatePartidaRequest(
            UUID modalidadeId,
            UUID equipeAId,
            UUID equipeBId,
            OffsetDateTime agendadoPara,
            String local,
            JsonNode snapshotSumula,
            String sumulaPdfUrl
    ) {}

    public record UpdateStatusRequest(
            @Schema(
                    description = "Novo status da partida.",
                    example = "pausada"
            )
            @NotBlank String status,

            @Schema(
                    description = "Status imediatamente anterior à pausa (usado quando status=pausada).",
                    example = "2° tempo"
            )
            @JsonProperty("status_antes_pausa") String statusAntesPausa
    ) {}



    public record PartidaResponse(
            UUID id,
            UUID modalidadeId,
            UUID equipeAId,
            UUID equipeBId,
            String status,
            OffsetDateTime agendadoPara,
            OffsetDateTime iniciadaEm,
            OffsetDateTime encerradaEm,
            String local,
            Integer placarA,
            Integer placarB,
            JsonNode snapshotSumula,
            String sumulaPdfUrl,
            String hashIntegridade,
            @JsonProperty("status_antes_pausa") String statusAntesPausa
    ) {
        public static PartidaResponse from(Partida p) {
            return new PartidaResponse(
                    p.getId(),
                    p.getModalidade() == null ? null : p.getModalidade().getId(),
                    p.getEquipeA() == null ? null : p.getEquipeA().getId(),
                    p.getEquipeB() == null ? null : p.getEquipeB().getId(),
                    p.getStatus(),
                    p.getAgendadoPara(),
                    p.getIniciadaEm(),
                    p.getEncerradaEm(),
                    p.getLocal(),
                    p.getPlacarA(),
                    p.getPlacarB(),
                    p.getSnapshotSumula(),
                    p.getSumulaPdfUrl(),
                    p.getHashIntegridade(),
                    p.getStatusAntesPausa()
            );
        }
    }
}
