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
import com.nkw.backapisumula.partidas.repo.EventoPartidaRepository;
import com.nkw.backapisumula.storage.SupabaseStorageService;
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
    public static final String STATUS_PRIMEIRO_TEMPO = "1° tempo";
    public static final String STATUS_INTERVALO = "intervalo";
    public static final String STATUS_SEGUNDO_TEMPO = "2° tempo";
    public static final String STATUS_PRORROGACAO = "prorrogação";
    public static final String STATUS_ACRESCIMO = "acréscimo";
    public static final String STATUS_PAUSADA = "pausada";
    public static final String STATUS_PENALTIS = "pênaltis";
    public static final String STATUS_FINALIZADA = "finalizada";
    public static final String STATUS_FECHADA = "fechada";

    private static final Set<String> VALID_STATUS = Set.of(
            STATUS_AGENDADA,
            STATUS_PRIMEIRO_TEMPO,
            STATUS_INTERVALO,
            STATUS_SEGUNDO_TEMPO,
            STATUS_PRORROGACAO,
            STATUS_ACRESCIMO,
            STATUS_PAUSADA,
            STATUS_PENALTIS,
            STATUS_FINALIZADA,
            STATUS_FECHADA
    );

    private final PartidaRepository repo;
    private final ModalidadeRepository modalidadeRepo;
    private final EquipeRepository equipeRepo;
    private final PartidaArbitroRepository partidaArbitroRepo;
    private final EventoPartidaRepository eventoRepo;
    private final ObjectMapper objectMapper;
    private final SupabaseStorageService supabaseStorageService;
    private final SumulaOficialPdfService sumulaOficialPdfService;

    public PartidaService(PartidaRepository repo,
                          ModalidadeRepository modalidadeRepo,
                          EquipeRepository equipeRepo,
                          PartidaArbitroRepository partidaArbitroRepo,
                          EventoPartidaRepository eventoRepo,
                          SupabaseStorageService supabaseStorageService,
                          SumulaOficialPdfService sumulaOficialPdfService) {
        this.repo = repo;
        this.modalidadeRepo = modalidadeRepo;
        this.equipeRepo = equipeRepo;
        this.partidaArbitroRepo = partidaArbitroRepo;
        this.eventoRepo = eventoRepo;
        this.supabaseStorageService = supabaseStorageService;
        this.sumulaOficialPdfService = sumulaOficialPdfService;
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
                    // ordem: em andamento primeiro, depois agendada, depois finalizada
                    if (isStatusEmAndamento(p.getStatus())) return 0;
                    if (STATUS_AGENDADA.equalsIgnoreCase(p.getStatus())) return 1;
                    return 2;
                }).thenComparing(p -> Optional.ofNullable(p.getIniciadaEm()).orElse(OffsetDateTime.MIN), Comparator.reverseOrder()))
                .toList();
    }

    public Partida getOrThrow(UUID id) {
        return repo.findById(id).orElseThrow(() -> new IllegalStateException("Partida não encontrada."));
    }

    public Partida create(UUID modalidadeId, UUID equipeAId, UUID equipeBId, OffsetDateTime agendadoPara, String local, String categoria, String fase) {
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
        p.setCategoria(categoria);
        p.setFase(fase);
        p.setAgendadoPara(agendadoPara);
        p.setStatus(STATUS_AGENDADA);
        p.setPlacarA(0);
        p.setPlacarB(0);

        return repo.save(p);
    }

    public Partida update(UUID partidaId, UUID userId, boolean isArbitroOnly, UUID modalidadeId, UUID equipeAId, UUID equipeBId, OffsetDateTime agendadoPara, String local, JsonNode snapshotSumula, String sumulaPdfUrl, String categoria, String fase) {
        Partida p = getOrThrow(partidaId);

        String st = p.getStatus() == null ? "" : p.getStatus().trim().toLowerCase();
        if (isStatusEmAndamento(st)) {
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
        if (STATUS_FINALIZADA.equals(st)) {
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
            throw new IllegalStateException("Só é possível editar dados básicos quando a partida estiver agendada.");
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

        if (agendadoPara != null) p.setAgendadoPara(agendadoPara);
        if (local != null) p.setLocal(local);
        if (categoria != null) p.setCategoria(categoria);
        if (fase != null) p.setFase(fase);

        return repo.save(p);
    }

    public Partida start(UUID partidaId, UUID userId, boolean isArbitroOnly) {
        Partida p = getOrThrow(partidaId);

        if (isStatusFinalizada(p.getStatus()) || isStatusFechada(p.getStatus())) {
            throw new IllegalStateException("Partida já encerrada.");
        }
        if (isStatusEmAndamento(p.getStatus())) {
            throw new IllegalStateException("Partida já está em andamento.");
        }

        if (isArbitroOnly && !partidaArbitroRepo.existsByPartida_IdAndArbitro_Id(partidaId, userId)) {
            throw new IllegalStateException("Árbitro não está atribuído a esta partida.");
        }

        p.setStatus(STATUS_PRIMEIRO_TEMPO);
        p.setIniciadaEm(OffsetDateTime.now());
        return repo.save(p);
    }

    public Partida end(UUID partidaId, UUID userId, boolean isArbitroOnly) {
        Partida p = getOrThrow(partidaId);

        if (isStatusFechada(p.getStatus())) {
            throw new IllegalStateException("Partida já está fechada.");
        }

        if (!isStatusFinalizada(p.getStatus())) {
            throw new IllegalStateException("Só é possível fechar a súmula de uma partida finalizada.");
        }

        if (isArbitroOnly && !partidaArbitroRepo.existsByPartida_IdAndArbitro_Id(partidaId, userId)) {
            throw new IllegalStateException("Árbitro não está atribuído a esta partida.");
        }

        p.setStatus(STATUS_FECHADA);

        if (p.getEncerradaEm() == null) {
            p.setEncerradaEm(OffsetDateTime.now());
        }

        // Ao fechar, garantimos um snapshot da súmula (fonte de verdade).
        JsonNode snapshot = buildSnapshotSumula(p);
        p.setSnapshotSumula(snapshot);

        // Gera e faz o upload da súmula em PDF
        try {
            byte[] pdfBytes = sumulaOficialPdfService.gerarPdf(partidaId);
            String fileName = "sumula_" + partidaId + "_" + System.currentTimeMillis() + ".pdf";
            supabaseStorageService.uploadPdf(fileName, pdfBytes);
            String publicUrl = supabaseStorageService.getPublicUrl(fileName);
            p.setSumulaPdfUrl(publicUrl);
        } catch (Exception e) {
            // Em caso de erro no upload/geração, logar. A url continuará vazia, ou a excecão vai interromper?
            // A exceção pode propagar para o controller para que o admin saiba do erro
            throw new RuntimeException("Erro ao gerar/salvar a súmula oficial em PDF", e);
        }

        // Atualiza hash com o snapshot e a url do pdf (se existir)
        p.setHashIntegridade(calcHashIntegridade(p.getSnapshotSumula(), p.getSumulaPdfUrl()));

        return repo.save(p);
    }

    public Partida updateStatus(UUID partidaId, UUID userId, boolean isArbitroOnly, String status, String statusAntesPausa) {
        Partida p = getOrThrow(partidaId);

        // Se for árbitro (sem ser admin/delegado), só pode alterar se estiver atribuído à partida
        if (isArbitroOnly && !partidaArbitroRepo.existsByPartida_IdAndArbitro_Id(partidaId, userId)) {
            throw new IllegalStateException("Árbitro não está atribuído a esta partida.");
        }

        // Evita reabrir partidas finalizadas/fechadas via este endpoint
        if (isStatusFinalizada(p.getStatus()) || isStatusFechada(p.getStatus())) {
            throw new IllegalStateException("Partida já encerrada.");
        }

        String normalized = normalizeStatusForDb(status);
        validateStatus(normalized);

        // "fechada" é reservado para o endpoint /end
        if (STATUS_FECHADA.equalsIgnoreCase(normalized)) {
            throw new IllegalStateException("Use o endpoint /end para fechar a súmula.");
        }

        p.setStatus(normalized);

        if (statusAntesPausa != null) {
            if (statusAntesPausa.isBlank()) {
                p.setStatusAntesPausa(null);
            } else {
                String normalizedAntesPausa = normalizeStatusForDb(statusAntesPausa);
                validateStatus(normalizedAntesPausa);
                p.setStatusAntesPausa(normalizedAntesPausa);
            }
        }

        // Se saiu de agendada, marca iniciadaEm caso ainda não exista
        if (!STATUS_AGENDADA.equalsIgnoreCase(normalized) && p.getIniciadaEm() == null) {
            p.setIniciadaEm(OffsetDateTime.now());
        }

        // Se marcou como finalizada por aqui, preenche encerradaEm (não gera snapshot automaticamente)
        if (STATUS_FINALIZADA.equalsIgnoreCase(normalized) && p.getEncerradaEm() == null) {
            p.setEncerradaEm(OffsetDateTime.now());
        }

        return repo.save(p);
    }

    private String normalizeStatusForDb(String raw) {
        if (raw == null) return null;

        String s = raw.trim().toLowerCase(Locale.ROOT);

        // Normaliza símbolo ordinal para o mesmo usado no banco (°)
        s = s.replace('º', '°');

        // Aceita variações sem acento
        if (s.equals("prorrogacao")) return STATUS_PRORROGACAO;
        if (s.equals("penaltis") || s.equals("pênaltis") || s.equals("penalti") || s.equals("pênalti")) {
            return STATUS_PENALTIS;
        }

        // Aceita variações comuns
        if (s.equals("pausa") || s.equals("pausado")) return STATUS_PAUSADA;
        if (s.equals("acrescimo") || s.equals("acréscimo")) return STATUS_ACRESCIMO;
        if (s.equals("1o tempo") || s.equals("1°tempo") || s.equals("1 tempo") || s.equals("primeiro tempo")) return STATUS_PRIMEIRO_TEMPO;
        if (s.equals("2o tempo") || s.equals("2°tempo") || s.equals("2 tempo") || s.equals("segundo tempo")) return STATUS_SEGUNDO_TEMPO;

        return s;
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
        root.put("categoria", p.getCategoria());
        root.put("fase", p.getFase());
        root.put("agendadoPara", p.getAgendadoPara() != null ? p.getAgendadoPara().toString() : null);
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
            ev.put("isSubstitution", e.getIsSubstitution() != null ? e.getIsSubstitution() : false);
            if (e.getAtleta() != null) {
                ObjectNode at = ev.putObject("atleta");
                at.put("id", e.getAtleta().getId().toString());
                at.put("nome", e.getAtleta().getNome());
            }
            if (e.getAtletaSai() != null) {
                ObjectNode atSai = ev.putObject("atletaSai");
                atSai.put("id", e.getAtletaSai().getId().toString());
                atSai.put("nome", e.getAtletaSai().getNome());
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


    public static boolean isStatusFinalizada(String status) {
        if (status == null) return false;
        return STATUS_FINALIZADA.equalsIgnoreCase(status.trim());
    }

    public static boolean isStatusFechada(String status) {
        if (status == null) return false;
        return STATUS_FECHADA.equalsIgnoreCase(status.trim());
    }

    /**
     * Consideramos "em andamento" qualquer status válido que não seja agendada/finalizada/fechada.
     * Isso cobre: 1° tempo, intervalo, 2° tempo, prorrogação, acréscimo, pausada e pênaltis.
     */
    public static boolean isStatusEmAndamento(String status) {
        if (status == null) return false;
        String s = status.trim().toLowerCase(Locale.ROOT);
        return !STATUS_AGENDADA.equals(s) && !STATUS_FINALIZADA.equals(s) && !STATUS_FECHADA.equals(s);
    }

    public void validateStatus(String status) {
        if (status == null) return;
        String s = status.trim().toLowerCase(Locale.ROOT);
        if (!VALID_STATUS.contains(s)) {
            throw new IllegalStateException("Status inválido. Use: agendada, 1° tempo, intervalo, 2° tempo, prorrogação, acréscimo, pausada, pênaltis, finalizada, fechada.");
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

    public void delete(UUID id) {
        Partida p = getOrThrow(id);
        repo.delete(p);
    }
}
