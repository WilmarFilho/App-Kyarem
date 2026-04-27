package com.nkw.backapisumula.partidas.service;

import com.nkw.backapisumula.cadastros.Atleta;
import com.nkw.backapisumula.cadastros.TipoEvento;
import com.nkw.backapisumula.cadastros.repo.AtletaRepository;
import com.nkw.backapisumula.cadastros.repo.TipoEventoRepository;
import com.nkw.backapisumula.common.outbox.EventPublisherService;
import com.nkw.backapisumula.competicao.CampeonatoTime;
import com.nkw.backapisumula.competicao.repo.CampeonatoTimeRepository;
import com.nkw.backapisumula.identity.Profile;
import com.nkw.backapisumula.identity.repo.ProfileRepository;
import com.nkw.backapisumula.partidas.EventoPartida;
import com.nkw.backapisumula.partidas.Partida;
import com.nkw.backapisumula.partidas.repo.EventoPartidaRepository;
import com.nkw.backapisumula.partidas.repo.PartidaArbitroRepository;
import com.nkw.backapisumula.partidas.repo.PartidaRepository;
import com.nkw.backapisumula.config.FirebaseCloudMessagingService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

import static java.util.Map.entry;

@Service
public class EventoPartidaService {

    // Mapeamento de nomes crus do banco → nomes amigáveis para notificações
    private static final Map<String, String> FRIENDLY_NAMES = Map.ofEntries(
        entry("INICIO_1_TEMPO", "Início do 1° Tempo"),
        entry("FIM_1_TEMPO", "Fim do 1° Tempo"),
        entry("FIM_2_TEMPO", "Fim do 2° Tempo"),
        entry("INICIO_2_TEMPO", "Início do 2° Tempo"),
        entry("FIM_PARTIDA", "Fim da Partida"),
        entry("GOL", "⚽ Gol"),
        entry("FALTA", "Falta"),
        entry("CARTAO_AMARELO", "\uD83D\uDFE8 Cartão Amarelo"),
        entry("CARTAO_VERMELHO", "\uD83D\uDFE5 Cartão Vermelho"),
        entry("SUBSTITUICAO", "\uD83D\uDD04 Substituição"),
        entry("PENALTI_MARCADO", "Pênalti Marcado"),
        entry("PENALTI", "⚽ Pênalti"),
        entry("PENALTI_PERDIDO", "Pênalti Perdido"),
        entry("ARREMESO_DE_META", "Arremesso de Meta"),
        entry("TIRO_DE_CANTO", "Tiro de Canto"),
        entry("TIRO_DE_SAIDA", "Tiro de Saída"),
        entry("TIRO_LATERAL", "Tiro Lateral"),
        entry("TIRO_LIVRE_DIRETO", "Tiro Livre Direto"),
        entry("TIRO_LIVRE_INDIRETO", "Tiro Livre Indireto"),
        entry("INTERVALO", "⏸️ Intervalo"),
        entry("PRORROGACAO", "⏱️ Prorrogação"),
        entry("PRORROGACAO_DADA", "⏱️ Prorrogação Definida"),
        entry("ACRESCIMO", "⏱️ Acréscimo"),
        entry("ACRESCIMO_DADO", "⏱️ Acréscimo Definido"),
        entry("PAUSA_TECNICA", "⏸️ Pausa Técnica"),
        entry("FIM_PAUSA_TECNICA", "▶️ Fim da Pausa Técnica"),
        entry("PARTIDA_RETOMADA", "▶️ Partida Retomada"),
        entry("PARTIDA_PAUSADA", "⏸️ Partida Pausada")
    );

    private static String friendlyName(String rawName) {
        if (rawName == null) return "Evento";
        return FRIENDLY_NAMES.getOrDefault(rawName.trim().toUpperCase(), rawName);
    }

    private static String buildNotificationBody(EventoPartida ev) {
        String nome = friendlyName(ev.getTipoEvento().getNome());
        StringBuilder sb = new StringBuilder(nome);

        if (ev.getAtleta() != null) {
            sb.append(" — ").append(ev.getAtleta().getNome());
        }

        if (ev.getDadosExtras() != null) {
            sb.append(": ").append(ev.getDadosExtras().toString());
        }

        return sb.toString();
    }

