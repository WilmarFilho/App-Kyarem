package com.nkw.backapisumula.competicao.api;

import com.nkw.backapisumula.cadastros.Atletica;
import com.nkw.backapisumula.competicao.CampeonatoModalidade;
import com.nkw.backapisumula.competicao.CampeonatoTime;
import com.nkw.backapisumula.competicao.ModalidadeCatalogo;
import com.nkw.backapisumula.competicao.TimeAtletica;
import com.nkw.backapisumula.competicao.repo.CampeonatoModalidadeRepository;
import com.nkw.backapisumula.competicao.repo.CampeonatoTimeRepository;
import com.nkw.backapisumula.competicao.repo.TimeAtleticaRepository;
import com.nkw.backapisumula.competicao.repo.ModalidadeCatalogoRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/times")
public class TimesController {

    private final TimeAtleticaRepository timeAtleticaRepository;
    private final CampeonatoTimeRepository campeonatoTimeRepository;
    private final ModalidadeCatalogoRepository modalidadeCatalogoRepository;
    private final CampeonatoModalidadeRepository campeonatoModalidadeRepository;

    public TimesController(TimeAtleticaRepository timeAtleticaRepository,
                           CampeonatoTimeRepository campeonatoTimeRepository,
                           ModalidadeCatalogoRepository modalidadeCatalogoRepository,
                           CampeonatoModalidadeRepository campeonatoModalidadeRepository) {
        this.timeAtleticaRepository = timeAtleticaRepository;
        this.campeonatoTimeRepository = campeonatoTimeRepository;
        this.modalidadeCatalogoRepository = modalidadeCatalogoRepository;
        this.campeonatoModalidadeRepository = campeonatoModalidadeRepository;
    }

    @GetMapping("/atletica/{atleticaId}")
    public List<TimeAtleticaResponse> listTimesPorAtletica(@PathVariable UUID atleticaId) {
        return timeAtleticaRepository.findAll().stream()
                .filter(time -> time.getAtletica() != null && atleticaId.equals(time.getAtletica().getId()))
                .map(TimeAtleticaResponse::from)
                .toList();
    }

    @PostMapping("/atletica")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director','ROLE_president')")
    public TimeAtleticaResponse createTimeAtletica(@Valid @RequestBody CreateTimeAtleticaRequest request) {
        ModalidadeCatalogo modalidade = modalidadeCatalogoRepository.findById(request.modalidadeCatalogoId())
                .orElseThrow(() -> new IllegalStateException("Modalidade catálogo não encontrada."));

        Atletica atletica = new Atletica();
        atletica.setId(request.atleticaId());

        TimeAtletica time = new TimeAtletica();
        time.setAtletica(atletica);
        time.setModalidade(modalidade);
        time.setNome(request.nome());
        time.setCriadoEm(OffsetDateTime.now());

        return TimeAtleticaResponse.from(timeAtleticaRepository.save(time));
    }

    @PutMapping("/atletica/{timeId}")
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director','ROLE_president')")
    public TimeAtleticaResponse updateTimeAtletica(@PathVariable UUID timeId,
                                                   @Valid @RequestBody UpdateTimeAtleticaRequest request) {
        TimeAtletica time = timeAtleticaRepository.findById(timeId)
                .orElseThrow(() -> new IllegalStateException("Time da atlética não encontrado."));

        if (request.nome() != null && !request.nome().isBlank()) {
            time.setNome(request.nome());
        }
        if (request.modalidadeCatalogoId() != null) {
            ModalidadeCatalogo modalidade = modalidadeCatalogoRepository.findById(request.modalidadeCatalogoId())
                    .orElseThrow(() -> new IllegalStateException("Modalidade catálogo não encontrada."));
            time.setModalidade(modalidade);
        }

        return TimeAtleticaResponse.from(timeAtleticaRepository.save(time));
    }

    @DeleteMapping("/atletica/{timeId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director','ROLE_president')")
    public void deleteTimeAtletica(@PathVariable UUID timeId) {
        timeAtleticaRepository.deleteById(timeId);
    }

    @GetMapping("/campeonato/{campeonatoId}")
    public List<CampeonatoTimeResponse> listTimesPorCampeonato(@PathVariable UUID campeonatoId) {
        return campeonatoTimeRepository.findAll().stream()
                .filter(time -> time.getCampeonato() != null && campeonatoId.equals(time.getCampeonato().getId()))
                .map(CampeonatoTimeResponse::from)
                .toList();
    }

