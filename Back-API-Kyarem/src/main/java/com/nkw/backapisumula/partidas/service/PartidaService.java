package com.nkw.backapisumula.partidas.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.nkw.backapisumula.competicao.Equipe;
import com.nkw.backapisumula.competicao.Modalidade;
import com.nkw.backapisumula.competicao.repo.EquipeRepository;
import com.nkw.backapisumula.competicao.repo.ModalidadeRepository;
import com.nkw.backapisumula.partidas.EventoPartida;
import com.nkw.backapisumula.partidas.Partida;
import com.nkw.backapisumula.partidas.repo.PartidaArbitroRepository;
import com.nkw.backapisumula.partidas.repo.PartidaRepository;
import com.nkw.backapisumula.partidas.repo.EventoPartidaRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.OffsetDateTime;
import java.util.*;

@Service
public class PartidaService {

    public static final String STATUS_AGENDADA = "agendada";
    public static final String STATUS_EM_ANDAMENTO = "em_andamento";
    public static final String STATUS_ENCERRADA = "encerrada";

    private static final Set<String> VALID_STATUS = Set.of(STATUS_AGENDADA, STATUS_EM_ANDAMENTO, STATUS_ENCERRADA);

    private final PartidaRepository repo;
    private final ModalidadeRepository modalidadeRepo;
    private final EquipeRepository equipeRepo;
    private final PartidaArbitroRepository partidaArbitroRepo;
    private final EventoPartidaRepository eventoRepo;
    private final ObjectMapper objectMapper;

    public PartidaService(PartidaRepository repo,
                          ModalidadeRepository modalidadeRepo,
                          EquipeRepository equipeRepo,
                          PartidaArbitroRepository partidaArbitroRepo,
                          EventoPartidaRepository eventoRepo) {
        this.repo = repo;
        this.modalidadeRepo = modalidadeRepo;
        this.equipeRepo = equipeRepo;
        this.partidaArbitroRepo = partidaArbitroRepo;
        this.eventoRepo = eventoRepo;
        this.objectMapper = new ObjectMapper().enable(SerializationFeature.ORDER_MAP_ENTRIES_BY_KEYS);
    }

    public List<Partida> list(UUID modalidadeId, String status) {
        if (modalidadeId != null && status != null && !status.isBlank()) {
            return repo.findByModalidade_IdAndStatus(modalidadeId, status);
        }
        if (modalidadeId != null) {
            return repo.findByModalidade_Id(modalidadeId);
        }
        if (status != null && !status.isBlank()) {
            return repo.findByStatus(status);
        }
        return repo.findAll();
    }


    public List<Partida> listByArbitro(UUID arbitroId) {
        return partidaArbitroRepo.findByArbitro_Id(arbitroId).stream()
                .map(pa -> pa.getPartida())
                .filter(Objects::nonNull)
                .sorted(Comparator.comparing((Partida p) -> {
                    // ordem: em_andamento primeiro, depois agendada, depois encerrada
                    if (STATUS_EM_ANDAMENTO.equalsIgnoreCase(p.getStatus())) return 0;
                    if (STATUS_AGENDADA.equalsIgnoreCase(p.getStatus())) return 1;
                    return 2;
                }).thenComparing(p -> Optional.ofNullable(p.getIniciadaEm()).orElse(OffsetDateTime.MIN), Comparator.reverseOrder()))
                .toList();
    }

    public Partida getOrThrow(UUID id) {
        return repo.findById(id).orElseThrow(() -> new IllegalStateException("Partida não encontrada."));
    }

