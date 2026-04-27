package com.nkw.backapisumula.competicao.api;

import com.fasterxml.jackson.databind.JsonNode;
import com.nkw.backapisumula.competicao.Campeonato;
import com.nkw.backapisumula.competicao.CampeonatoModalidade;
import com.nkw.backapisumula.competicao.ModalidadeCatalogo;
import com.nkw.backapisumula.competicao.repo.CampeonatoModalidadeRepository;
import com.nkw.backapisumula.competicao.repo.CampeonatoRepository;
import com.nkw.backapisumula.competicao.repo.ModalidadeCatalogoRepository;
import com.nkw.backapisumula.shared.validation.JsonObject;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
public class ModalidadesController {

    private final CampeonatoModalidadeRepository campeonatoModalidadeRepository;
    private final CampeonatoRepository campeonatoRepository;
    private final ModalidadeCatalogoRepository modalidadeCatalogoRepository;

    public ModalidadesController(CampeonatoModalidadeRepository campeonatoModalidadeRepository,
                                 CampeonatoRepository campeonatoRepository,
                                 ModalidadeCatalogoRepository modalidadeCatalogoRepository) {
        this.campeonatoModalidadeRepository = campeonatoModalidadeRepository;
        this.campeonatoRepository = campeonatoRepository;
        this.modalidadeCatalogoRepository = modalidadeCatalogoRepository;
    }

    @GetMapping("/api/v1/modalidades-catalogo")
    public List<ModalidadeCatalogoResponse> listCatalogo() {
        return modalidadeCatalogoRepository.findAll().stream()
                .map(ModalidadeCatalogoResponse::from)
                .toList();
    }

    @GetMapping("/api/v1/campeonatos/{campeonatoId}/modalidades")
    public List<ModalidadeResponse> listByCampeonato(@PathVariable UUID campeonatoId) {
        return campeonatoModalidadeRepository.findAll().stream()
                .filter(item -> item.getCampeonato() != null && campeonatoId.equals(item.getCampeonato().getId()))
                .map(ModalidadeResponse::from)
                .toList();
    }

    @GetMapping("/api/v1/modalidades/{id}")
    public ModalidadeResponse get(@PathVariable UUID id) {
        CampeonatoModalidade modalidade = campeonatoModalidadeRepository.findById(id)
                .orElseThrow(() -> new IllegalStateException("Modalidade do campeonato não encontrada."));
        return ModalidadeResponse.from(modalidade);
    }

    @PostMapping("/api/v1/modalidades")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director')")
    public ModalidadeResponse create(@Valid @RequestBody CreateModalidadeRequest request) {
        Campeonato campeonato = campeonatoRepository.findById(request.campeonatoId())
                .orElseThrow(() -> new IllegalStateException("Campeonato não encontrado."));
        ModalidadeCatalogo modalidadeCatalogo = modalidadeCatalogoRepository.findById(request.modalidadeCatalogoId())
                .orElseThrow(() -> new IllegalStateException("Modalidade catálogo não encontrada."));

        CampeonatoModalidade modalidade = new CampeonatoModalidade();
        modalidade.setCampeonato(campeonato);
        modalidade.setModalidade(modalidadeCatalogo);
        modalidade.setFaseAtual(request.faseAtual());
        modalidade.setConfiguracoesEspecificas(request.configuracoesEspecificas());

        return ModalidadeResponse.from(campeonatoModalidadeRepository.save(modalidade));
    }

    @PutMapping("/api/v1/modalidades/{id}")
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director')")
    public ModalidadeResponse update(@PathVariable UUID id, @Valid @RequestBody UpdateModalidadeRequest request) {
        CampeonatoModalidade modalidade = campeonatoModalidadeRepository.findById(id)
                .orElseThrow(() -> new IllegalStateException("Modalidade do campeonato não encontrada."));

        if (request.campeonatoId() != null) {
            Campeonato campeonato = campeonatoRepository.findById(request.campeonatoId())
                    .orElseThrow(() -> new IllegalStateException("Campeonato não encontrado."));
            modalidade.setCampeonato(campeonato);
        }

        if (request.modalidadeCatalogoId() != null) {
            ModalidadeCatalogo modalidadeCatalogo = modalidadeCatalogoRepository.findById(request.modalidadeCatalogoId())
                    .orElseThrow(() -> new IllegalStateException("Modalidade catálogo não encontrada."));
            modalidade.setModalidade(modalidadeCatalogo);
        }

        if (request.faseAtual() != null) {
            modalidade.setFaseAtual(request.faseAtual());
        }
        if (request.configuracoesEspecificas() != null) {
            modalidade.setConfiguracoesEspecificas(request.configuracoesEspecificas());
        }

        return ModalidadeResponse.from(campeonatoModalidadeRepository.save(modalidade));
    }

    public record CreateModalidadeRequest(
            @NotNull UUID campeonatoId,
            @NotNull UUID modalidadeCatalogoId,
            String faseAtual,
            @JsonObject(allowNull = true)
            @Schema(description = "Configurações específicas da modalidade no campeonato.", example = """
{
  "tempoRegulamentar": 40,
  "permiteEmpate": true
}
            """)
            JsonNode configuracoesEspecificas
    ) {}

    public record UpdateModalidadeRequest(
            UUID campeonatoId,
            UUID modalidadeCatalogoId,
            String faseAtual,
            @JsonObject(allowNull = true)
            JsonNode configuracoesEspecificas
    ) {}

    public record ModalidadeResponse(
            UUID id,
            UUID campeonatoId,
            String campeonatoNome,
            UUID modalidadeCatalogoId,
            UUID esporteId,
            String esporteNome,
            String nome,
            String slug,
            String genero,
            String faseAtual,
            JsonNode configuracoesEspecificas
    ) {
        public static ModalidadeResponse from(CampeonatoModalidade modalidade) {
            ModalidadeCatalogo catalogo = modalidade.getModalidade();
            return new ModalidadeResponse(
                    modalidade.getId(),
                    modalidade.getCampeonato() != null ? modalidade.getCampeonato().getId() : null,
                    modalidade.getCampeonato() != null ? modalidade.getCampeonato().getNome() : null,
                    catalogo != null ? catalogo.getId() : null,
                    catalogo != null && catalogo.getEsporte() != null ? catalogo.getEsporte().getId() : null,
                    catalogo != null && catalogo.getEsporte() != null ? catalogo.getEsporte().getNome() : null,
                    catalogo != null ? catalogo.getNome() : null,
                    catalogo != null ? catalogo.getSlug() : null,
                    catalogo != null ? catalogo.getGenero() : null,
                    modalidade.getFaseAtual(),
                    modalidade.getConfiguracoesEspecificas()
            );
        }
    }

    public record ModalidadeCatalogoResponse(
            UUID id,
            UUID esporteId,
            String esporteNome,
            String nome,
            String slug,
            String genero
    ) {
        public static ModalidadeCatalogoResponse from(ModalidadeCatalogo modalidadeCatalogo) {
            return new ModalidadeCatalogoResponse(
                    modalidadeCatalogo.getId(),
                    modalidadeCatalogo.getEsporte() != null ? modalidadeCatalogo.getEsporte().getId() : null,
                    modalidadeCatalogo.getEsporte() != null ? modalidadeCatalogo.getEsporte().getNome() : null,
                    modalidadeCatalogo.getNome(),
                    modalidadeCatalogo.getSlug(),
                    modalidadeCatalogo.getGenero()
            );
        }
    }
}
