package com.nkw.backapisumula.competicao.api;

import com.nkw.backapisumula.competicao.Equipe;
import com.nkw.backapisumula.competicao.EquipeAtletaInscrito;
import com.nkw.backapisumula.competicao.EquipeStaff;
import com.nkw.backapisumula.competicao.service.EquipeAtletaInscritoService;
import com.nkw.backapisumula.competicao.service.EquipeService;
import com.nkw.backapisumula.competicao.service.EquipeStaffService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/equipes")
public class EquipesController {

    private final EquipeService service;
    private final EquipeAtletaInscritoService inscritosService;
    private final EquipeStaffService staffService;

    public EquipesController(
            EquipeService service,
            EquipeAtletaInscritoService inscritosService,
            EquipeStaffService staffService
    ) {
        this.service = service;
        this.inscritosService = inscritosService;
        this.staffService = staffService;
    }

    @GetMapping
    public List<EquipeResponse> list(
            @RequestParam(required = false) UUID campeonatoId,
            @RequestParam(required = false) UUID modalidadeId,
            @RequestParam(required = false) UUID atleticaId
    ) {
        return service.list(campeonatoId, modalidadeId, atleticaId).stream().map(EquipeResponse::from).toList();
    }

    @GetMapping("/{id}")
    public EquipeResponse get(@PathVariable UUID id) {
        return EquipeResponse.from(service.getOrThrow(id));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado','ROLE_presidente_atletica')")
    public EquipeResponse create(@Valid @RequestBody CreateEquipeRequest r) {
        return EquipeResponse.from(service.create(r.atleticaId(), r.campeonatoId(), r.modalidadeId(), r.nomeEquipe()));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado','ROLE_presidente_atletica')")
    public EquipeResponse update(@PathVariable UUID id, @Valid @RequestBody UpdateEquipeRequest r) {
        return EquipeResponse.from(service.update(id, r.atleticaId(), r.campeonatoId(), r.modalidadeId(), r.nomeEquipe()));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado','ROLE_presidente_atletica')")
    public void delete(@PathVariable UUID id) {
        service.delete(id);
    }

    // -------- Inscritos --------

    @GetMapping("/{id}/inscritos")
    public List<InscritoResponse> listInscritos(@PathVariable UUID id) {
        return inscritosService.listByEquipe(id).stream().map(InscritoResponse::from).toList();
    }

    @PostMapping("/{id}/inscritos")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado','ROLE_presidente_atletica')")
    public List<InscritoResponse> addInscritos(
            @PathVariable UUID id,
            @Valid @RequestBody @NotEmpty List<@Valid AddInscritoRequest> r
    ) {
        List<EquipeAtletaInscrito> created = inscritosService.addBatch(
                id,
                r.stream()
                        .map(x -> new EquipeAtletaInscritoService.AddInscritoCommand(x.atletaId(), x.numeroCamisa(), x.ativo(), x.isGoleiro(), x.isCapitao()))
                        .toList()
        );
        return created.stream().map(InscritoResponse::from).toList();
    }

    @PatchMapping("/{id}/inscritos/{inscritoId}")
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado','ROLE_presidente_atletica')")
    public InscritoResponse patchInscrito(
            @PathVariable UUID id,
            @PathVariable UUID inscritoId,
            @RequestBody PatchInscritoRequest r
    ) {
        return InscritoResponse.from(inscritosService.updateFuncao(id, inscritoId, r.isGoleiro(), r.isCapitao()));
    }

    @DeleteMapping("/{id}/inscritos/{inscritoId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado','ROLE_presidente_atletica')")
    public void removeInscrito(@PathVariable UUID id, @PathVariable UUID inscritoId) {
        inscritosService.remove(id, inscritoId);
    }

    // -------- Staff --------

    @GetMapping("/{id}/staff")
    public List<StaffResponse> listStaff(@PathVariable UUID id) {
        return staffService.listByEquipe(id).stream().map(StaffResponse::from).toList();
    }

    @PostMapping("/{id}/staff")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado','ROLE_presidente_atletica')")
    public StaffResponse addStaff(@PathVariable UUID id, @Valid @RequestBody AddStaffRequest r) {
        return StaffResponse.from(staffService.add(id, r.nome(), r.cargo()));
    }

    @DeleteMapping("/{id}/staff/{staffId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_delegado','ROLE_presidente_atletica')")
    public void removeStaff(@PathVariable UUID id, @PathVariable UUID staffId) {
        staffService.remove(id, staffId);
    }

    // -------- Records --------

    public record CreateEquipeRequest(
            @NotNull UUID atleticaId,
            @NotNull UUID campeonatoId,
            @NotNull UUID modalidadeId,
            @NotBlank String nomeEquipe
    ) {}

    public record UpdateEquipeRequest(
            UUID atleticaId,
            UUID campeonatoId,
            UUID modalidadeId,
            String nomeEquipe
    ) {}

    public record AddInscritoRequest(
            @NotNull UUID atletaId,
            Integer numeroCamisa,
            Boolean ativo,
            Boolean isGoleiro,
            Boolean isCapitao
    ) {}

    public record PatchInscritoRequest(
            Boolean isGoleiro,
            Boolean isCapitao
    ) {}

    public record AddStaffRequest(
            @NotBlank String nome,
            @NotBlank String cargo
    ) {}

    public record EquipeResponse(
            UUID id,
            UUID atleticaId,
            String atleticaNome,
            String atleticaEscudoUrl,
            UUID campeonatoId,
            String campeonatoNome,
            UUID modalidadeId,
            String modalidadeNome,
            String nomeEquipe
    ) {
        public static EquipeResponse from(Equipe e) {
            return new EquipeResponse(
                    e.getId(),
                    e.getAtletica() != null ? e.getAtletica().getId() : null,
                    e.getAtletica() != null ? e.getAtletica().getNome() : null,
                    e.getAtletica() != null ? e.getAtletica().getEscudoUrl() : null,
                    e.getCampeonato() != null ? e.getCampeonato().getId() : null,
                    e.getCampeonato() != null ? e.getCampeonato().getNome() : null,
                    e.getModalidade() != null ? e.getModalidade().getId() : null,
                    e.getModalidade() != null ? e.getModalidade().getNome() : null,
                    e.getNomeEquipe()
            );
        }
    }

    public record InscritoResponse(
            UUID id,
            UUID equipeId,
            UUID atletaId,
            String atletaNome,
            String atletaFotoUrl,
            UUID atleticaId,
            Integer numeroCamisa,
            Boolean ativo,
            Boolean isGoleiro,
            Boolean isCapitao
    ) {
        public static InscritoResponse from(EquipeAtletaInscrito i) {
            return new InscritoResponse(
                    i.getId(),
                    i.getEquipe() != null ? i.getEquipe().getId() : null,
                    i.getAtleta() != null ? i.getAtleta().getId() : null,
                    i.getAtleta() != null ? i.getAtleta().getNome() : null,
                    i.getAtleta() != null ? i.getAtleta().getFotoUrl() : null,
                    i.getAtleta() != null && i.getAtleta().getAtletica() != null ? i.getAtleta().getAtletica().getId() : null,
                    i.getNumeroCamisa(),
                    i.getAtivo(),
                    i.getIsGoleiro(),
                    i.getIsCapitao()
            );
        }
    }

    public record StaffResponse(
            UUID id,
            UUID equipeId,
            String nome,
            String cargo,
            java.time.OffsetDateTime criadoEm
    ) {
        public static StaffResponse from(EquipeStaff s) {
            return new StaffResponse(
                    s.getId(),
                    s.getEquipe() != null ? s.getEquipe().getId() : null,
                    s.getNome(),
                    s.getCargo(),
                    s.getCriadoEm()
            );
        }
    }
}