    public Partida create(UUID modalidadeId, UUID equipeAId, UUID equipeBId, String local) {
        if (equipeAId.equals(equipeBId)) {
            throw new IllegalStateException("Equipe A e Equipe B não podem ser a mesma.");
        }

        Modalidade modalidade = modalidadeRepo.findById(modalidadeId)
                .orElseThrow(() -> new IllegalStateException("Modalidade não encontrada."));

        Equipe equipeA = equipeRepo.findById(equipeAId)
                .orElseThrow(() -> new IllegalStateException("Equipe A não encontrada."));
        Equipe equipeB = equipeRepo.findById(equipeBId)
                .orElseThrow(() -> new IllegalStateException("Equipe B não encontrada."));

        // valida campeonato/modalidade coerentes
        validateEquipeCompatibilidade(modalidade, equipeA, equipeB);

        Partida p = new Partida();
        p.setModalidade(modalidade);
        p.setEquipeA(equipeA);
        p.setEquipeB(equipeB);
        p.setLocal(local);
        p.setStatus(STATUS_AGENDADA);
        p.setPlacarA(0);
        p.setPlacarB(0);

        return repo.save(p);
    }

    public Partida update(UUID partidaId, UUID userId, boolean isArbitroOnly, UUID modalidadeId, UUID equipeAId, UUID equipeBId, String local, JsonNode snapshotSumula, String sumulaPdfUrl) {
        Partida p = getOrThrow(partidaId);

        String st = p.getStatus() == null ? "" : p.getStatus().trim().toLowerCase();
        if (STATUS_EM_ANDAMENTO.equals(st)) {
            throw new IllegalStateException("Não é possível editar uma partida em andamento.");
        }

        // Se for árbitro (sem ser admin/delegado), só pode editar se estiver atribuído à partida
        if (isArbitroOnly) {
            boolean atribuido = partidaArbitroRepo.existsByPartida_IdAndArbitro_Id(partidaId, userId);
            if (!atribuido) {
                throw new IllegalStateException("Você não está atribuído como árbitro desta partida.");
            }
        }

        // Pós-jogo: permitir salvar súmula quando encerrada
        if (STATUS_ENCERRADA.equals(st)) {
            if (snapshotSumula != null) {
                p.setSnapshotSumula(snapshotSumula);
            }
            if (sumulaPdfUrl != null && !sumulaPdfUrl.isBlank()) {
                p.setSumulaPdfUrl(sumulaPdfUrl.trim());
            }
            // Atualiza hash de integridade sempre que salvar snapshot/url
            if (snapshotSumula != null || (sumulaPdfUrl != null && !sumulaPdfUrl.isBlank())) {
                p.setHashIntegridade(calcHashIntegridade(p.getSnapshotSumula(), p.getSumulaPdfUrl()));
            }
            return repo.save(p);
        }

        // Caso esteja agendada, permite editar dados básicos
        if (!STATUS_AGENDADA.equals(st)) {
            throw new IllegalStateException("Status inválido para edição.");
        }


        if (equipeAId != null && equipeBId != null && equipeAId.equals(equipeBId)) {
            throw new IllegalStateException("Equipe A e Equipe B não podem ser a mesma.");
        }

        Modalidade modalidade = p.getModalidade();
        if (modalidadeId != null) {
            modalidade = modalidadeRepo.findById(modalidadeId)
                    .orElseThrow(() -> new IllegalStateException("Modalidade não encontrada."));
            p.setModalidade(modalidade);
        }

        Equipe equipeA = p.getEquipeA();
        if (equipeAId != null) {
            equipeA = equipeRepo.findById(equipeAId)
                    .orElseThrow(() -> new IllegalStateException("Equipe A não encontrada."));
            p.setEquipeA(equipeA);
        }

        Equipe equipeB = p.getEquipeB();
        if (equipeBId != null) {
            equipeB = equipeRepo.findById(equipeBId)
                    .orElseThrow(() -> new IllegalStateException("Equipe B não encontrada."));
            p.setEquipeB(equipeB);
        }

        validateEquipeCompatibilidade(modalidade, equipeA, equipeB);

        if (local != null) p.setLocal(local);

        return repo.save(p);
    }

