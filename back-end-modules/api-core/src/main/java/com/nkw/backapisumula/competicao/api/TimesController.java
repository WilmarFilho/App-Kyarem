package com.nkw.backapisumula.competicao.api;

import com.nkw.backapisumula.cadastros.Atletica;
import com.nkw.backapisumula.common.outbox.EventPublisherService;
import com.nkw.backapisumula.competicao.CampeonatoModalidade;
import com.nkw.backapisumula.competicao.CampeonatoTime;
import com.nkw.backapisumula.competicao.ModalidadeCatalogo;
import com.nkw.backapisumula.competicao.TimeAtletica;
import com.nkw.backapisumula.competicao.repo.CampeonatoModalidadeRepository;
import com.nkw.backapisumula.competicao.repo.CampeonatoTimeRepository;
import com.nkw.backapisumula.competicao.repo.TimeAtleticaRepository;
import com.nkw.backapisumula.competicao.repo.ModalidadeCatalogoRepository;
import com.nkw.backapisumula.competicao.EquipeStaff;
import com.nkw.backapisumula.competicao.repo.EquipeStaffRepository;
import jakarta.persistence.EntityManager;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
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
        private final EventPublisherService eventPublisherService;
        private final EquipeStaffRepository equipeStaffRepository;

        @Autowired
        private EntityManager entityManager;

        public TimesController(TimeAtleticaRepository timeAtleticaRepository,
                        CampeonatoTimeRepository campeonatoTimeRepository,
                        ModalidadeCatalogoRepository modalidadeCatalogoRepository,
                        CampeonatoModalidadeRepository campeonatoModalidadeRepository,
                        EventPublisherService eventPublisherService,
                        EquipeStaffRepository equipeStaffRepository) {
                this.timeAtleticaRepository = timeAtleticaRepository;
                this.campeonatoTimeRepository = campeonatoTimeRepository;
                this.modalidadeCatalogoRepository = modalidadeCatalogoRepository;
                this.campeonatoModalidadeRepository = campeonatoModalidadeRepository;
                this.eventPublisherService = eventPublisherService;
                this.equipeStaffRepository = equipeStaffRepository;
        }

        @GetMapping("/atletica/{atleticaId}")
        @Transactional(readOnly = true)
        public List<TimeAtleticaResponse> listTimesPorAtletica(@PathVariable UUID atleticaId) {
                return timeAtleticaRepository.findAll().stream()
                                .filter(time -> time.getAtletica() != null
                                                && atleticaId.equals(time.getAtletica().getId()))
                                .map(TimeAtleticaResponse::from)
                                .toList();
        }

        @PostMapping("/atletica")
        @ResponseStatus(HttpStatus.CREATED)
        @PreAuthorize("isAuthenticated()")
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
        @PreAuthorize("isAuthenticated()")
        public TimeAtleticaResponse updateTimeAtletica(@PathVariable UUID timeId,
                        @Valid @RequestBody UpdateTimeAtleticaRequest request) {
                TimeAtletica time = timeAtleticaRepository.findById(timeId)
                                .orElseThrow(() -> new IllegalStateException("Time da atlética não encontrado."));

                if (request.nome() != null && !request.nome().isBlank()) {
                        time.setNome(request.nome());
                }
                if (request.modalidadeCatalogoId() != null) {
                        ModalidadeCatalogo modalidade = modalidadeCatalogoRepository
                                        .findById(request.modalidadeCatalogoId())
                                        .orElseThrow(() -> new IllegalStateException(
                                                        "Modalidade catálogo não encontrada."));
                        time.setModalidade(modalidade);
                }

                return TimeAtleticaResponse.from(timeAtleticaRepository.save(time));
        }

        @DeleteMapping("/atletica/{timeId}")
        @ResponseStatus(HttpStatus.NO_CONTENT)
        @PreAuthorize("isAuthenticated()")
        public void deleteTimeAtletica(@PathVariable UUID timeId) {
                timeAtleticaRepository.deleteById(timeId);
        }

        @PostMapping("/atletica/{timeId}/atletas")
        @ResponseStatus(HttpStatus.CREATED)
        @PreAuthorize("isAuthenticated()")
        public void adicionarAtletasTimePermanente(@PathVariable UUID timeId,
                        @Valid @RequestBody AddAtletasRequest request) {
                // Feature descontinuada: A tabela operational.time_atletica_atletas foi removida (V25).
                // O vínculo de atletas a times permanentes não é mais suportado no BD,
                // devendo ser feito através de campeonato_atletas (por campeonato).
        }

        @GetMapping("/campeonato/{campeonatoId}")
        @Transactional(readOnly = true)
        public List<CampeonatoTimeResponse> listTimesPorCampeonato(@PathVariable UUID campeonatoId) {
                return campeonatoTimeRepository.findAll().stream()
                                .filter(time -> time.getCampeonato() != null
                                                && campeonatoId.equals(time.getCampeonato().getId()))
                                .map(CampeonatoTimeResponse::from)
                                .toList();
        }

        @PostMapping("/campeonato")
        @ResponseStatus(HttpStatus.CREATED)
        @PreAuthorize("isAuthenticated()")
        @Transactional
        public CampeonatoTimeResponse inscreverTimeNoCampeonato(@Valid @RequestBody InscricaoTimeRequest request) {
                CampeonatoModalidade campeonatoModalidade = campeonatoModalidadeRepository
                                .findById(request.campeonatoModalidadeId())
                                .orElseThrow(() -> new IllegalStateException(
                                                "Modalidade do campeonato não encontrada."));

                TimeAtletica timeAtletica = timeAtleticaRepository.findById(request.timeAtleticaId())
                                .orElseThrow(() -> new IllegalStateException("Time da atlética não encontrado."));

                CampeonatoTime campeonatoTime = new CampeonatoTime();
                campeonatoTime.setCampeonato(campeonatoModalidade.getCampeonato());
                campeonatoTime.setCampeonatoModalidade(campeonatoModalidade);
                campeonatoTime.setTime(timeAtletica);
                campeonatoTime.setStatus("CONFIRMADA");
                UUID campeonatoAtleticaId;
                try {
                        campeonatoAtleticaId = (UUID) entityManager.createNativeQuery(
                                        "SELECT id FROM operational.campeonato_atleticas WHERE campeonato_id = :campeonatoId AND atletica_id = :atleticaId")
                                        .setParameter("campeonatoId", campeonatoModalidade.getCampeonato().getId())
                                        .setParameter("atleticaId", timeAtletica.getAtletica().getId())
                                        .getSingleResult();
                } catch (Exception e) {
                        e.printStackTrace();
                        throw new IllegalStateException("A atlética não está inscrita neste campeonato. Erro real: " + e.getMessage(), e);
                }

                campeonatoTime.setCampeonatoAtleticaId(campeonatoAtleticaId);
                campeonatoTime.setCriadoEm(OffsetDateTime.now());

                CampeonatoTime saved = campeonatoTimeRepository.save(campeonatoTime);
                eventPublisherService.publish(
                                "CampeonatoTime",
                                saved.getId().toString(),
                                "CampeonatoTimeCriado",
                                java.util.Map.of(
                                                "campeonatoTimeId", saved.getId().toString(),
                                                "campeonatoId", saved.getCampeonato().getId().toString(),
                                                "campeonatoAtleticaId", saved.getCampeonatoAtleticaId().toString()));

                return CampeonatoTimeResponse.from(saved);
        }

        @DeleteMapping("/campeonato/{campeonatoTimeId}")
        @ResponseStatus(HttpStatus.NO_CONTENT)
        @PreAuthorize("isAuthenticated()")
        @Transactional
        public void removerTimeDoCampeonato(@PathVariable UUID campeonatoTimeId) {
                CampeonatoTime time = campeonatoTimeRepository.findById(campeonatoTimeId)
                                .orElseThrow(() -> new IllegalStateException("Time do campeonato não encontrado."));

                entityManager.createNativeQuery("DELETE FROM operational.campeonato_atletas WHERE campeonato_time_id = :timeId")
                                .setParameter("timeId", campeonatoTimeId).executeUpdate();
                entityManager.createNativeQuery("DELETE FROM operational.equipes_staff WHERE campeonato_time_id = :timeId")
                                .setParameter("timeId", campeonatoTimeId).executeUpdate();

                eventPublisherService.publish(
                                "CampeonatoTime",
                                campeonatoTimeId.toString(),
                                "CampeonatoTimeExcluido",
                                java.util.Map.of(
                                                "campeonatoTimeId", campeonatoTimeId.toString(),
                                                "campeonatoId", time.getCampeonato().getId().toString(),
                                                "campeonatoAtleticaId", time.getCampeonatoAtleticaId().toString()));
                campeonatoTimeRepository.deleteById(campeonatoTimeId);
        }

        @PatchMapping("/campeonato/{campeonatoTimeId}/atletas/{atletaId}/camisa")
        @Transactional
        @PreAuthorize("isAuthenticated()")
        @ResponseStatus(HttpStatus.NO_CONTENT)
        public void atualizarNumeroCamisa(
                        @PathVariable UUID campeonatoTimeId,
                        @PathVariable UUID atletaId,
                        @Valid @RequestBody AtualizarNumeroCamisaRequest request) {
                CampeonatoTime ct = campeonatoTimeRepository.findById(campeonatoTimeId)
                                .orElseThrow(() -> new IllegalStateException("Equipe do campeonato não encontrada."));
                if (ct.getTime() == null)
                        throw new IllegalStateException("Time atlética não vinculado à equipe do campeonato.");

                int updated = entityManager.createNativeQuery("""
                                UPDATE operational.campeonato_atletas
                                SET numero_camisa = :numeroCamisa
                                WHERE campeonato_time_id = :campeonatoTimeId
                                  AND atleta_id = :atletaId
                                """)
                                .setParameter("numeroCamisa", request.numeroCamisa())
                                .setParameter("campeonatoTimeId", campeonatoTimeId)
                                .setParameter("atletaId", atletaId)
                                .executeUpdate();
                if (updated == 0)
                        throw new IllegalStateException("Atleta não encontrado neste time.");

                UUID campeonatoAtletaId = (UUID) entityManager.createNativeQuery("""
                                SELECT id
                                FROM operational.campeonato_atletas
                                WHERE campeonato_time_id = :campeonatoTimeId
                                  AND atleta_id = :atletaId
                                """)
                                .setParameter("campeonatoTimeId", campeonatoTimeId)
                                .setParameter("atletaId", atletaId)
                                .getSingleResult();

                eventPublisherService.publish("CampeonatoAtleta", campeonatoAtletaId.toString(),
                                "CampeonatoAtletaAtualizado", java.util.Map.of(
                                                "campeonatoAtletaId", campeonatoAtletaId.toString(),
                                                "campeonatoTimeId", campeonatoTimeId.toString(),
                                                "atletaId", atletaId.toString()));
        }

        @GetMapping("/campeonato/{campeonatoTimeId}/atletas")
        @Transactional(readOnly = true)
        @SuppressWarnings("unchecked")
        public List<AtletaRosterResponse> listAtletasDoCampeonatoTime(@PathVariable UUID campeonatoTimeId) {
                CampeonatoTime ct = campeonatoTimeRepository.findById(campeonatoTimeId)
                                .orElseThrow(() -> new IllegalStateException("Equipe do campeonato não encontrada."));
                if (ct.getTime() == null)
                        return List.of();
                List<Object[]> rows = entityManager
                                .createNativeQuery(
                                                """
                                                                SELECT p.id,
                                                                       COALESCE(NULLIF(p.nome_exibicao, ''), p.nome_completo) AS nome,
                                                                       p.avatar_url,
                                                                       ca.status,
                                                                       ca.numero_camisa
                                                                FROM operational.campeonato_atletas ca
                                                                JOIN operational.profiles p ON p.id = ca.atleta_id
                                                                WHERE ca.campeonato_time_id = :campeonatoTimeId
                                                                ORDER BY ca.numero_camisa ASC NULLS LAST, COALESCE(NULLIF(p.nome_exibicao, ''), p.nome_completo) ASC
                                                                """)
                                .setParameter("campeonatoTimeId", campeonatoTimeId)
                                .getResultList();

                return rows.stream().map(r -> {
                        Integer numeroCamisa = null;
                        if (r[4] instanceof Number n)
                                numeroCamisa = n.intValue();
                        return new AtletaRosterResponse(
                                        (UUID) r[0],
                                        (String) r[1],
                                        (String) r[2],
                                        (String) r[3],
                                        numeroCamisa);
                }).toList();
        }

        @PostMapping("/campeonato/{campeonatoTimeId}/staff")
        @ResponseStatus(HttpStatus.CREATED)
        @PreAuthorize("isAuthenticated()")
        public EquipeStaffResponse adicionarStaff(@PathVariable UUID campeonatoTimeId,
                        @Valid @RequestBody AddStaffRequest request) {
                CampeonatoTime ct = campeonatoTimeRepository.findById(campeonatoTimeId)
                                .orElseThrow(() -> new IllegalStateException("Equipe do campeonato não encontrada."));

                EquipeStaff staff = new EquipeStaff();
                staff.setCampeonatoTime(ct);
                staff.setUserId(request.userId());
                staff.setNome(request.nome());
                staff.setCargo(request.cargo());
                staff.setCriadoEm(OffsetDateTime.now());

                return EquipeStaffResponse.from(equipeStaffRepository.save(staff));
        }

        @GetMapping("/campeonato/{campeonatoTimeId}/staff")
        @Transactional(readOnly = true)
        public List<EquipeStaffResponse> listStaffDoCampeonatoTime(@PathVariable UUID campeonatoTimeId) {
                return equipeStaffRepository.findAll().stream()
                                .filter(s -> s.getCampeonatoTime() != null && campeonatoTimeId.equals(s.getCampeonatoTime().getId()))
                                .map(EquipeStaffResponse::from)
                                .toList();
        }

        public record CreateTimeAtleticaRequest(
                        @NotNull UUID atleticaId,
                        @NotNull UUID modalidadeCatalogoId,
                        @NotBlank String nome,
                        List<UUID> atletaIds) {
        }

        public record UpdateTimeAtleticaRequest(
                        UUID modalidadeCatalogoId,
                        String nome) {
        }

        public record InscricaoTimeRequest(
                        @NotNull UUID campeonatoModalidadeId,
                        @NotNull UUID timeAtleticaId,
                        String nomeExibicao) {
        }

        public record TimeAtleticaResponse(
                        UUID id,
                        UUID atleticaId,
                        String atleticaNome,
                        String nome,
                        UUID modalidadeCatalogoId,
                        String modalidadeNome,
                        String genero) {
                public static TimeAtleticaResponse from(TimeAtletica time) {
                        return new TimeAtleticaResponse(
                                        time.getId(),
                                        time.getAtletica() != null ? time.getAtletica().getId() : null,
                                        time.getAtletica() != null ? time.getAtletica().getNome() : null,
                                        time.getNome(),
                                        time.getModalidade() != null ? time.getModalidade().getId() : null,
                                        time.getModalidade() != null ? time.getModalidade().getNome() : null,
                                        time.getModalidade() != null ? time.getModalidade().getGenero() : null);
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
                        String status) {
                public static CampeonatoTimeResponse from(CampeonatoTime time) {
                        return new CampeonatoTimeResponse(
                                        time.getId(),
                                        time.getCampeonato() != null ? time.getCampeonato().getId() : null,
                                        time.getCampeonato() != null ? time.getCampeonato().getNome() : null,
                                        time.getCampeonatoModalidade() != null ? time.getCampeonatoModalidade().getId()
                                                        : null,
                                        time.getTime() != null ? time.getTime().getId() : null,
                                        time.getNomeEquipe(),
                                        time.getTime() != null && time.getTime().getAtletica() != null
                                                        ? time.getTime().getAtletica().getNome()
                                                        : null,
                                        time.getCampeonatoModalidade() != null
                                                        && time.getCampeonatoModalidade().getModalidade() != null
                                                                        ? time.getCampeonatoModalidade().getModalidade()
                                                                                        .getNome()
                                                                        : null,
                                        time.getStatus());
                }
        }

        public record AtletaRosterResponse(
                        UUID id,
                        String nome,
                        String fotoUrl,
                        String status,
                        Integer numeroCamisa) {
        }

        public record AtualizarNumeroCamisaRequest(
                        @Min(value = 0, message = "Número da camisa deve ser maior ou igual a 0.") @Max(value = 999, message = "Número da camisa deve ser menor ou igual a 999.") Integer numeroCamisa) {
        }

        public record AddAtletasRequest(
                        @NotNull List<UUID> atletaIds) {
        }

        public record AddStaffRequest(
                        UUID userId,
                        @NotBlank String nome,
                        @NotBlank String cargo) {
        }

        public record EquipeStaffResponse(
                        UUID id,
                        UUID userId,
                        String nome,
                        String cargo) {
                public static EquipeStaffResponse from(EquipeStaff staff) {
                        return new EquipeStaffResponse(
                                        staff.getId(),
                                        staff.getUserId(),
                                        staff.getNome(),
                                        staff.getCargo());
                }
        }
}
