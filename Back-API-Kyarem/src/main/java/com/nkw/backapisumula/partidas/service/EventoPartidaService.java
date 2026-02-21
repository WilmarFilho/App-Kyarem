package com.nkw.backapisumula.partidas.service;

import com.nkw.backapisumula.cadastros.Atleta;
import com.nkw.backapisumula.cadastros.TipoEvento;
import com.nkw.backapisumula.cadastros.repo.AtletaRepository;
import com.nkw.backapisumula.cadastros.repo.TipoEventoRepository;
import com.nkw.backapisumula.competicao.Equipe;
import com.nkw.backapisumula.competicao.Modalidade;
import com.nkw.backapisumula.competicao.repo.EquipeAtletaInscritoRepository;
import com.nkw.backapisumula.competicao.repo.EquipeRepository;
import com.nkw.backapisumula.partidas.EventoPartida;
import com.nkw.backapisumula.partidas.Partida;
import com.nkw.backapisumula.partidas.repo.EventoPartidaRepository;
import com.nkw.backapisumula.partidas.repo.PartidaArbitroRepository;
import com.nkw.backapisumula.partidas.repo.PartidaRepository;
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

@Service
public class EventoPartidaService {

    public record AddEventoInput(
            UUID equipeId,
            UUID atletaId,
            UUID tipoEventoId,
            String tempoCronometro,
            String descricaoDetalhada
    ) {}

    private final EventoPartidaRepository repo;
    private final PartidaRepository partidaRepo;
    private final PartidaArbitroRepository partidaArbitroRepo;
    private final EquipeRepository equipeRepo;
    private final AtletaRepository atletaRepo;
    private final TipoEventoRepository tipoEventoRepo;
    private final EquipeAtletaInscritoRepository inscritoRepo;

    public EventoPartidaService(EventoPartidaRepository repo,
                               PartidaRepository partidaRepo,
                               PartidaArbitroRepository partidaArbitroRepo,
                               EquipeRepository equipeRepo,
                               AtletaRepository atletaRepo,
                               TipoEventoRepository tipoEventoRepo,
                               EquipeAtletaInscritoRepository inscritoRepo) {
        this.repo = repo;
        this.partidaRepo = partidaRepo;
        this.partidaArbitroRepo = partidaArbitroRepo;
        this.equipeRepo = equipeRepo;
        this.atletaRepo = atletaRepo;
        this.tipoEventoRepo = tipoEventoRepo;
        this.inscritoRepo = inscritoRepo;
    }

    public List<EventoPartida> list(UUID partidaId) {
        return repo.findByPartida_IdOrderByCriadoEmAsc(partidaId);
    }

    /**
     * Cria eventos em lote para reduzir quantidade de requisições HTTP.
     *
     * Regras/validações seguem a mesma lógica do {@link #add(UUID, UUID, boolean, UUID, UUID, UUID, String, String)}.
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

        if (!PartidaService.STATUS_EM_ANDAMENTO.equalsIgnoreCase(partida.getStatus())) {
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
            if (r == null || r.atletaId() == null) continue;
            if (r.equipeId() == null) continue;
            atletasPorEquipe.computeIfAbsent(r.equipeId(), k -> new HashSet<>()).add(r.atletaId());
        }

        Map<UUID, Set<UUID>> inscritosPorEquipe = new HashMap<>();
        for (var entry : atletasPorEquipe.entrySet()) {
            UUID eqId = entry.getKey();
            List<UUID> ids = new ArrayList<>(entry.getValue());
            Set<UUID> inscritos = new HashSet<>(inscritoRepo.findAtletaIdsInscritos(eqId, ids));
            inscritosPorEquipe.put(eqId, inscritos);
        }

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

            EventoPartida ev = new EventoPartida();
            ev.setPartida(partida);
            ev.setEquipe(equipe);
            ev.setAtleta(atleta);
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
        }

        List<EventoPartida> saved = repo.saveAll(toSave);

        if (golsA > 0 || golsB > 0) {
            int a = partida.getPlacarA() == null ? 0 : partida.getPlacarA();
            int b = partida.getPlacarB() == null ? 0 : partida.getPlacarB();
            partida.setPlacarA(a + golsA);
            partida.setPlacarB(b + golsB);
            partidaRepo.save(partida);
        }

        return saved;
    }

    public EventoPartida add(UUID partidaId,
                             UUID userId,
                             boolean isArbitroOnly,
                             UUID equipeId,
                             UUID atletaId,
                             UUID tipoEventoId,
                             String tempoCronometro,
                             String descricaoDetalhada) {

        Partida partida = partidaRepo.findById(partidaId)
                .orElseThrow(() -> new IllegalStateException("Partida não encontrada."));

        if (!PartidaService.STATUS_EM_ANDAMENTO.equalsIgnoreCase(partida.getStatus())) {
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

        EventoPartida ev = new EventoPartida();
        ev.setPartida(partida);
        ev.setEquipe(equipe);
        ev.setAtleta(atleta);
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

        return saved;
    }
}