    public static boolean isGoalEvent(TipoEvento tipoEvento) {
        if (tipoEvento == null || tipoEvento.getNome() == null) return false;
        String nome = tipoEvento.getNome().trim().toUpperCase();
        return nome.equals("GOL") || nome.equals("PENALTI_MARCADO") || nome.equals("PENALTI_CONVERTIDO");
    }

    public record AddEventoInput(
            UUID campeonatoTimeId,
            UUID atletaId,
            UUID atletaSaiId,
            boolean isSubstitution,
            UUID tipoEventoId,
            String minutoSegundo,
            String descricaoDetalhada,
            String localEventoId
    ) {}

    public record AddEventoGeralInput(
            UUID tipoEventoId,
            String minutoSegundo,
            String descricaoDetalhada,
            String localEventoId,
            UUID campeonatoTimeId
    ) {}

    private final EventoPartidaRepository repo;
    private final PartidaRepository partidaRepo;
    private final PartidaArbitroRepository partidaArbitroRepo;
    private final CampeonatoTimeRepository campeonatoTimeRepo;
    private final AtletaRepository atletaRepo;
    private final TipoEventoRepository tipoEventoRepo;
    private final FirebaseCloudMessagingService firebaseMessagingService;
    private final EventPublisherService eventPublisherService;
    private final ProfileRepository profileRepo;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public EventoPartidaService(EventoPartidaRepository repo,
                               PartidaRepository partidaRepo,
                               PartidaArbitroRepository partidaArbitroRepo,
                               CampeonatoTimeRepository campeonatoTimeRepo,
                               AtletaRepository atletaRepo,
                               TipoEventoRepository tipoEventoRepo,
                               FirebaseCloudMessagingService firebaseMessagingService,
                               EventPublisherService eventPublisherService,
                               ProfileRepository profileRepo) {
        this.repo = repo;
        this.partidaRepo = partidaRepo;
        this.partidaArbitroRepo = partidaArbitroRepo;
        this.campeonatoTimeRepo = campeonatoTimeRepo;
        this.atletaRepo = atletaRepo;
        this.tipoEventoRepo = tipoEventoRepo;
        this.firebaseMessagingService = firebaseMessagingService;
        this.eventPublisherService = eventPublisherService;
        this.profileRepo = profileRepo;
    }

    public List<EventoPartida> list(UUID partidaId) {
        return repo.findByPartida_IdOrderByCriadoEmAsc(partidaId);
    }

    @Transactional
    public EventoPartida updateEvento(UUID partidaId,
                                      UUID eventoId,
                                      UUID userId,
                                      boolean isArbitroOnly,
                                      UUID campeonatoTimeId,
                                      UUID atletaId,
                                      UUID atletaSaiId,
                                      boolean isSubstitution,
                                      UUID tipoEventoId,
                                      String minutoSegundo,
                                      String descricaoDetalhada) {

        Partida partida = partidaRepo.findById(partidaId)
                .orElseThrow(() -> new IllegalStateException("Partida não encontrada."));

        if (PartidaService.isStatusFechada(partida.getStatus())) {
            throw new IllegalStateException("Não é possível editar eventos de partidas com súmula fechada.");
        }

        if (isArbitroOnly && !partidaArbitroRepo.existsByPartida_IdAndArbitro_Id(partidaId, userId)) {
            throw new IllegalStateException("Árbitro não está atribuído a esta partida.");
        }

        EventoPartida ev = repo.findById(eventoId)
                .orElseThrow(() -> new IllegalStateException("Evento não encontrado."));

        if (ev.getPartida() == null || !ev.getPartida().getId().equals(partidaId)) {
            throw new IllegalStateException("Evento não pertence à partida informada.");
        }

        if (campeonatoTimeId != null) {
            CampeonatoTime time = campeonatoTimeRepo.findById(campeonatoTimeId)
                    .orElseThrow(() -> new IllegalStateException("Time não encontrado."));
            validateTimeNaPartida(partida, time.getId());
            ev.setCampeonatoTime(time);
        }

        if (tipoEventoId != null) {
            TipoEvento tipoEvento = tipoEventoRepo.findById(tipoEventoId)
                    .orElseThrow(() -> new IllegalStateException("Tipo de evento não encontrado."));
            validateTipoEventoEsporte(partida, tipoEvento);
            ev.setTipoEvento(tipoEvento);
        }

        if (atletaId != null) {
            Atleta atleta = atletaRepo.findById(atletaId)
                    .orElseThrow(() -> new IllegalStateException("Atleta não encontrado."));
            ev.setAtleta(atleta);
        } else {
            ev.setAtleta(null);
        }

        if (atletaSaiId != null) {
            Atleta atletaSai = atletaRepo.findById(atletaSaiId)
                    .orElseThrow(() -> new IllegalStateException("Atleta de saída não encontrado."));
            ev.setAtletaSai(atletaSai);
        } else {
            ev.setAtletaSai(null);
        }

        ev.setIsSubstitution(isSubstitution);
        if (minutoSegundo != null && !minutoSegundo.isBlank()) ev.setMinutoSegundo(minutoSegundo);
        ev.setDescricaoDetalhada(descricaoDetalhada);

        return repo.save(ev);
    }

