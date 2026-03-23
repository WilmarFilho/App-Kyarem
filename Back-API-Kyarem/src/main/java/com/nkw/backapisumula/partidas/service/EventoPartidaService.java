package com.nkw.backapisumula.partidas.service;

import com.nkw.backapisumula.cadastros.Atleta;
import com.nkw.backapisumula.cadastros.TipoEvento;
import com.nkw.backapisumula.cadastros.repo.AtletaRepository;
import com.nkw.backapisumula.cadastros.repo.TipoEventoRepository;
import com.nkw.backapisumula.competicao.Equipe;
import com.nkw.backapisumula.competicao.EquipeAtletaInscrito;
import com.nkw.backapisumula.competicao.Modalidade;
import com.nkw.backapisumula.competicao.repo.EquipeAtletaInscritoRepository;
import com.nkw.backapisumula.competicao.repo.EquipeRepository;
import com.nkw.backapisumula.partidas.EventoPartida;
import com.nkw.backapisumula.partidas.Partida;
import com.nkw.backapisumula.partidas.repo.EventoPartidaRepository;
import com.nkw.backapisumula.partidas.repo.PartidaArbitroRepository;
import com.nkw.backapisumula.partidas.repo.PartidaRepository;
import com.nkw.backapisumula.config.FirebaseCloudMessagingService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

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
        entry("ARREMESO_DE_META", "Arremesso de Meta"),
        entry("TIRO_DE_CANTO", "Tiro de Canto"),
        entry("TIRO_DE_SAIDA", "Tiro de Saída"),
        entry("TIRO_LATERAL", "Tiro Lateral"),
        entry("PENALTI_PERDIDO", "Pênalti Perdido"),
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

        // Incluir nome do atleta
        if (ev.getIsSubstitution() != null && ev.getIsSubstitution()
                && ev.getAtleta() != null && ev.getAtletaSai() != null) {
            sb.append(" — Entra: ").append(ev.getAtleta().getNome())
              .append(", Sai: ").append(ev.getAtletaSai().getNome());
        } else if (ev.getAtleta() != null) {
            sb.append(" — ").append(ev.getAtleta().getNome());
        }

        // Incluir descrição adicional
        if (ev.getDescricaoDetalhada() != null && !ev.getDescricaoDetalhada().isBlank()) {
            sb.append(": ").append(ev.getDescricaoDetalhada());
        }

        return sb.toString();
    }

    public record AddEventoInput(
            UUID equipeId,
            UUID atletaId,
            UUID atletaSaiId,
            boolean isSubstitution,
            UUID tipoEventoId,
            String tempoCronometro,
            String descricaoDetalhada,
            String localEventoId   
    ) {}

    public record AddEventoGeralInput(
            UUID tipoEventoId,
            String tempoCronometro,
            String descricaoDetalhada,
            String localEventoId   
    ) {}

    private final EventoPartidaRepository repo;
    private final PartidaRepository partidaRepo;
    private final PartidaArbitroRepository partidaArbitroRepo;
    private final EquipeRepository equipeRepo;
    private final AtletaRepository atletaRepo;
    private final TipoEventoRepository tipoEventoRepo;
    private final EquipeAtletaInscritoRepository inscritoRepo;
    private final FirebaseCloudMessagingService firebaseMessagingService;

    public EventoPartidaService(EventoPartidaRepository repo,
                               PartidaRepository partidaRepo,
                               PartidaArbitroRepository partidaArbitroRepo,
                               EquipeRepository equipeRepo,
                               AtletaRepository atletaRepo,
                               TipoEventoRepository tipoEventoRepo,
                               EquipeAtletaInscritoRepository inscritoRepo,
                               FirebaseCloudMessagingService firebaseMessagingService) {
        this.repo = repo;
        this.partidaRepo = partidaRepo;
        this.partidaArbitroRepo = partidaArbitroRepo;
        this.equipeRepo = equipeRepo;
        this.atletaRepo = atletaRepo;
        this.tipoEventoRepo = tipoEventoRepo;
        this.inscritoRepo = inscritoRepo;
        this.firebaseMessagingService = firebaseMessagingService;
    }

    public List<EventoPartida> list(UUID partidaId) {
        return repo.findByPartida_IdOrderByCriadoEmAsc(partidaId);
    }

    @Transactional
    public EventoPartida updateEvento(UUID partidaId,
                                      UUID eventoId,
                                      UUID userId,
                                      boolean isArbitroOnly,
                                      UUID equipeId,
                                      UUID atletaId,
                                      UUID atletaSaiId,
                                      boolean isSubstitution,
                                      UUID tipoEventoId,
                                      String tempoCronometro,
                                      String novaDescricao) {

        Partida partida = partidaRepo.findById(partidaId)
                .orElseThrow(() -> new IllegalStateException("Partida não encontrada."));

        // Não permitir edição em partida fechada
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

        // Valida e atualiza equipe/tipo/atletas usando mesma lógica do add(...)
        if (equipeId != null) {
            Equipe equipe = equipeRepo.findById(equipeId)
                    .orElseThrow(() -> new IllegalStateException("Equipe não encontrada."));

            if (!Objects.equals(equipe.getId(), partida.getEquipeA().getId())
                    && !Objects.equals(equipe.getId(), partida.getEquipeB().getId())) {
                throw new IllegalStateException("Equipe do evento deve ser uma das equipes da partida.");
            }
            ev.setEquipe(equipe);
        }

        if (tipoEventoId != null) {
            TipoEvento tipoEvento = tipoEventoRepo.findById(tipoEventoId)
                    .orElseThrow(() -> new IllegalStateException("Tipo de evento não encontrado."));

            Modalidade modalidade = partida.getModalidade();
            if (modalidade.getEsporte() == null || tipoEvento.getEsporte() == null) {
                throw new IllegalStateException("Modalidade/Tipo de evento sem esporte vinculado.");
            }
            if (!Objects.equals(modalidade.getEsporte().getId(), tipoEvento.getEsporte().getId())) {
                throw new IllegalStateException("Tipo de evento não pertence ao esporte da modalidade da partida.");
            }
            ev.setTipoEvento(tipoEvento);
        }

        if (isSubstitution) {
            if (atletaId == null || atletaSaiId == null) {
                throw new IllegalStateException("Substituição requer atletaId (entra) e atletaSaiId (sai).");
            }
            if (Objects.equals(atletaId, atletaSaiId)) {
                throw new IllegalStateException("Em substituição, atletaId e atletaSaiId devem ser diferentes.");
            }
        }

        if (atletaId != null) {
            Atleta atleta = atletaRepo.findById(atletaId)
                    .orElseThrow(() -> new IllegalStateException("Atleta não encontrado."));
            boolean inscrito = inscritoRepo.existsByEquipe_IdAndAtleta_Id(equipeId, atletaId);
            if (!inscrito) {
                throw new IllegalStateException("Atleta não está inscrito nesta equipe.");
            }
            ev.setAtleta(atleta);
        } else {
            ev.setAtleta(null);
        }

        if (atletaSaiId != null) {
            Atleta atletaSai = atletaRepo.findById(atletaSaiId)
                    .orElseThrow(() -> new IllegalStateException("Atleta (sai) não encontrado."));
            boolean inscritoSai = inscritoRepo.existsByEquipe_IdAndAtleta_Id(equipeId, atletaSaiId);
            if (!inscritoSai) {
                throw new IllegalStateException("Atleta (sai) não está inscrito nesta equipe.");
            }
            ev.setAtletaSai(atletaSai);
        } else {
            ev.setAtletaSai(null);
        }

        ev.setIsSubstitution(isSubstitution);

        if (tempoCronometro != null && !tempoCronometro.isBlank()) {
            ev.setTempoCronometro(tempoCronometro);
        }

        ev.setDescricaoDetalhada(novaDescricao);
        return repo.save(ev);
    }

    @Transactional
    public void deleteEvento(UUID partidaId,
                             UUID eventoId,
                             UUID userId,
                             boolean isArbitroOnly) {

        Partida partida = partidaRepo.findById(partidaId)
                .orElseThrow(() -> new IllegalStateException("Partida não encontrada."));

        // Não permitir exclusão em partida fechada
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
     * Cria eventos gerais da partida (sem equipe/atleta), em lote.
     *
     * A operação é transacional: se 1 evento falhar, nada é persistido.
     */
    @Transactional
    public List<EventoPartida> addBatchGerais(UUID partidaId,
                                              UUID userId,
                                              boolean isArbitroOnly,
                                              List<AddEventoGeralInput> reqs) {

        if (reqs == null || reqs.isEmpty()) {
            throw new IllegalStateException("Lista de eventos não pode ser vazia.");
        }

        Partida partida = partidaRepo.findById(partidaId)
                .orElseThrow(() -> new IllegalStateException("Partida não encontrada."));

        if (!PartidaService.isStatusEmAndamento(partida.getStatus())) {
            throw new IllegalStateException("Só é possível registrar eventos quando a partida estiver em andamento.");
        }

        if (isArbitroOnly && !partidaArbitroRepo.existsByPartida_IdAndArbitro_Id(partidaId, userId)) {
            throw new IllegalStateException("Árbitro não está atribuído a esta partida.");
        }

        Modalidade modalidade = partida.getModalidade();
        if (modalidade == null || modalidade.getEsporte() == null) {
            throw new IllegalStateException("Modalidade da partida sem esporte vinculado.");
        }
        UUID esporteIdDaPartida = modalidade.getEsporte().getId();

        // Carrega tipos em lote
        Set<UUID> tipoEventoIds = new HashSet<>();
        for (AddEventoGeralInput r : reqs) {
            if (r == null) continue;
            if (r.tipoEventoId() != null) tipoEventoIds.add(r.tipoEventoId());
        }

        Map<UUID, TipoEvento> tipos = new HashMap<>();
        for (TipoEvento te : tipoEventoRepo.findAllById(tipoEventoIds)) {
            tipos.put(te.getId(), te);
        }

        // ── Idempotência ──────────────────────────────────────────────────────────
        Set<String> localIdsRequisicao = new HashSet<>();
        for (AddEventoGeralInput r : reqs) {
            if (r != null && r.localEventoId() != null && !r.localEventoId().isBlank()) {
                localIdsRequisicao.add(r.localEventoId());
            }
        }
        Set<String> localIdsJaExistentes = localIdsRequisicao.isEmpty()
            ? Set.of()
            : repo.findExistingLocalEventoIds(localIdsRequisicao);
        // ─────────────────────────────────────────────────────────────────────────

        List<EventoPartida> toSave = new ArrayList<>(reqs.size());
        for (AddEventoGeralInput r : reqs) {
            if (r == null) {
                throw new IllegalStateException("Evento inválido (null) na lista.");
            }
            if (r.tipoEventoId() == null) {
                throw new IllegalStateException("tipoEventoId é obrigatório.");
            }
            if (r.tempoCronometro() == null || r.tempoCronometro().isBlank()) {
                throw new IllegalStateException("tempoCronometro é obrigatório.");
            }

            TipoEvento tipoEvento = tipos.get(r.tipoEventoId());
            if (tipoEvento == null) {
                throw new IllegalStateException("Tipo de evento não encontrado: " + r.tipoEventoId());
            }
            if (tipoEvento.getEsporte() == null || tipoEvento.getEsporte().getId() == null) {
                throw new IllegalStateException("Tipo de evento sem esporte vinculado.");
            }
            if (!Objects.equals(esporteIdDaPartida, tipoEvento.getEsporte().getId())) {
                throw new IllegalStateException("Tipo de evento não pertence ao esporte da modalidade da partida.");
            }

            // Se for gol, precisa de equipe para atualizar placar -> use /eventos
            if (tipoEvento.getNome() != null && tipoEvento.getNome().trim().equalsIgnoreCase("gol")) {
                throw new IllegalStateException("Evento 'gol' requer equipeId (use /api/v1/partidas/{partidaId}/eventos). ");
            }

            if (r.localEventoId() != null 
                && !r.localEventoId().isBlank()
                && localIdsJaExistentes.contains(r.localEventoId())) {
                continue;
            }

            EventoPartida ev = new EventoPartida();
            ev.setLocalEventoId(r.localEventoId());

            ev.setPartida(partida);
            ev.setTipoEvento(tipoEvento);
            ev.setTempoCronometro(r.tempoCronometro());
            ev.setDescricaoDetalhada(r.descricaoDetalhada());
            ev.setIsSubstitution(false);

            toSave.add(ev);
        }

        List<EventoPartida> saved = repo.saveAll(toSave);

        // Send push notifications
        for (EventoPartida ev : saved) {
            String topic = "partida_" + partidaId.toString();
            String title = (partida.getEquipeA() != null ? partida.getEquipeA().getNomeEquipe() : "Equipe A") + " x " + 
                           (partida.getEquipeB() != null ? partida.getEquipeB().getNomeEquipe() : "Equipe B");
            String body = buildNotificationBody(ev);
            firebaseMessagingService.sendNotificationToTopic(topic, title, body);
        }

        return saved;
    }

    /**
     * Cria eventos em lote para reduzir quantidade de requisições HTTP.
     *
     * Regras/validações seguem a mesma lógica do registro unitário de evento (método add).
     * A operação é transacional: se 1 evento falhar, nada é persistido.
     */
    @Transactional
    public List<EventoPartida> addBatch(UUID partidaId,
                                       UUID userId,
                                       boolean isArbitroOnly,
                                       List<AddEventoInput> reqs) {

        if (reqs == null || reqs.isEmpty()) {
            throw new IllegalStateException("Lista de eventos não pode ser vazia.");
        }

        Partida partida = partidaRepo.findById(partidaId)
                .orElseThrow(() -> new IllegalStateException("Partida não encontrada."));

        if (!PartidaService.isStatusEmAndamento(partida.getStatus())) {
            throw new IllegalStateException("Só é possível registrar eventos quando a partida estiver em andamento.");
        }

        if (isArbitroOnly && !partidaArbitroRepo.existsByPartida_IdAndArbitro_Id(partidaId, userId)) {
            throw new IllegalStateException("Árbitro não está atribuído a esta partida.");
        }

        UUID equipeAId = partida.getEquipeA() == null ? null : partida.getEquipeA().getId();
        UUID equipeBId = partida.getEquipeB() == null ? null : partida.getEquipeB().getId();
        if (equipeAId == null || equipeBId == null) {
            throw new IllegalStateException("Partida sem equipes A/B vinculadas.");
        }

        Modalidade modalidade = partida.getModalidade();
        if (modalidade == null || modalidade.getEsporte() == null) {
            throw new IllegalStateException("Modalidade da partida sem esporte vinculado.");
        }
        UUID esporteIdDaPartida = modalidade.getEsporte().getId();

        // 1) Carrega em lote Equipes / Tipos de Evento / Atletas para reduzir queries
        Set<UUID> equipeIds = new HashSet<>();
        Set<UUID> tipoEventoIds = new HashSet<>();
        Set<UUID> atletaIds = new HashSet<>();

        for (AddEventoInput r : reqs) {
            if (r == null) continue;
            if (r.equipeId() != null) equipeIds.add(r.equipeId());
            if (r.tipoEventoId() != null) tipoEventoIds.add(r.tipoEventoId());
            if (r.atletaId() != null) atletaIds.add(r.atletaId());
            if (r.atletaSaiId() != null) atletaIds.add(r.atletaSaiId());
        }

        Map<UUID, Equipe> equipes = new HashMap<>();
        for (Equipe e : equipeRepo.findAllById(equipeIds)) {
            equipes.put(e.getId(), e);
        }

        Map<UUID, TipoEvento> tipos = new HashMap<>();
        for (TipoEvento te : tipoEventoRepo.findAllById(tipoEventoIds)) {
            tipos.put(te.getId(), te);
        }

        Map<UUID, Atleta> atletas = new HashMap<>();
        for (Atleta a : atletaRepo.findAllById(atletaIds)) {
            atletas.put(a.getId(), a);
        }

        // 2) Pré-valida inscrição (por equipe) para evitar N queries (partida tem no máx 2 equipes)
        Map<UUID, Set<UUID>> atletasPorEquipe = new HashMap<>();
        for (AddEventoInput r : reqs) {
            if (r == null) continue;
            if (r.equipeId() == null) continue;
            if (r.atletaId() != null) {
                atletasPorEquipe.computeIfAbsent(r.equipeId(), k -> new HashSet<>()).add(r.atletaId());
            }
            if (r.atletaSaiId() != null) {
                atletasPorEquipe.computeIfAbsent(r.equipeId(), k -> new HashSet<>()).add(r.atletaSaiId());
            }
        }

        Map<UUID, Set<UUID>> inscritosPorEquipe = new HashMap<>();
        for (var entry : atletasPorEquipe.entrySet()) {
            UUID eqId = entry.getKey();
            List<UUID> ids = new ArrayList<>(entry.getValue());
            Set<UUID> inscritos = new HashSet<>(inscritoRepo.findAtletaIdsInscritos(eqId, ids));
            inscritosPorEquipe.put(eqId, inscritos);
        }

        // ── Idempotência: coleta os localEventoIds da requisição ──────────────────
        Set<String> localIdsRequisicao = new HashSet<>();
        for (AddEventoInput r : reqs) {
            if (r != null && r.localEventoId() != null && !r.localEventoId().isBlank()) {
                localIdsRequisicao.add(r.localEventoId());
            }
        }

        // Consulta em lote quais já existem no banco
        Set<String> localIdsJaExistentes = localIdsRequisicao.isEmpty()
            ? Set.of()
            : repo.findExistingLocalEventoIds(localIdsRequisicao);
        // ─────────────────────────────────────────────────────────────────────────

        // 3) Monta entidades e valida tudo
        List<EventoPartida> toSave = new ArrayList<>(reqs.size());
        int golsA = 0;
        int golsB = 0;

        for (AddEventoInput r : reqs) {
            if (r == null) {
                throw new IllegalStateException("Evento inválido (null) na lista.");
            }
            if (r.equipeId() == null) {
                throw new IllegalStateException("equipeId é obrigatório.");
            }
            if (r.tipoEventoId() == null) {
                throw new IllegalStateException("tipoEventoId é obrigatório.");
            }
            if (r.tempoCronometro() == null || r.tempoCronometro().isBlank()) {
                throw new IllegalStateException("tempoCronometro é obrigatório.");
            }

            Equipe equipe = equipes.get(r.equipeId());
            if (equipe == null) {
                throw new IllegalStateException("Equipe não encontrada: " + r.equipeId());
            }

            // Equipe precisa ser A ou B
            if (!Objects.equals(r.equipeId(), equipeAId) && !Objects.equals(r.equipeId(), equipeBId)) {
                throw new IllegalStateException("Equipe do evento deve ser uma das equipes da partida.");
            }

            TipoEvento tipoEvento = tipos.get(r.tipoEventoId());
            if (tipoEvento == null) {
                throw new IllegalStateException("Tipo de evento não encontrado: " + r.tipoEventoId());
            }
            if (tipoEvento.getEsporte() == null || tipoEvento.getEsporte().getId() == null) {
                throw new IllegalStateException("Tipo de evento sem esporte vinculado.");
            }
            if (!Objects.equals(esporteIdDaPartida, tipoEvento.getEsporte().getId())) {
                throw new IllegalStateException("Tipo de evento não pertence ao esporte da modalidade da partida.");
            }

            boolean isSub = r.isSubstitution();
            if (isSub) {
                if (r.atletaId() == null || r.atletaSaiId() == null) {
                    throw new IllegalStateException("Substituição requer atletaId (entra) e atletaSaiId (sai).");
                }
                if (Objects.equals(r.atletaId(), r.atletaSaiId())) {
                    throw new IllegalStateException("Em substituição, atletaId e atletaSaiId devem ser diferentes.");
                }
            }

            Atleta atleta = null;
            if (r.atletaId() != null) {
                atleta = atletas.get(r.atletaId());
                if (atleta == null) {
                    throw new IllegalStateException("Atleta não encontrado: " + r.atletaId());
                }

                Set<UUID> inscritos = inscritosPorEquipe.getOrDefault(r.equipeId(), Set.of());
                if (!inscritos.contains(r.atletaId())) {
                    throw new IllegalStateException("Atleta não está inscrito nesta equipe.");
                }
            }

            Atleta atletaSai = null;
            if (r.atletaSaiId() != null) {
                atletaSai = atletas.get(r.atletaSaiId());
                if (atletaSai == null) {
                    throw new IllegalStateException("Atleta (sai) não encontrado: " + r.atletaSaiId());
                }
                Set<UUID> inscritos = inscritosPorEquipe.getOrDefault(r.equipeId(), Set.of());
                if (!inscritos.contains(r.atletaSaiId())) {
                    throw new IllegalStateException("Atleta (sai) não está inscrito nesta equipe.");
                }
            }

            // Pula silenciosamente eventos já processados (idempotência)
            if (r.localEventoId() != null 
                    && !r.localEventoId().isBlank()
                    && localIdsJaExistentes.contains(r.localEventoId())) {
                continue; // já foi salvo, ignora sem lançar erro
            }

            EventoPartida ev = new EventoPartida();
            ev.setLocalEventoId(r.localEventoId());
            ev.setPartida(partida);
            ev.setEquipe(equipe);
            ev.setAtleta(atleta);
            ev.setAtletaSai(atletaSai);
            ev.setIsSubstitution(isSub);
            ev.setTipoEvento(tipoEvento);
            ev.setTempoCronometro(r.tempoCronometro());
            ev.setDescricaoDetalhada(r.descricaoDetalhada());
            toSave.add(ev);

            // Atualiza placar se for Gol (vamos somar e persistir 1 vez)
            if (tipoEvento.getNome() != null && tipoEvento.getNome().trim().equalsIgnoreCase("gol")) {
                if (Objects.equals(r.equipeId(), equipeAId)) {
                    golsA++;
                } else {
                    golsB++;
                }
            }

            if (isSub) {
                System.out.println("[DEBUG addBatch] Substitution detected! equipeId=" + r.equipeId()
                        + " atletaEntra=" + r.atletaId() + " atletaSai=" + r.atletaSaiId()
                        + " isSubstitution=" + r.isSubstitution());
                handleSubstitutionAtivoStatus(r.equipeId(), r.atletaId(), r.atletaSaiId());
            }
        }

        List<EventoPartida> saved = repo.saveAll(toSave);

        if (golsA > 0 || golsB > 0) {
            int a = partida.getPlacarA() == null ? 0 : partida.getPlacarA();
            int b = partida.getPlacarB() == null ? 0 : partida.getPlacarB();
            partida.setPlacarA(a + golsA);
            partida.setPlacarB(b + golsB);
            partidaRepo.save(partida);
        }

        // Send push notifications
        for (EventoPartida ev : saved) {
            String topic = "partida_" + partidaId.toString();
            String title = (partida.getEquipeA() != null ? partida.getEquipeA().getNomeEquipe() : "Equipe A") + " x " + 
                           (partida.getEquipeB() != null ? partida.getEquipeB().getNomeEquipe() : "Equipe B");
            String body = buildNotificationBody(ev);
            firebaseMessagingService.sendNotificationToTopic(topic, title, body);
        }

        return saved;
    }

    public EventoPartida add(UUID partidaId,
                             UUID userId,
                             boolean isArbitroOnly,
                             UUID equipeId,
                             UUID atletaId,
                             UUID atletaSaiId,
                             boolean isSubstitution,
                             UUID tipoEventoId,
                             String tempoCronometro,
                             String descricaoDetalhada) {

        Partida partida = partidaRepo.findById(partidaId)
                .orElseThrow(() -> new IllegalStateException("Partida não encontrada."));

        if (!PartidaService.isStatusEmAndamento(partida.getStatus())) {
            throw new IllegalStateException("Só é possível registrar eventos quando a partida estiver em andamento.");
        }

        if (isArbitroOnly && !partidaArbitroRepo.existsByPartida_IdAndArbitro_Id(partidaId, userId)) {
            throw new IllegalStateException("Árbitro não está atribuído a esta partida.");
        }

        Equipe equipe = equipeRepo.findById(equipeId)
                .orElseThrow(() -> new IllegalStateException("Equipe não encontrada."));

        // equipe precisa ser A ou B
        if (!Objects.equals(equipe.getId(), partida.getEquipeA().getId()) && !Objects.equals(equipe.getId(), partida.getEquipeB().getId())) {
            throw new IllegalStateException("Equipe do evento deve ser uma das equipes da partida.");
        }

        TipoEvento tipoEvento = tipoEventoRepo.findById(tipoEventoId)
                .orElseThrow(() -> new IllegalStateException("Tipo de evento não encontrado."));

        // Tipo de evento deve ser do mesmo esporte da modalidade
        Modalidade modalidade = partida.getModalidade();
        if (modalidade.getEsporte() == null || tipoEvento.getEsporte() == null) {
            throw new IllegalStateException("Modalidade/Tipo de evento sem esporte vinculado.");
        }
        if (!Objects.equals(modalidade.getEsporte().getId(), tipoEvento.getEsporte().getId())) {
            throw new IllegalStateException("Tipo de evento não pertence ao esporte da modalidade da partida.");
        }

        if (isSubstitution) {
            if (atletaId == null || atletaSaiId == null) {
                throw new IllegalStateException("Substituição requer atletaId (entra) e atletaSaiId (sai).");
            }
            if (Objects.equals(atletaId, atletaSaiId)) {
                throw new IllegalStateException("Em substituição, atletaId e atletaSaiId devem ser diferentes.");
            }
        }

        Atleta atleta = null;
        if (atletaId != null) {
            atleta = atletaRepo.findById(atletaId)
                    .orElseThrow(() -> new IllegalStateException("Atleta não encontrado."));

            // valida inscrição do atleta na equipe
            boolean inscrito = inscritoRepo.existsByEquipe_IdAndAtleta_Id(equipeId, atletaId);
            if (!inscrito) {
                throw new IllegalStateException("Atleta não está inscrito nesta equipe.");
            }
        }

        Atleta atletaSai = null;
        if (atletaSaiId != null) {
            atletaSai = atletaRepo.findById(atletaSaiId)
                    .orElseThrow(() -> new IllegalStateException("Atleta (sai) não encontrado."));
            boolean inscritoSai = inscritoRepo.existsByEquipe_IdAndAtleta_Id(equipeId, atletaSaiId);
            if (!inscritoSai) {
                throw new IllegalStateException("Atleta (sai) não está inscrito nesta equipe.");
            }
        }

        EventoPartida ev = new EventoPartida();
        ev.setPartida(partida);
        ev.setEquipe(equipe);
        ev.setAtleta(atleta);
        ev.setAtletaSai(atletaSai);
        ev.setIsSubstitution(isSubstitution);
        ev.setTipoEvento(tipoEvento);
        ev.setTempoCronometro(tempoCronometro);
        ev.setDescricaoDetalhada(descricaoDetalhada);

        EventoPartida saved = repo.save(ev);

        // Atualiza placar se for Gol
        if (tipoEvento.getNome() != null && tipoEvento.getNome().trim().equalsIgnoreCase("gol")) {
            Integer a = partida.getPlacarA() == null ? 0 : partida.getPlacarA();
            Integer b = partida.getPlacarB() == null ? 0 : partida.getPlacarB();

            if (Objects.equals(equipeId, partida.getEquipeA().getId())) {
                partida.setPlacarA(a + 1);
            } else {
                partida.setPlacarB(b + 1);
            }
            partidaRepo.save(partida);
        }

        if (isSubstitution) {
            handleSubstitutionAtivoStatus(equipeId, atletaId, atletaSaiId);
        }

        // Send push notification
        String topic = "partida_" + partidaId.toString();
        String title = (partida.getEquipeA() != null ? partida.getEquipeA().getNomeEquipe() : "Equipe A") + " x " + 
                       (partida.getEquipeB() != null ? partida.getEquipeB().getNomeEquipe() : "Equipe B");
        String body = buildNotificationBody(saved);
        firebaseMessagingService.sendNotificationToTopic(topic, title, body);

        return saved;
    }

    private void handleSubstitutionAtivoStatus(UUID equipeId, UUID entraId, UUID saiId) {
        System.out.println("[DEBUG handleSubstitutionAtivoStatus] equipeId=" + equipeId
                + " entraId=" + entraId + " saiId=" + saiId);
        if (entraId != null) {
            var entraOpt = inscritoRepo.findByEquipe_IdAndAtleta_Id(equipeId, entraId);
            System.out.println("[DEBUG handleSubstitutionAtivoStatus] entra found=" + entraOpt.isPresent());
            EquipeAtletaInscrito entra = entraOpt
                    .orElseThrow(() -> new IllegalStateException("Atleta (entra) não está inscrito nesta equipe."));
            System.out.println("[DEBUG handleSubstitutionAtivoStatus] entra BEFORE ativo=" + entra.getAtivo()
                    + " atletaId=" + entraId + " numero=" + entra.getNumeroCamisa());
            entra.setAtivo(true);
            inscritoRepo.save(entra);
            System.out.println("[DEBUG handleSubstitutionAtivoStatus] entra AFTER ativo=" + entra.getAtivo());
        }
        if (saiId != null) {
            var saiOpt = inscritoRepo.findByEquipe_IdAndAtleta_Id(equipeId, saiId);
            System.out.println("[DEBUG handleSubstitutionAtivoStatus] sai found=" + saiOpt.isPresent());
            EquipeAtletaInscrito sai = saiOpt
                    .orElseThrow(() -> new IllegalStateException("Atleta (sai) não está inscrito nesta equipe."));
            System.out.println("[DEBUG: handleSubstitutionAtivoStatus] sai BEFORE ativo=" + sai.getAtivo()
                    + " atletaId=" + saiId + " numero=" + sai.getNumeroCamisa());
            sai.setAtivo(false);
            inscritoRepo.save(sai);
            System.out.println("[DEBUG handleSubstitutionAtivoStatus] sai AFTER ativo=" + sai.getAtivo());
        }
    }
}