    public Partida start(UUID partidaId, UUID userId, boolean isArbitroOnly) {
        Partida p = getOrThrow(partidaId);

        if (STATUS_ENCERRADA.equalsIgnoreCase(p.getStatus())) {
            throw new IllegalStateException("Partida já encerrada.");
        }
        if (STATUS_EM_ANDAMENTO.equalsIgnoreCase(p.getStatus())) {
            throw new IllegalStateException("Partida já está em andamento.");
        }

        if (isArbitroOnly && !partidaArbitroRepo.existsByPartida_IdAndArbitro_Id(partidaId, userId)) {
            throw new IllegalStateException("Árbitro não está atribuído a esta partida.");
        }

        p.setStatus(STATUS_EM_ANDAMENTO);
        p.setIniciadaEm(OffsetDateTime.now());
        return repo.save(p);
    }

    public Partida end(UUID partidaId, UUID userId, boolean isArbitroOnly) {
        Partida p = getOrThrow(partidaId);

        if (!STATUS_EM_ANDAMENTO.equalsIgnoreCase(p.getStatus())) {
            throw new IllegalStateException("Só é possível encerrar uma partida em andamento.");
        }

        if (isArbitroOnly && !partidaArbitroRepo.existsByPartida_IdAndArbitro_Id(partidaId, userId)) {
            throw new IllegalStateException("Árbitro não está atribuído a esta partida.");
        }

        p.setStatus(STATUS_ENCERRADA);
        p.setEncerradaEm(OffsetDateTime.now());

        // Ao encerrar, geramos automaticamente um snapshot da súmula.
        // (Isso evita o front precisar mandar snapshotSumula no PUT).
        JsonNode snapshot = buildSnapshotSumula(p);
        p.setSnapshotSumula(snapshot);

        // Espaço reservado para gerar o PDF e fazer upload no bucket.
        // Por enquanto deixamos nulo (ou mantém o que já existir).
        if (p.getSumulaPdfUrl() == null || p.getSumulaPdfUrl().isBlank()) {
            p.setSumulaPdfUrl(generateSumulaPdfUrlPlaceholder(p, snapshot));
        }

        // Atualiza hash com o snapshot e a url do pdf (se existir)
        p.setHashIntegridade(calcHashIntegridade(p.getSnapshotSumula(), p.getSumulaPdfUrl()));

        return repo.save(p);
    }