    @Transactional
    public void deleteEvento(UUID partidaId, UUID eventoId, UUID userId, boolean isArbitroOnly) {

        Partida partida = partidaRepo.findById(partidaId)
                .orElseThrow(() -> new IllegalStateException("Partida não encontrada."));

        if (PartidaService.isStatusFechada(partida.getStatus())) {
            throw new IllegalStateException("Não é possível excluir eventos de partidas com súmula fechada.");
        }

        if (isArbitroOnly && !partidaArbitroRepo.existsByPartida_IdAndArbitro_Id(partidaId, userId)) {
            throw new IllegalStateException("Árbitro não está atribuído a esta partida.");
        }

        EventoPartida ev = repo.findById(eventoId)
                .orElseThrow(() -> new IllegalStateException("Evento não encontrado."));

        if (ev.getPartida() == null || !ev.getPartida().getId().equals(partidaId)) {
            throw new IllegalStateException("Evento não pertence à partida informada.");
        }

        repo.delete(ev);
    }

    /**
     * Cria eventos gerais da partida (sem time/atleta específico), em lote.
     * Transacional: se 1 evento falhar, nada é persistido.
     */
    @Transactional
    public List<EventoPartida> addBatchGerais(UUID partidaId,
                                              UUID userId,
                                              boolean isArbitroOnly,
                                              List<AddEventoGeralInput> reqs) {

        if (reqs == null || reqs.isEmpty()) {
            throw new IllegalStateException("Lista de eventos não pode ser vazia.");
        }

        Partida partida = getPartidaEmAndamento(partidaId, userId, isArbitroOnly);
        UUID esporteId = getEsporteIdDaPartida(partida);

        Set<UUID> tipoEventoIds = new HashSet<>();
        for (AddEventoGeralInput r : reqs) {
            if (r != null && r.tipoEventoId() != null) tipoEventoIds.add(r.tipoEventoId());
        }

        Map<UUID, TipoEvento> tipos = carregarTipos(tipoEventoIds);

        // Idempotência
        Set<String> localIdsRequisicao = collectLocalIds(reqs, r -> r.localEventoId());
        Set<String> localIdsJaExistentes = localIdsRequisicao.isEmpty()
            ? Set.of()
            : repo.findExistingLocalEventoIds(localIdsRequisicao);

        Profile author = profileRepo.findById(userId)
                .orElseThrow(() -> new IllegalStateException("Usuário não encontrado."));

        List<EventoPartida> toSave = new ArrayList<>(reqs.size());
        for (AddEventoGeralInput r : reqs) {
            if (r == null) throw new IllegalStateException("Evento inválido (null) na lista.");
            if (r.tipoEventoId() == null) throw new IllegalStateException("tipoEventoId é obrigatório.");
            if (r.minutoSegundo() == null || r.minutoSegundo().isBlank()) throw new IllegalStateException("minutoSegundo é obrigatório.");

            TipoEvento tipoEvento = tipos.get(r.tipoEventoId());
            if (tipoEvento == null) throw new IllegalStateException("Tipo de evento não encontrado: " + r.tipoEventoId());
            if (!Objects.equals(esporteId, tipoEvento.getEsporte() != null ? tipoEvento.getEsporte().getId() : null)) {
                throw new IllegalStateException("Tipo de evento não pertence ao esporte da modalidade da partida.");
            }
            if (isGoalEvent(tipoEvento)) {
                throw new IllegalStateException("Evento '" + tipoEvento.getNome() + "' requer campeonatoTimeId (use /api/v1/partidas/{id}/eventos).");
            }

            if (r.localEventoId() != null && !r.localEventoId().isBlank()
                    && localIdsJaExistentes.contains(r.localEventoId())) {
                continue; // idempotência: já processado
            }

            EventoPartida ev = new EventoPartida();
            ev.setPartida(partida);
            ev.setTipoEvento(tipoEvento);
            ev.setMinutoSegundo(r.minutoSegundo());
            ev.setCriadoPorUser(author);
            ev.setLocalEventoId(r.localEventoId());
            ev.setDescricaoDetalhada(r.descricaoDetalhada());
            if (r.descricaoDetalhada() != null && !r.descricaoDetalhada().isBlank()) {
                ev.setDadosExtras(objectMapper.valueToTree(Map.of("descricao", r.descricaoDetalhada())));
            }

            if (r.campeonatoTimeId() != null) {
                campeonatoTimeRepo.findById(r.campeonatoTimeId()).ifPresent(ev::setCampeonatoTime);
            }

            toSave.add(ev);
        }

        List<EventoPartida> saved = repo.saveAll(toSave);

        for (EventoPartida ev : saved) {
            String topic = "partida_" + partidaId;
            String title = buildMatchTitle(partida);
            firebaseMessagingService.sendNotificationToTopic(topic, title, buildNotificationBody(ev));

            eventPublisherService.publish("EventoPartida", ev.getId().toString(), "EventoRegistrado", Map.of(
                "partidaId", partidaId.toString(),
                "tipoEvento", ev.getTipoEvento().getNome()
            ));
        }

        return saved;
    }

