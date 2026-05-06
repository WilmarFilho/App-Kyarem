package com.nkw.backapisumula.competicao.api;

import com.fasterxml.jackson.databind.JsonNode;
import com.nkw.backapisumula.cadastros.Esporte;
import com.nkw.backapisumula.cadastros.repo.EsporteRepository;
import com.nkw.backapisumula.competicao.Campeonato;
import com.nkw.backapisumula.competicao.CampeonatoModalidade;
import com.nkw.backapisumula.competicao.ModalidadeCatalogo;
import com.nkw.backapisumula.competicao.repo.CampeonatoModalidadeRepository;
import com.nkw.backapisumula.competicao.repo.CampeonatoRepository;
import com.nkw.backapisumula.competicao.repo.ModalidadeCatalogoRepository;
import com.nkw.backapisumula.shared.validation.JsonObject;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@RestController
public class ModalidadesController {

        private final CampeonatoModalidadeRepository campeonatoModalidadeRepository;
        private final CampeonatoRepository campeonatoRepository;
        private final ModalidadeCatalogoRepository modalidadeCatalogoRepository;
        private final EsporteRepository esporteRepository;

        public ModalidadesController(CampeonatoModalidadeRepository campeonatoModalidadeRepository,
                        CampeonatoRepository campeonatoRepository,
                        ModalidadeCatalogoRepository modalidadeCatalogoRepository,
                        EsporteRepository esporteRepository) {
                this.campeonatoModalidadeRepository = campeonatoModalidadeRepository;
                this.campeonatoRepository = campeonatoRepository;
                this.modalidadeCatalogoRepository = modalidadeCatalogoRepository;
                this.esporteRepository = esporteRepository;
        }

        @GetMapping("/api/v1/modalidades-catalogo")
        @Transactional(readOnly = true)
        public List<ModalidadeCatalogoResponse> listCatalogo() {
                return modalidadeCatalogoRepository.findAllByOrderByNomeAsc().stream()
                                .map(ModalidadeCatalogoResponse::from)
                                .toList();
        }

        @GetMapping("/api/v1/modalidades-catalogo/{id}")
        @PreAuthorize("hasAuthority('ROLE_admin')")
        @Transactional(readOnly = true)
        public ModalidadeCatalogoResponse getCatalogo(@PathVariable UUID id) {
                ModalidadeCatalogo modalidadeCatalogo = modalidadeCatalogoRepository.findById(id)
                                .orElseThrow(() -> new IllegalStateException("Modalidade catálogo não encontrada."));
                return ModalidadeCatalogoResponse.from(modalidadeCatalogo);
        }

        @GetMapping("/api/v1/modalidades-catalogo/{id}/campeonatos")
        @PreAuthorize("hasAuthority('ROLE_admin')")
        @Transactional(readOnly = true)
        public List<ModalidadeResponse> listAssociacoesByCatalogo(@PathVariable UUID id) {
                modalidadeCatalogoRepository.findById(id)
                                .orElseThrow(() -> new IllegalStateException("Modalidade catálogo não encontrada."));
                return campeonatoModalidadeRepository.findAllByModalidade_IdOrderByCampeonato_NomeAsc(id).stream()
                                .map(ModalidadeResponse::from)
                                .toList();
        }

        @PostMapping("/api/v1/modalidades-catalogo")
        @ResponseStatus(HttpStatus.CREATED)
        @PreAuthorize("hasAuthority('ROLE_admin')")
        @Transactional
        public ModalidadeCatalogoResponse createCatalogo(@Valid @RequestBody CreateModalidadeCatalogoRequest request) {
                ModalidadeCatalogo modalidadeCatalogo = new ModalidadeCatalogo();
                Esporte esporte = esporteRepository.findById(request.esporteId())
                                .orElseThrow(() -> new IllegalStateException("Esporte não encontrado."));
                modalidadeCatalogo.setEsporte(esporte);
                modalidadeCatalogo.setNome(request.nome());
                modalidadeCatalogo.setSlug(request.slug());
                modalidadeCatalogo.setGenero(request.genero());
                modalidadeCatalogo.setMotorRegras(request.motorRegras());
                modalidadeCatalogo.setMotorConfigsDefault(request.motorConfigsDefault());
                modalidadeCatalogo.setAtivo(request.ativo() == null ? Boolean.TRUE : request.ativo());
                return ModalidadeCatalogoResponse.from(modalidadeCatalogoRepository.save(modalidadeCatalogo));
        }