    @PostMapping("/campeonato")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director','ROLE_president')")
    public CampeonatoTimeResponse inscreverTimeNoCampeonato(@Valid @RequestBody InscricaoTimeRequest request) {
        CampeonatoModalidade campeonatoModalidade = campeonatoModalidadeRepository.findById(request.campeonatoModalidadeId())
                .orElseThrow(() -> new IllegalStateException("Modalidade do campeonato não encontrada."));

        TimeAtletica timeAtletica = timeAtleticaRepository.findById(request.timeAtleticaId())
                .orElseThrow(() -> new IllegalStateException("Time da atlética não encontrado."));

        CampeonatoTime campeonatoTime = new CampeonatoTime();
        campeonatoTime.setCampeonato(campeonatoModalidade.getCampeonato());
        campeonatoTime.setCampeonatoModalidade(campeonatoModalidade);
        campeonatoTime.setTime(timeAtletica);
        campeonatoTime.setNomeExibicao(request.nomeExibicao());
        campeonatoTime.setStatus("CONFIRMADA");
        // TODO: campeonatoAtleticaId is required by schema, but no entity/endpoint exists yet.
        // We set a temporary UUID to avoid null pointer/compile errors, but this will fail DB constraints
        // until the business logic fully implements campeonato_atleticas.
        campeonatoTime.setCampeonatoAtleticaId(UUID.randomUUID());

        return CampeonatoTimeResponse.from(campeonatoTimeRepository.save(campeonatoTime));
    }

    @DeleteMapping("/campeonato/{campeonatoTimeId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAnyAuthority('ROLE_admin','ROLE_director','ROLE_president')")
    public void removerTimeDoCampeonato(@PathVariable UUID campeonatoTimeId) {
        campeonatoTimeRepository.deleteById(campeonatoTimeId);
    }

    public record CreateTimeAtleticaRequest(
            @NotNull UUID atleticaId,
            @NotNull UUID modalidadeCatalogoId,
            @NotBlank String nome
    ) {}

    public record UpdateTimeAtleticaRequest(
            UUID modalidadeCatalogoId,
            String nome
    ) {}

    public record InscricaoTimeRequest(
            @NotNull UUID campeonatoModalidadeId,
            @NotNull UUID timeAtleticaId,
            String nomeExibicao
    ) {}

    public record TimeAtleticaResponse(
            UUID id,
            UUID atleticaId,
            String atleticaNome,
            String nome,
            UUID modalidadeCatalogoId,
            String modalidadeNome,
            String genero
    ) {
        public static TimeAtleticaResponse from(TimeAtletica time) {
            return new TimeAtleticaResponse(
                    time.getId(),
                    time.getAtletica() != null ? time.getAtletica().getId() : null,
                    time.getAtletica() != null ? time.getAtletica().getNome() : null,
                    time.getNome(),
                    time.getModalidade() != null ? time.getModalidade().getId() : null,
                    time.getModalidade() != null ? time.getModalidade().getNome() : null,
                    time.getModalidade() != null ? time.getModalidade().getGenero() : null
            );
        }
    }

    public record CampeonatoTimeResponse(
            UUID id,
            UUID campeonatoId,
            String campeonatoNome,
            UUID campeonatoModalidadeId,
            UUID timeAtleticaId,
            String nome,
            String atleticaNome,
            String modalidadeNome,
            String status
    ) {
        public static CampeonatoTimeResponse from(CampeonatoTime time) {
            return new CampeonatoTimeResponse(
                    time.getId(),
                    time.getCampeonato() != null ? time.getCampeonato().getId() : null,
                    time.getCampeonato() != null ? time.getCampeonato().getNome() : null,
                    time.getCampeonatoModalidade() != null ? time.getCampeonatoModalidade().getId() : null,
                    time.getTime() != null ? time.getTime().getId() : null,
                    time.getNomeEquipe(),
                    time.getTime() != null && time.getTime().getAtletica() != null ? time.getTime().getAtletica().getNome() : null,
                    time.getCampeonatoModalidade() != null && time.getCampeonatoModalidade().getModalidade() != null
                            ? time.getCampeonatoModalidade().getModalidade().getNome() : null,
                    time.getStatus()
            );
        }
    }
}
