package com.nkw.backapisumula.partidas.api;

import com.nkw.backapisumula.partidas.PartidaArbitro;
import com.nkw.backapisumula.partidas.service.PartidaArbitroService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/partidas/{partidaId}/arbitros")
public class PartidaArbitrosController {

    private final PartidaArbitroService service;

    public PartidaArbitrosController(PartidaArbitroService service) {
        this.service = service;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('admin','director','referee')")
    public List<PartidaArbitroResponse> list(@PathVariable UUID partidaId) {
        return service.list(partidaId).stream().map(PartidaArbitroResponse::from).toList();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('admin','director','referee')")
    public PartidaArbitroResponse add(@PathVariable UUID partidaId, 
                                      @Valid @RequestBody AddArbitroRequest req,
                                      @AuthenticationPrincipal Jwt jwt) {
        UUID actionUserId = UUID.fromString(jwt.getSubject());
        PartidaArbitro pa = service.add(partidaId, req.arbitroId(), req.funcao(), actionUserId);
        return PartidaArbitroResponse.from(pa);
    }

    @DeleteMapping("/{partidaArbitroId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAnyRole('admin','director','referee')")
    public void remove(@PathVariable UUID partidaId, 
                       @PathVariable UUID partidaArbitroId,
                       @AuthenticationPrincipal Jwt jwt) {
        UUID actionUserId = UUID.fromString(jwt.getSubject());
        // partidaId está no path por consistência; remoção usa o id do vínculo
        service.remove(partidaArbitroId, actionUserId);
    }

    public record AddArbitroRequest(
            @NotNull UUID arbitroId,
            @NotBlank String funcao
    ) {}

    public record PartidaArbitroResponse(
            UUID id,
            UUID partidaId,
            UUID arbitroId,
            String funcao,
            OffsetDateTime criadoEm
    ) {
        public static PartidaArbitroResponse from(PartidaArbitro pa) {
            return new PartidaArbitroResponse(
                    pa.getId(),
                    pa.getPartida() == null ? null : pa.getPartida().getId(),
                    pa.getArbitro() == null ? null : pa.getArbitro().getId(),
                    pa.getFuncao(),
                    pa.getCriadoEm()
            );
        }
    }
}