        @PutMapping("/api/v1/modalidades-catalogo/{id}")
        @PreAuthorize("hasAuthority('ROLE_admin')")
        @Transactional
        public ModalidadeCatalogoResponse updateCatalogo(
                        @PathVariable UUID id,
                        @Valid @RequestBody UpdateModalidadeCatalogoRequest request) {
                ModalidadeCatalogo modalidadeCatalogo = modalidadeCatalogoRepository.findById(id)
                                .orElseThrow(() -> new IllegalStateException("Modalidade catálogo não encontrada."));

                if (request.esporteId() != null) {
                        Esporte esporte = esporteRepository.findById(request.esporteId())
                                        .orElseThrow(() -> new IllegalStateException("Esporte não encontrado."));
                        modalidadeCatalogo.setEsporte(esporte);
                }
                if (request.nome() != null) modalidadeCatalogo.setNome(request.nome());
                if (request.slug() != null) modalidadeCatalogo.setSlug(request.slug());
                if (request.genero() != null) modalidadeCatalogo.setGenero(request.genero());
                if (request.motorRegras() != null) modalidadeCatalogo.setMotorRegras(request.motorRegras());
                if (request.motorConfigsDefault() != null) modalidadeCatalogo.setMotorConfigsDefault(request.motorConfigsDefault());
                if (request.ativo() != null) modalidadeCatalogo.setAtivo(request.ativo());

                return ModalidadeCatalogoResponse.from(modalidadeCatalogoRepository.save(modalidadeCatalogo));
        }

        @DeleteMapping("/api/v1/modalidades-catalogo/{id}")
        @ResponseStatus(HttpStatus.NO_CONTENT)
        @PreAuthorize("hasAuthority('ROLE_admin')")
        public void deleteCatalogo(@PathVariable UUID id) {
                ModalidadeCatalogo modalidadeCatalogo = modalidadeCatalogoRepository.findById(id)
                                .orElseThrow(() -> new IllegalStateException("Modalidade catálogo não encontrada."));
                modalidadeCatalogoRepository.delete(modalidadeCatalogo);
        }

        @GetMapping("/api/v1/campeonatos/{campeonatoId}/modalidades")
        @Transactional(readOnly = true)
        public List<ModalidadeResponse> listByCampeonato(@PathVariable UUID campeonatoId) {
                return campeonatoModalidadeRepository.findAll().stream()
                                .filter(item -> item.getCampeonato() != null
                                                && campeonatoId.equals(item.getCampeonato().getId()))
                                .map(ModalidadeResponse::from)
                                .toList();
        }

        @GetMapping("/api/v1/modalidades/{id}")
        @Transactional(readOnly = true)
        public ModalidadeResponse get(@PathVariable UUID id) {
                CampeonatoModalidade modalidade = campeonatoModalidadeRepository.findById(id)
                                .orElseThrow(() -> new IllegalStateException(
                                                "Modalidade do campeonato não encontrada."));
                return ModalidadeResponse.from(modalidade);
        }

