package com.nkw.backapisumula.competicao.api;

import com.nkw.backapisumula.cadastros.Atletica;
import com.nkw.backapisumula.cadastros.repo.AtleticaMembroRepository;
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
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
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
        private final AtleticaMembroRepository atleticaMembroRepository;

        @Autowired
        private EntityManager entityManager;

        public TimesController(TimeAtleticaRepository timeAtleticaRepository,
                        CampeonatoTimeRepository campeonatoTimeRepository,
                        ModalidadeCatalogoRepository modalidadeCatalogoRepository,
                        CampeonatoModalidadeRepository campeonatoModalidadeRepository,
                        EventPublisherService eventPublisherService,
                        EquipeStaffRepository equipeStaffRepository,
                        AtleticaMembroRepository atleticaMembroRepository) {
                this.timeAtleticaRepository = timeAtleticaRepository;
                this.campeonatoTimeRepository = campeonatoTimeRepository;
                this.modalidadeCatalogoRepository = modalidadeCatalogoRepository;
                this.campeonatoModalidadeRepository = campeonatoModalidadeRepository;
                this.eventPublisherService = eventPublisherService;
                this.equipeStaffRepository = equipeStaffRepository;
                this.atleticaMembroRepository = atleticaMembroRepository;
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

                TimeAtletica saved = timeAtleticaRepository.save(time);
                syncAtletasTimePermanente(saved, request.atletaIds());
                return TimeAtleticaResponse.from(saved);
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

                TimeAtletica saved = timeAtleticaRepository.save(time);
                if (request.atletaIds() != null) {
                        syncAtletasTimePermanente(saved, request.atletaIds());
                }

                return TimeAtleticaResponse.from(saved);
        }

        @DeleteMapping("/atletica/{timeId}")
        @ResponseStatus(HttpStatus.NO_CONTENT)
        @PreAuthorize("isAuthenticated()")
        public void deleteTimeAtletica(@PathVariable UUID timeId) {
                timeAtleticaRepository.deleteById(timeId);
        }

        @GetMapping("/atletica/{timeId}/atletas")
        @Transactional(readOnly = true)
        @SuppressWarnings("unchecked")
        public List<TimeAtletaResponse> listAtletasTimePermanente(@PathVariable UUID timeId) {
                timeAtleticaRepository.findById(timeId)
                                .orElseThrow(() -> new IllegalStateException("Time da atlética não encontrado."));

                List<Object[]> rows = entityManager.createNativeQuery("""
                                SELECT p.id,
                                       COALESCE(NULLIF(p.nome_exibicao, ''), p.nome_completo) AS nome,
                                       p.email,
                                       p.avatar_url
                                FROM operational.time_atletica_atletas taa
                                JOIN operational.profiles p ON p.id = taa.atleta_id
                                WHERE taa.time_atletica_id = :timeId
                                  AND taa.status = 'ATIVO'
                                ORDER BY COALESCE(NULLIF(p.nome_exibicao, ''), p.nome_completo) ASC
                                """)
                                .setParameter("timeId", timeId)
                                .getResultList();

                return rows.stream()
                                .map(row -> new TimeAtletaResponse(
                                                (UUID) row[0],
                                                (String) row[1],
                                                (String) row[2],
                                                (String) row[3]))
                                .toList();
        }

        @PostMapping("/atletica/{timeId}/atletas")
        @ResponseStatus(HttpStatus.CREATED)
        @PreAuthorize("isAuthenticated()")
        public void adicionarAtletasTimePermanente(@PathVariable UUID timeId,
                        @Valid @RequestBody AddAtletasRequest request) {
                TimeAtletica time = timeAtleticaRepository.findById(timeId)
                                .orElseThrow(() -> new IllegalStateException("Time da atlética não encontrado."));
                syncAtletasTimePermanente(time, request.atletaIds());
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
                UUID campeonatoAtleticaId = ensureCampeonatoAtletica(
                                campeonatoModalidade.getCampeonato().getId(),
                                timeAtletica.getAtletica().getId());

                campeonatoTime.setCampeonatoAtleticaId(campeonatoAtleticaId);
                campeonatoTime.setCriadoEm(OffsetDateTime.now());

                CampeonatoTime saved = campeonatoTimeRepository.save(campeonatoTime);
                seedCampeonatoAtletas(saved);
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
                        String nome,
                        List<UUID> atletaIds) {
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

        public record TimeAtletaResponse(
                        UUID id,
                        String nome,
                        String email,
                        String fotoUrl) {
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

        private void syncAtletasTimePermanente(TimeAtletica time, List<UUID> atletaIds) {
                List<UUID> requestedIds = atletaIds == null
                                ? List.of()
                                : atletaIds.stream()
                                                .filter(java.util.Objects::nonNull)
                                                .distinct()
                                                .toList();

                validateAtletasPertencemAoElenco(time.getAtletica().getId(), requestedIds);

                entityManager.createNativeQuery("""
                                DELETE FROM operational.time_atletica_atletas
                                WHERE time_atletica_id = :timeId
                                """)
                                .setParameter("timeId", time.getId())
                                .executeUpdate();

                for (UUID atletaId : requestedIds) {
                        entityManager.createNativeQuery("""
                                        INSERT INTO operational.time_atletica_atletas (
                                                id,
                                                time_atletica_id,
                                                atleta_id,
                                                status,
                                                adicionado_em
                                        ) VALUES (
                                                gen_random_uuid(),
                                                :timeId,
                                                :atletaId,
                                                'ATIVO',
                                                now()
                                        )
                                        """)
                                        .setParameter("timeId", time.getId())
                                        .setParameter("atletaId", atletaId)
                                        .executeUpdate();
                }
        }

        private void validateAtletasPertencemAoElenco(UUID atleticaId, List<UUID> atletaIds) {
                if (atletaIds.isEmpty()) {
                        return;
                }

                Set<UUID> atletasAtivosDaAtletica = atleticaMembroRepository
                                .findByAtletica_IdOrderByCriadoEmAsc(atleticaId)
                                .stream()
                                .filter(membro -> membro.getUser() != null && membro.getUser().getId() != null)
                                .filter(membro -> "ATHLETE".equalsIgnoreCase(membro.getPapelCodigo()))
                                .filter(membro -> "ATIVO".equalsIgnoreCase(membro.getStatus()))
                                .map(membro -> membro.getUser().getId())
                                .collect(java.util.stream.Collectors.toCollection(LinkedHashSet::new));

                boolean hasInvalidAthlete = atletaIds.stream()
                                .anyMatch(atletaId -> !atletasAtivosDaAtletica.contains(atletaId));

                if (hasInvalidAthlete) {
                        throw new IllegalArgumentException(
                                        "Selecione apenas atletas ativos que pertencem ao elenco desta atlética.");
                }
        }

        @SuppressWarnings("unchecked")
        private void seedCampeonatoAtletas(CampeonatoTime campeonatoTime) {
                List<Object[]> conflitos = entityManager.createNativeQuery("""
                                SELECT DISTINCT p.id,
                                       COALESCE(NULLIF(p.nome_exibicao, ''), p.nome_completo) AS nome
                                FROM operational.time_atletica_atletas taa
                                JOIN operational.campeonato_atletas ca
                                  ON ca.atleta_id = taa.atleta_id
                                 AND ca.campeonato_id = :campeonatoId
                                 AND ca.status = 'ATIVO'
                                JOIN operational.profiles p ON p.id = taa.atleta_id
                                WHERE taa.time_atletica_id = :timeAtleticaId
                                  AND taa.status = 'ATIVO'
                                """)
                                .setParameter("campeonatoId", campeonatoTime.getCampeonato().getId())
                                .setParameter("timeAtleticaId", campeonatoTime.getTime().getId())
                                .getResultList();

                if (!conflitos.isEmpty()) {
                        String nomes = conflitos.stream()
                                        .map(row -> (String) row[1])
                                        .filter(java.util.Objects::nonNull)
                                        .distinct()
                                        .limit(5)
                                        .reduce((a, b) -> a + ", " + b)
                                        .orElse("um ou mais atletas");
                        throw new IllegalStateException(
                                        "Alguns atletas deste time já estão inscritos neste campeonato: " + nomes + ".");
                }

                entityManager.createNativeQuery("""
                                INSERT INTO operational.campeonato_atletas (
                                        id,
                                        campeonato_id,
                                        atletica_id,
                                        campeonato_time_id,
                                        atleta_id,
                                        status,
                                        inscrito_em
                                )
                                SELECT gen_random_uuid(),
                                       :campeonatoId,
                                       :atleticaId,
                                       :campeonatoTimeId,
                                       taa.atleta_id,
                                       'ATIVO',
                                       now()
                                FROM operational.time_atletica_atletas taa
                                WHERE taa.time_atletica_id = :timeAtleticaId
                                  AND taa.status = 'ATIVO'
                                """)
                                .setParameter("campeonatoId", campeonatoTime.getCampeonato().getId())
                                .setParameter("atleticaId", campeonatoTime.getTime().getAtletica().getId())
                                .setParameter("campeonatoTimeId", campeonatoTime.getId())
                                .setParameter("timeAtleticaId", campeonatoTime.getTime().getId())
                                .executeUpdate();
        }

        private UUID ensureCampeonatoAtletica(UUID campeonatoId, UUID atleticaId) {
                List<?> existingIds = entityManager.createNativeQuery(
                                "SELECT id FROM operational.campeonato_atleticas WHERE campeonato_id = :campeonatoId AND atletica_id = :atleticaId")
                                .setParameter("campeonatoId", campeonatoId)
                                .setParameter("atleticaId", atleticaId)
                                .getResultList();

                if (!existingIds.isEmpty()) {
                        return (UUID) existingIds.get(0);
                }

                UUID createdId = UUID.randomUUID();
                entityManager.createNativeQuery("""
                                INSERT INTO operational.campeonato_atleticas (
                                        id,
                                        campeonato_id,
                                        atletica_id,
                                        criado_em
                                ) VALUES (
                                        :id,
                                        :campeonatoId,
                                        :atleticaId,
                                        now()
                                )
                                """)
                                .setParameter("id", createdId)
                                .setParameter("campeonatoId", campeonatoId)
                                .setParameter("atleticaId", atleticaId)
                                .executeUpdate();

                return createdId;
        }
}
