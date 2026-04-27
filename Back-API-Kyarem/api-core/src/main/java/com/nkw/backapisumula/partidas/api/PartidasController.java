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
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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
    @PreAuthorize("hasAnyRole('admin','referee')")
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
    @PreAuthorize("hasAnyRole('admin','director','referee')")
    public PartidaResponse create(@Valid @RequestBody CreatePartidaRequest req) {
        Partida p = service.create(req.modalidadeId(), req.equipeAId(), req.equipeBId(), req.agendadoPara(), req.local(), req.categoria(), req.fase());
        return PartidaResponse.from(p);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('admin','director','referee')")
    public PartidaResponse update(@PathVariable UUID id,
                                 Authentication authentication,
                                 @AuthenticationPrincipal Jwt jwt,
                                 @Valid @RequestBody UpdatePartidaRequest req) {
        UUID userId = UUID.fromString(jwt.getSubject());
        boolean arbitroOnly = isArbitroOnly(authentication);
        Partida p = service.update(id, userId, arbitroOnly, req.modalidadeId(), req.equipeAId(), req.equipeBId(), req.agendadoPara(), req.local(), req.snapshotSumula(), req.sumulaPdfUrl(), req.categoria(), req.fase());
        return PartidaResponse.from(p);
    }

    @GetMapping(value = "/{id}/sumula-oficial.pdf", produces = MediaType.APPLICATION_PDF_VALUE)
    @PreAuthorize("hasAnyRole('admin','director','referee')")
    public ResponseEntity<byte[]> getOfficialPdf(@PathVariable UUID id) {
        byte[] pdf = sumulaOficialPdfService.gerarPdf(id);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=sumula-oficial-" + id + ".pdf")
                .contentType(MediaType.APPLICATION_PDF)
                .body(pdf);
    }

    @PostMapping("/{id}/start")
    @PreAuthorize("hasAnyRole('admin','director','referee')")
    public PartidaResponse start(@PathVariable UUID id,
                                 Authentication authentication,
                                 @AuthenticationPrincipal Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getSubject());
        boolean arbitroOnly = isArbitroOnly(authentication);
        return PartidaResponse.from(service.start(id, userId, arbitroOnly));
    }

    @PostMapping("/{id}/end")
    @PreAuthorize("hasAnyRole('admin','director','referee')")
    public PartidaResponse end(@PathVariable UUID id,
                               Authentication authentication,
                               @AuthenticationPrincipal Jwt jwt) {
        UUID userId = UUID.fromString(jwt.getSubject());
        boolean arbitroOnly = isArbitroOnly(authentication);
        return PartidaResponse.from(service.end(id, userId, arbitroOnly));
    }


    @PatchMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('admin','director','referee')")
    public PartidaResponse updateStatus(@PathVariable UUID id,
                                        Authentication authentication,
                                        @AuthenticationPrincipal Jwt jwt,
                                        @Valid @RequestBody UpdateStatusRequest req) {
        UUID userId = UUID.fromString(jwt.getSubject());
        boolean arbitroOnly = isArbitroOnly(authentication);
        Partida p = service.updateStatus(id, userId, arbitroOnly, req.status(), req.statusAntesPausa());
        return PartidaResponse.from(p);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAnyRole('admin','director')")
    public void delete(@PathVariable UUID id) {
        service.delete(id);
    }

    private boolean isArbitroOnly(Authentication authentication) {
        boolean isAdminOrDirector = authentication.getAuthorities().stream().anyMatch(a ->
                a.getAuthority().equals("ROLE_admin") || a.getAuthority().equals("ROLE_director"));
        boolean isReferee = authentication.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_referee"));
        return isReferee && !isAdminOrDirector;
    }

    public record CreatePartidaRequest(
            @NotNull UUID modalidadeId,
            @NotNull UUID equipeAId,
            @NotNull UUID equipeBId,
            OffsetDateTime agendadoPara,
            String local,
            String categoria,
            String fase
    ) {}

    public record UpdatePartidaRequest(
            UUID modalidadeId,
            UUID equipeAId,
            UUID equipeBId,
            OffsetDateTime agendadoPara,
            String local,
            JsonNode snapshotSumula,
            String sumulaPdfUrl,
            String categoria,
            String fase
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
            String modalidadeNome,
            String status,
            OffsetDateTime agendadoPara,
            OffsetDateTime iniciadaEm,
            OffsetDateTime encerradaEm,
            String local,
            String categoria,
            String fase,
            Integer placarA,
            Integer placarB,
            Map<String, Object> equipeA,
            Map<String, Object> equipeB,
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
                    p.getModalidade() != null && p.getModalidade().getModalidade() != null ? p.getModalidade().getModalidade().getNome() : null,
                    p.getStatus(),
                    p.getAgendadoPara(),
                    p.getIniciadaEm(),
                    p.getEncerradaEm(),
                    p.getLocal(),
                    p.getCategoria(),
                    p.getFase(),
                    p.getPlacarA(),
                    p.getPlacarB(),
                    toEquipeMap(p.getEquipeA()),
                    toEquipeMap(p.getEquipeB()),
                    p.getSnapshotSumula(),
                    p.getSumulaPdfUrl(),
                    p.getHashIntegridade(),
                    p.getStatusAntesPausa()
            );
        }

        private static Map<String, Object> toEquipeMap(com.nkw.backapisumula.competicao.CampeonatoTime equipe) {
            if (equipe == null || equipe.getTime() == null) {
                return null;
            }

            Map<String, Object> payload = new HashMap<>();
            payload.put("id", equipe.getId());
            payload.put("nome", equipe.getNomeEquipe());
            if (equipe.getTime().getAtletica() != null) {
                payload.put("atleticaId", equipe.getTime().getAtletica().getId());
                payload.put("atleticaNome", equipe.getTime().getAtletica().getNome());
                payload.put("atleticaEscudoUrl", equipe.getTime().getAtletica().getEscudoUrl());
            }
            return payload;
        }
    }
}