        @PostMapping("/api/v1/modalidades")
        @ResponseStatus(HttpStatus.CREATED)
        @PreAuthorize("hasAuthority('ROLE_admin')")
        @Transactional
        public ModalidadeResponse create(@Valid @RequestBody CreateModalidadeRequest request) {
                Campeonato campeonato = campeonatoRepository.findById(request.campeonatoId())
                                .orElseThrow(() -> new IllegalStateException("Campeonato não encontrado."));
                ModalidadeCatalogo modalidadeCatalogo = modalidadeCatalogoRepository
                                .findById(request.modalidadeCatalogoId())
                                .orElseThrow(() -> new IllegalStateException("Modalidade catálogo não encontrada."));

                if (campeonatoModalidadeRepository.existsByCampeonato_IdAndModalidade_Id(
                                request.campeonatoId(),
                                request.modalidadeCatalogoId())) {
                        throw new IllegalStateException("Essa modalidade já está associada a esse campeonato.");
                }

                CampeonatoModalidade modalidade = new CampeonatoModalidade();
                modalidade.setCampeonato(campeonato);
                modalidade.setModalidade(modalidadeCatalogo);

                modalidade.setNomeExibicao(request.nomeExibicao());
                modalidade.setCategoria(request.categoria());
                modalidade.setGenero(request.genero());
                modalidade.setRegrasJson(request.regrasJson());
                modalidade.setFormatoFasesJson(request.formatoFasesJson());
                modalidade.setTempoPartidaMinutos(request.tempoPartidaMinutos());
                if (request.permiteProrrogacao() != null)
                        modalidade.setPermiteProrrogacao(request.permiteProrrogacao());
                if (request.permitePenaltis() != null)
                        modalidade.setPermitePenaltis(request.permitePenaltis());
                if (request.status() != null)
                        modalidade.setStatus(request.status());

                return ModalidadeResponse.from(campeonatoModalidadeRepository.save(modalidade));
        }

        @DeleteMapping("/api/v1/modalidades/{id}")
        @ResponseStatus(HttpStatus.NO_CONTENT)
        @PreAuthorize("hasAuthority('ROLE_admin')")
        public void delete(@PathVariable UUID id) {
                CampeonatoModalidade modalidade = campeonatoModalidadeRepository.findById(id)
                                .orElseThrow(() -> new IllegalStateException(
                                                "Modalidade do campeonato não encontrada."));
                campeonatoModalidadeRepository.delete(modalidade);
        }

        @PutMapping("/api/v1/modalidades/{id}")
        @PreAuthorize("hasAuthority('ROLE_admin')")
        public ModalidadeResponse update(@PathVariable UUID id, @Valid @RequestBody UpdateModalidadeRequest request) {
                CampeonatoModalidade modalidade = campeonatoModalidadeRepository.findById(id)
                                .orElseThrow(() -> new IllegalStateException(
                                                "Modalidade do campeonato não encontrada."));

                if (request.campeonatoId() != null) {
                        Campeonato campeonato = campeonatoRepository.findById(request.campeonatoId())
                                        .orElseThrow(() -> new IllegalStateException("Campeonato não encontrado."));
                        modalidade.setCampeonato(campeonato);
                }

                if (request.modalidadeCatalogoId() != null) {
                        ModalidadeCatalogo modalidadeCatalogo = modalidadeCatalogoRepository
                                        .findById(request.modalidadeCatalogoId())
                                        .orElseThrow(() -> new IllegalStateException(
                                                        "Modalidade catálogo não encontrada."));
                        modalidade.setModalidade(modalidadeCatalogo);
                }

                if (request.nomeExibicao() != null)
                        modalidade.setNomeExibicao(request.nomeExibicao());
                if (request.categoria() != null)
                        modalidade.setCategoria(request.categoria());
                if (request.genero() != null)
                        modalidade.setGenero(request.genero());
                if (request.regrasJson() != null)
                        modalidade.setRegrasJson(request.regrasJson());
                if (request.formatoFasesJson() != null)
                        modalidade.setFormatoFasesJson(request.formatoFasesJson());
                if (request.tempoPartidaMinutos() != null)
                        modalidade.setTempoPartidaMinutos(request.tempoPartidaMinutos());
                if (request.permiteProrrogacao() != null)
                        modalidade.setPermiteProrrogacao(request.permiteProrrogacao());
                if (request.permitePenaltis() != null)
                        modalidade.setPermitePenaltis(request.permitePenaltis());
                if (request.status() != null)
                        modalidade.setStatus(request.status());

                return ModalidadeResponse.from(campeonatoModalidadeRepository.save(modalidade));
        }

        public record CreateModalidadeRequest(
                        @NotNull UUID campeonatoId,
                        @NotNull UUID modalidadeCatalogoId,
                        String nomeExibicao,
                        String categoria,
                        String genero,
                        @JsonObject(allowNull = true) JsonNode regrasJson,
                        @JsonObject(allowNull = true) JsonNode formatoFasesJson,
                        Integer tempoPartidaMinutos,
                        Boolean permiteProrrogacao,
                        Boolean permitePenaltis,
                        String status) {
        }

