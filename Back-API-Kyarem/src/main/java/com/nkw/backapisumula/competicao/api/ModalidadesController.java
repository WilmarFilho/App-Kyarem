package com.nkw.backapisumula.competicao.api;

import com.fasterxml.jackson.databind.JsonNode;
import com.nkw.backapisumula.competicao.Modalidade;
import com.nkw.backapisumula.competicao.service.ModalidadeService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import io.swagger.v3.oas.annotations.media.Schema;
import com.nkw.backapisumula.shared.validation.JsonObject;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
public class ModalidadesController {

    private final ModalidadeService service;

    public ModalidadesController(ModalidadeService service) {
        this.service = service;
    }

    @GetMapping("/api/v1/campeonatos/{campeonatoId}/modalidades")
    public List<ModalidadeResponse> listByCampeonato(@PathVariable UUID campeonatoId) {
        return service.listByCampeonato(campeonatoId).stream().map(ModalidadeResponse::from).toList();
    }

    @GetMapping("/api/v1/modalidades/{id}")
    public ModalidadeResponse get(@PathVariable UUID id) {
        return ModalidadeResponse.from(service.getOrThrow(id));
    }

    @PostMapping("/api/v1/modalidades")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado')")
    public ModalidadeResponse create(@Valid @RequestBody CreateModalidadeRequest r) {
        Modalidade m = new Modalidade();
        m.setNome(r.nome());
        m.setTempoPartidaMinutos(r.tempoPartidaMinutos());
        m.setRegrasJson(r.regrasJson());
        return ModalidadeResponse.from(service.create(r.campeonatoId(), r.esporteId(), m));
    }

    @PutMapping("/api/v1/modalidades/{id}")
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado')")
    public ModalidadeResponse update(@PathVariable UUID id, @Valid @RequestBody UpdateModalidadeRequest r) {
        Modalidade patch = new Modalidade();
        patch.setNome(r.nome());
        patch.setTempoPartidaMinutos(r.tempoPartidaMinutos());
        patch.setRegrasJson(r.regrasJson());
        return ModalidadeResponse.from(service.update(id, patch, r.campeonatoId(), r.esporteId()));
    }

    public record CreateModalidadeRequest(
            @NotNull UUID campeonatoId,
            @NotNull UUID esporteId,
            @NotBlank String nome,
            Integer tempoPartidaMinutos,
            @NotNull
            @JsonObject
            @Schema(description = "Regras específicas da modalidade em JSON (objeto).", example = """
{
  "tempoRegulamentar": 40,
  "quantidadeJogadores": 5,
  "permiteEmpate": true,
  "tempoProrrogacao": 10,
  "temPenaltis": true
}
            """)
            JsonNode regrasJson
    ) {}

    public record UpdateModalidadeRequest(
            UUID campeonatoId,
            UUID esporteId,
            String nome,
            Integer tempoPartidaMinutos,
            @JsonObject(allowNull = true)
                        @Schema(description = "Regras específicas da modalidade em JSON (objeto).", example = """
{
  "tempoRegulamentar": 40,
  "quantidadeJogadores": 5,
  "permiteEmpate": true,
  "tempoProrrogacao": 10,
  "temPenaltis": true
}
            """)
            JsonNode regrasJson
    ) {}

    public record ModalidadeResponse(
            UUID id,
            UUID campeonatoId,
            String campeonatoNome,
            UUID esporteId,
            String esporteNome,
            String nome,
            Integer tempoPartidaMinutos,
            @NotNull
            @JsonObject
            @Schema(description = "Regras específicas da modalidade em JSON (objeto).", example = """
{
  "tempoRegulamentar": 40,
  "quantidadeJogadores": 5,
  "permiteEmpate": true,
  "tempoProrrogacao": 10,
  "temPenaltis": true
}
            """)
            JsonNode regrasJson
    ) {
        public static ModalidadeResponse from(Modalidade m) {
            return new ModalidadeResponse(
                    m.getId(),
                    m.getCampeonato() != null ? m.getCampeonato().getId() : null,
                    m.getCampeonatoNome(),
                    m.getEsporte() != null ? m.getEsporte().getId() : null,
                    m.getEsporte() != null ? m.getEsporte().getNome() : null,
                    m.getNome(),
                    m.getTempoPartidaMinutos(),
                    m.getRegrasJson()
            );
        }
    }
}