    /**
     * Monta um JSON estável (ordenado) com os dados necessários para a súmula.
     * Pode evoluir com o tempo (ex.: adicionar estatísticas, assinaturas etc.).
     */
    @Transactional(readOnly = true)
    protected JsonNode buildSnapshotSumula(Partida p) {
        List<EventoPartida> eventos = eventoRepo.findByPartidaIdWithDetails(p.getId());
        List<com.nkw.backapisumula.partidas.PartidaArbitro> arbitros = partidaArbitroRepo.findByPartidaIdWithArbitro(p.getId());

        ObjectNode root = objectMapper.createObjectNode();
        root.put("partidaId", p.getId().toString());
        root.put("status", p.getStatus());
        root.put("iniciadaEm", p.getIniciadaEm() != null ? p.getIniciadaEm().toString() : null);
        root.put("encerradaEm", p.getEncerradaEm() != null ? p.getEncerradaEm().toString() : null);
        root.put("local", p.getLocal());
        root.put("placarA", p.getPlacarA() != null ? p.getPlacarA() : 0);
        root.put("placarB", p.getPlacarB() != null ? p.getPlacarB() : 0);

        if (p.getModalidade() != null) {
            ObjectNode modalidade = root.putObject("modalidade");
            modalidade.put("id", p.getModalidade().getId().toString());
            modalidade.put("nome", p.getModalidade().getNome());
            if (p.getModalidade().getEsporte() != null) {
                ObjectNode esporte = modalidade.putObject("esporte");
                esporte.put("id", p.getModalidade().getEsporte().getId().toString());
                esporte.put("nome", p.getModalidade().getEsporte().getNome());
            }
        }

        if (p.getEquipeA() != null) {
            ObjectNode eqA = root.putObject("equipeA");
            eqA.put("id", p.getEquipeA().getId().toString());
            eqA.put("nomeEquipe", p.getEquipeA().getNomeEquipe());
        }
        if (p.getEquipeB() != null) {
            ObjectNode eqB = root.putObject("equipeB");
            eqB.put("id", p.getEquipeB().getId().toString());
            eqB.put("nomeEquipe", p.getEquipeB().getNomeEquipe());
        }

        ArrayNode arbitrosJson = root.putArray("arbitros");
        arbitros.forEach(pa -> {
            ObjectNode a = arbitrosJson.addObject();
            a.put("id", pa.getId().toString());
            a.put("funcao", pa.getFuncao());
            if (pa.getArbitro() != null) {
                a.put("arbitroId", pa.getArbitro().getId().toString());
                a.put("nome", pa.getArbitro().getNomeExibicao());
            }
        });

        ArrayNode eventosJson = root.putArray("eventos");
        eventos.forEach(e -> {
            ObjectNode ev = eventosJson.addObject();
            ev.put("id", e.getId().toString());
            ev.put("tempo", e.getTempoCronometro());
            ev.put("descricao", e.getDescricaoDetalhada());
            if (e.getTipoEvento() != null) {
                ObjectNode tipo = ev.putObject("tipoEvento");
                tipo.put("id", e.getTipoEvento().getId().toString());
                tipo.put("nome", e.getTipoEvento().getNome());
            }
            if (e.getEquipe() != null) {
                ObjectNode eq = ev.putObject("equipe");
                eq.put("id", e.getEquipe().getId().toString());
                eq.put("nomeEquipe", e.getEquipe().getNomeEquipe());
            }
            if (e.getAtleta() != null) {
                ObjectNode at = ev.putObject("atleta");
                at.put("id", e.getAtleta().getId().toString());
                at.put("nome", e.getAtleta().getNome());
            }
            ev.put("criadoEm", e.getCriadoEm() != null ? e.getCriadoEm().toString() : null);
        });

        return root;
    }

    /**
     * Placeholder para futura geração/upload do PDF da súmula.
     * Retorna null por enquanto.
     */
    protected String generateSumulaPdfUrlPlaceholder(Partida p, JsonNode snapshot) {
        // TODO: gerar PDF baseado no snapshot + upload em bucket (Supabase Storage)
        return null;
    }

    public void validateStatus(String status) {
        if (status == null) return;
        String s = status.trim().toLowerCase(Locale.ROOT);
        if (!VALID_STATUS.contains(s)) {
            throw new IllegalStateException("Status inválido. Use: agendada, em_andamento, encerrada.");
        }
    }

    private void validateEquipeCompatibilidade(Modalidade modalidade, Equipe equipeA, Equipe equipeB) {
        if (equipeA.getModalidade() == null || equipeB.getModalidade() == null) {
            throw new IllegalStateException("Equipes precisam estar vinculadas a uma modalidade.");
        }
        if (!Objects.equals(equipeA.getModalidade().getId(), modalidade.getId())
                || !Objects.equals(equipeB.getModalidade().getId(), modalidade.getId())) {
            throw new IllegalStateException("Equipes devem ser da mesma modalidade da partida.");
        }
        if (equipeA.getCampeonato() == null || equipeB.getCampeonato() == null) {
            throw new IllegalStateException("Equipes precisam estar vinculadas a um campeonato.");
        }
        if (!Objects.equals(equipeA.getCampeonato().getId(), equipeB.getCampeonato().getId())) {
            throw new IllegalStateException("Equipes devem ser do mesmo campeonato.");
        }
    }

    private String calcHashIntegridade(com.fasterxml.jackson.databind.JsonNode snapshot, String pdfUrl) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");

            String base = "";

            if (snapshot != null) {
                base += snapshot.toString();
            }

            if (pdfUrl != null) {
                base += pdfUrl;
            }

            byte[] hash = digest.digest(base.getBytes(StandardCharsets.UTF_8));

            return Base64.getEncoder().encodeToString(hash);

        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("Erro ao calcular hash de integridade", e);
        }
    }

}