        public record CreateModalidadeCatalogoRequest(
                        @NotNull UUID esporteId,
                        @NotNull String nome,
                        @NotNull String slug,
                        @NotNull String genero,
                        @NotNull String motorRegras,
                        @JsonObject(allowNull = true) JsonNode motorConfigsDefault,
                        Boolean ativo) {
        }

        public record UpdateModalidadeCatalogoRequest(
                        UUID esporteId,
                        String nome,
                        String slug,
                        String genero,
                        String motorRegras,
                        @JsonObject(allowNull = true) JsonNode motorConfigsDefault,
                        Boolean ativo) {
        }

        public record UpdateModalidadeRequest(
                        UUID campeonatoId,
                        UUID modalidadeCatalogoId,
                        String nomeExibicao,
                        String categoria,
                        String genero,
                        @JsonObject(allowNull = true) JsonNode regrasJson,
                        @JsonObject(allowNull = true) JsonNode formatoFasesJson,
                        Integer tempoPartidaMinutos,
                        Boolean permiteProrrogacao,
                        Boolean permitePenaltis,
                        String status) {
        }

        public record ModalidadeResponse(
                        UUID id,
                        UUID campeonatoId,
                        String campeonatoNome,
                        UUID modalidadeCatalogoId,
                        UUID esporteId,
                        String esporteNome,
                        String nome,
                        String slug,
                        String generoCatalogo,
                        String nomeExibicao,
                        String categoria,
                        String genero,
                        JsonNode regrasJson,
                        JsonNode formatoFasesJson,
                        Integer tempoPartidaMinutos,
                        Boolean permiteProrrogacao,
                        Boolean permitePenaltis,
                        String status) {
                public static ModalidadeResponse from(CampeonatoModalidade modalidade) {
                        ModalidadeCatalogo catalogo = modalidade.getModalidade();
                        return new ModalidadeResponse(
                                        modalidade.getId(),
                                        modalidade.getCampeonato() != null ? modalidade.getCampeonato().getId() : null,
                                        modalidade.getCampeonato() != null ? modalidade.getCampeonato().getNome()
                                                        : null,
                                        catalogo != null ? catalogo.getId() : null,
                                        catalogo != null && catalogo.getEsporte() != null
                                                        ? catalogo.getEsporte().getId()
                                                        : null,
                                        catalogo != null && catalogo.getEsporte() != null
                                                        ? catalogo.getEsporte().getNome()
                                                        : null,
                                        catalogo != null ? catalogo.getNome() : null,
                                        catalogo != null ? catalogo.getSlug() : null,
                                        catalogo != null ? catalogo.getGenero() : null,
                                        modalidade.getNomeExibicao(),
                                        modalidade.getCategoria(),
                                        modalidade.getGenero(),
                                        modalidade.getRegrasJson(),
                                        modalidade.getFormatoFasesJson(),
                                        modalidade.getTempoPartidaMinutos(),
                                        modalidade.getPermiteProrrogacao(),
                                        modalidade.getPermitePenaltis(),
                                        modalidade.getStatus());
                }
        }

        public record ModalidadeCatalogoResponse(
                        UUID id,
                        UUID esporteId,
                        String esporteNome,
                        String nome,
                        String slug,
                        String genero,
                        String motorRegras,
                        JsonNode motorConfigsDefault,
                        Boolean ativo) {
                public static ModalidadeCatalogoResponse from(ModalidadeCatalogo modalidadeCatalogo) {
                        return new ModalidadeCatalogoResponse(
                                        modalidadeCatalogo.getId(),
                                        modalidadeCatalogo.getEsporte() != null
                                                        ? modalidadeCatalogo.getEsporte().getId()
                                                        : null,
                                        modalidadeCatalogo.getEsporte() != null
                                                        ? modalidadeCatalogo.getEsporte().getNome()
                                                        : null,
                                        modalidadeCatalogo.getNome(),
                                        modalidadeCatalogo.getSlug(),
                                        modalidadeCatalogo.getGenero(),
                                        modalidadeCatalogo.getMotorRegras(),
                                        modalidadeCatalogo.getMotorConfigsDefault(),
                                        modalidadeCatalogo.getAtivo());
                }
        }
}