    /**
     * Cria eventos de equipe/atleta em lote (gols, cartões, substituições, etc).
     * Transacional: se 1 evento falhar, nada é persistido.
     */
    @Transactional
    public List<EventoPartida> addBatch(UUID partidaId,
                                       UUID userId,
                                       boolean isArbitroOnly,
                                       List<AddEventoInput> reqs) {

        if (reqs == null || reqs.isEmpty()) {
            throw new IllegalStateException("Lista de eventos não pode ser vazia.");
        }

        Partida partida = getPartidaEmAndamento(partidaId, userId, isArbitroOnly);
        UUID esporteId = getEsporteIdDaPartida(partida);

        UUID timeAId = partida.getTimeA() == null ? null : partida.getTimeA().getId();
        UUID timeBId = partida.getTimeB() == null ? null : partida.getTimeB().getId();
        if (timeAId == null || timeBId == null) {
            throw new IllegalStateException("Partida sem times A/B vinculados.");
        }

        // Carrega em lote
        Set<UUID> timeIds = new HashSet<>();
        Set<UUID> tipoEventoIds = new HashSet<>();
        Set<UUID> atletaIds = new HashSet<>();

        for (AddEventoInput r : reqs) {
            if (r == null) continue;
            if (r.campeonatoTimeId() != null) timeIds.add(r.campeonatoTimeId());
            if (r.tipoEventoId() != null) tipoEventoIds.add(r.tipoEventoId());
            if (r.atletaId() != null) atletaIds.add(r.atletaId());
            if (r.atletaSaiId() != null) atletaIds.add(r.atletaSaiId());
        }

        Map<UUID, CampeonatoTime> times = new HashMap<>();
        for (CampeonatoTime t : campeonatoTimeRepo.findAllById(timeIds)) {
            times.put(t.getId(), t);
        }

        Map<UUID, TipoEvento> tipos = carregarTipos(tipoEventoIds);

        Map<UUID, Atleta> atletas = new HashMap<>();
        for (Atleta a : atletaRepo.findAllById(atletaIds)) {
            atletas.put(a.getId(), a);
        }

        // Idempotência
        Set<String> localIdsReq = collectLocalIds(reqs, r -> r.localEventoId());
        Set<String> localIdsExistentes = localIdsReq.isEmpty()
            ? Set.of()
            : repo.findExistingLocalEventoIds(localIdsReq);

        Profile author = profileRepo.findById(userId)
                .orElseThrow(() -> new IllegalStateException("Usuário não encontrado."));

        List<EventoPartida> toSave = new ArrayList<>(reqs.size());
        int golsA = 0;
        int golsB = 0;

        for (AddEventoInput r : reqs) {
            if (r == null) throw new IllegalStateException("Evento inválido (null) na lista.");
            if (r.campeonatoTimeId() == null) throw new IllegalStateException("campeonatoTimeId é obrigatório.");
            if (r.tipoEventoId() == null) throw new IllegalStateException("tipoEventoId é obrigatório.");
            if (r.minutoSegundo() == null || r.minutoSegundo().isBlank()) throw new IllegalStateException("minutoSegundo é obrigatório.");

            CampeonatoTime time = times.get(r.campeonatoTimeId());
            if (time == null) throw new IllegalStateException("Time não encontrado: " + r.campeonatoTimeId());
            if (!Objects.equals(r.campeonatoTimeId(), timeAId) && !Objects.equals(r.campeonatoTimeId(), timeBId)) {
                throw new IllegalStateException("Time do evento deve ser um dos times da partida.");
            }

            TipoEvento tipoEvento = tipos.get(r.tipoEventoId());
            if (tipoEvento == null) throw new IllegalStateException("Tipo de evento não encontrado: " + r.tipoEventoId());
            if (!Objects.equals(esporteId, tipoEvento.getEsporte() != null ? tipoEvento.getEsporte().getId() : null)) {
                throw new IllegalStateException("Tipo de evento não pertence ao esporte da modalidade da partida.");
            }

            Atleta atleta = null;
            if (r.atletaId() != null) {
                atleta = atletas.get(r.atletaId());
                if (atleta == null) throw new IllegalStateException("Atleta não encontrado: " + r.atletaId());
            }

            // Idempotência: pula silenciosamente
            if (r.localEventoId() != null && !r.localEventoId().isBlank()
                    && localIdsExistentes.contains(r.localEventoId())) {
                continue;
            }

            EventoPartida ev = new EventoPartida();
            ev.setPartida(partida);
            ev.setCampeonatoTime(time);
            ev.setAtleta(atleta);
            if (r.atletaSaiId() != null) {
                Atleta atletaSai = atletas.get(r.atletaSaiId());
                if (atletaSai == null) {
                    atletaSai = atletaRepo.findById(r.atletaSaiId())
                            .orElseThrow(() -> new IllegalStateException("Atleta de saída não encontrado: " + r.atletaSaiId()));
                }
                ev.setAtletaSai(atletaSai);
            }
            ev.setTipoEvento(tipoEvento);
            ev.setMinutoSegundo(r.minutoSegundo());
            ev.setCriadoPorUser(author);
            ev.setIsSubstitution(r.isSubstitution());
            ev.setDescricaoDetalhada(r.descricaoDetalhada());
            ev.setLocalEventoId(r.localEventoId());
            if (r.descricaoDetalhada() != null && !r.descricaoDetalhada().isBlank()) {
                ev.setDadosExtras(objectMapper.valueToTree(Map.of("descricao", r.descricaoDetalhada())));
            }
            toSave.add(ev);

            if (isGoalEvent(tipoEvento)) {
                if (Objects.equals(r.campeonatoTimeId(), timeAId)) golsA++;
                else golsB++;
            }
        }

        List<EventoPartida> saved = repo.saveAll(toSave);

        // Atualiza placar em batch
        if (golsA > 0 || golsB > 0) {
            int a = partida.getPlacarA() == null ? 0 : partida.getPlacarA();
            int b = partida.getPlacarB() == null ? 0 : partida.getPlacarB();
            partida.setPlacarA(a + golsA);
            partida.setPlacarB(b + golsB);
            partidaRepo.save(partida);
        }

        // Notificações + eventos Outbox
        for (EventoPartida ev : saved) {
            String topic = "partida_" + partidaId;
            String title = buildMatchTitle(partida);
            firebaseMessagingService.sendNotificationToTopic(topic, title, buildNotificationBody(ev));

            eventPublisherService.publish("EventoPartida", ev.getId().toString(), "EventoRegistrado", Map.of(
                "partidaId", partidaId.toString(),
                "tipoEvento", ev.getTipoEvento().getNome(),
                "placarA", partida.getPlacarA(),
                "placarB", partida.getPlacarB()
            ));
        }

        return saved;
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private Partida getPartidaEmAndamento(UUID partidaId, UUID userId, boolean isArbitroOnly) {
        Partida partida = partidaRepo.findById(partidaId)
                .orElseThrow(() -> new IllegalStateException("Partida não encontrada."));
        if (!PartidaService.isStatusEmAndamento(partida.getStatus())) {
            throw new IllegalStateException("Só é possível registrar eventos quando a partida estiver em andamento.");
        }
        if (isArbitroOnly && !partidaArbitroRepo.existsByPartida_IdAndArbitro_Id(partidaId, userId)) {
            throw new IllegalStateException("Árbitro não está atribuído a esta partida.");
        }
        return partida;
    }

    private UUID getEsporteIdDaPartida(Partida partida) {
        if (partida.getModalidade() == null || partida.getModalidade().getEsporte() == null) {
            throw new IllegalStateException("Modalidade da partida sem esporte vinculado.");
        }
        return partida.getModalidade().getEsporte().getId();
    }

    private Map<UUID, TipoEvento> carregarTipos(Set<UUID> ids) {
        Map<UUID, TipoEvento> map = new HashMap<>();
        for (TipoEvento te : tipoEventoRepo.findAllById(ids)) {
            map.put(te.getId(), te);
        }
        return map;
    }

    private void validateTimeNaPartida(Partida partida, UUID timeId) {
        UUID timeAId = partida.getTimeA() == null ? null : partida.getTimeA().getId();
        UUID timeBId = partida.getTimeB() == null ? null : partida.getTimeB().getId();
        if (!Objects.equals(timeId, timeAId) && !Objects.equals(timeId, timeBId)) {
            throw new IllegalStateException("Time do evento deve ser um dos times da partida.");
        }
    }

    private void validateTipoEventoEsporte(Partida partida, TipoEvento tipoEvento) {
        UUID esportePartida = partida.getModalidade() != null && partida.getModalidade().getEsporte() != null
                ? partida.getModalidade().getEsporte().getId() : null;
        UUID esporteEvento = tipoEvento.getEsporte() != null ? tipoEvento.getEsporte().getId() : null;
        if (!Objects.equals(esportePartida, esporteEvento)) {
            throw new IllegalStateException("Tipo de evento não pertence ao esporte da modalidade da partida.");
        }
    }

    private String buildMatchTitle(Partida partida) {
        String nomeA = partida.getTimeA() != null && partida.getTimeA().getTime() != null
                ? partida.getTimeA().getTime().getNome() : "Time A";
        String nomeB = partida.getTimeB() != null && partida.getTimeB().getTime() != null
                ? partida.getTimeB().getTime().getNome() : "Time B";
        return nomeA + " x " + nomeB;
    }

    @FunctionalInterface
    private interface LocalIdExtractor<T> {
        String extract(T item);
    }

    private <T> Set<String> collectLocalIds(List<T> reqs, LocalIdExtractor<T> extractor) {
        Set<String> ids = new HashSet<>();
        for (T r : reqs) {
            if (r != null) {
                String id = extractor.extract(r);
                if (id != null && !id.isBlank()) ids.add(id);
            }
        }
        return ids;
    }
}
