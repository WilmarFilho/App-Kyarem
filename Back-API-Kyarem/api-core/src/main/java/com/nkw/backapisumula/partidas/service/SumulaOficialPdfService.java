package com.nkw.backapisumula.partidas.service;

import com.nkw.backapisumula.competicao.CampeonatoAtleta;
import com.nkw.backapisumula.competicao.EquipeStaff;
import com.nkw.backapisumula.competicao.repo.CampeonatoAtletaRepository;
import com.nkw.backapisumula.competicao.repo.EquipeStaffRepository;
import com.nkw.backapisumula.partidas.EventoPartida;
import com.nkw.backapisumula.partidas.Partida;
import com.nkw.backapisumula.partidas.PartidaArbitro;
import com.nkw.backapisumula.partidas.repo.EventoPartidaRepository;
import com.nkw.backapisumula.partidas.repo.PartidaArbitroRepository;
import com.nkw.backapisumula.partidas.repo.PartidaRepository;
import com.openhtmltopdf.pdfboxout.PdfRendererBuilder;
import org.hibernate.Hibernate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.net.URI;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;
import javax.imageio.ImageIO;

@Service
public class SumulaOficialPdfService {

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("HH:mm");
    private static final int MAX_PLAYERS = 13;
    private static final int MAX_GOALS = 27;

    private final PartidaRepository partidaRepo;
    private final EventoPartidaRepository eventoRepo;
    private final PartidaArbitroRepository partidaArbitroRepo;
    private final CampeonatoAtletaRepository inscritosRepo;
    private final EquipeStaffRepository equipeStaffRepo;

    public SumulaOficialPdfService(
            PartidaRepository partidaRepo,
            EventoPartidaRepository eventoRepo,
            PartidaArbitroRepository partidaArbitroRepo,
            CampeonatoAtletaRepository inscritosRepo,
            EquipeStaffRepository equipeStaffRepo) {
        this.partidaRepo = partidaRepo;
        this.eventoRepo = eventoRepo;
        this.partidaArbitroRepo = partidaArbitroRepo;
        this.inscritosRepo = inscritosRepo;
        this.equipeStaffRepo = equipeStaffRepo;
    }

    // ─── PUBLIC API ─────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public byte[] gerarPdf(UUID partidaId) {
        Partida partida = partidaRepo.findById(partidaId)
                .orElseThrow(() -> new IllegalStateException("Partida não encontrada."));

        // Force-load lazy relations so escudo URLs are available
        if (partida.getEquipeA() != null) {
            Hibernate.initialize(partida.getEquipeA());
            if (partida.getEquipeA().getAtletica() != null)
                Hibernate.initialize(partida.getEquipeA().getAtletica());
            if (partida.getEquipeA().getCampeonato() != null)
                Hibernate.initialize(partida.getEquipeA().getCampeonato());
        }
        if (partida.getEquipeB() != null) {
            Hibernate.initialize(partida.getEquipeB());
            if (partida.getEquipeB().getAtletica() != null)
                Hibernate.initialize(partida.getEquipeB().getAtletica());
            if (partida.getEquipeB().getCampeonato() != null)
                Hibernate.initialize(partida.getEquipeB().getCampeonato());
        }

        List<EventoPartida> eventos = eventoRepo.findByPartidaIdWithDetails(partidaId);
        System.out.println("Eventos: " + eventos);
        List<PartidaArbitro> arbitros = partidaArbitroRepo.findByPartidaIdWithArbitro(partidaId);
        List<CampeonatoAtleta> inscritosA = partida.getEquipeA() == null ? List.of()
                : inscritosRepo.findByCampeonatoTime_Id(partida.getEquipeA().getId());
        List<CampeonatoAtleta> inscritosB = partida.getEquipeB() == null ? List.of()
                : inscritosRepo.findByCampeonatoTime_Id(partida.getEquipeB().getId());
        List<EquipeStaff> staffA = partida.getEquipeA() == null ? List.of()
                : equipeStaffRepo.findByCampeonatoTime_Id(partida.getEquipeA().getId());
        List<EquipeStaff> staffB = partida.getEquipeB() == null ? List.of()
                : equipeStaffRepo.findByCampeonatoTime_Id(partida.getEquipeB().getId());

        SumulaData data = buildData(partida, inscritosA, inscritosB, staffA, staffB, arbitros, eventos);
        return renderHtmlToPdf(buildHtml(data));
    }

    // ─── DATA BUILDING ──────────────────────────────────────────────────────────

    private SumulaData buildData(
            Partida partida,
            List<CampeonatoAtleta> inscritosA,
            List<CampeonatoAtleta> inscritosB,
            List<EquipeStaff> staffA,
            List<EquipeStaff> staffB,
            List<PartidaArbitro> arbitros,
            List<EventoPartida> eventos) {
        int tempoPeriodo = Optional.ofNullable(partida.getModalidade())
                .map(m -> m.getTempoPartidaMinutos()).filter(v -> v > 0).orElse(20);

        Map<UUID, Integer> numeroPorAtleta = new HashMap<>();
        inscritosA.forEach(i -> putIfPresent(numeroPorAtleta, i));
        inscritosB.forEach(i -> putIfPresent(numeroPorAtleta, i));

        Map<UUID, List<EventoPartida>> eventosPorJogador = eventos.stream()
                .filter(e -> e.getAtleta() != null && e.getAtleta().getId() != null)
                .collect(Collectors.groupingBy(e -> e.getAtleta().getId(),
                        LinkedHashMap::new, Collectors.toList()));

        List<RosterRow> rowsA = inscritosA.stream()
                .sorted(Comparator.comparing(i -> Optional.ofNullable(i.getNumeroCamisa()).orElse(999)))
                .limit(MAX_PLAYERS)
                .map(i -> rosterRow(i, eventosPorJogador.get(i.getAtleta().getId())))
                .toList();

        List<RosterRow> rowsB = inscritosB.stream()
                .sorted(Comparator.comparing(i -> Optional.ofNullable(i.getNumeroCamisa()).orElse(999)))
                .limit(MAX_PLAYERS)
                .map(i -> rosterRow(i, eventosPorJogador.get(i.getAtleta().getId())))
                .toList();

        UUID equipeAId = partida.getEquipeA() == null ? null : partida.getEquipeA().getId();
        UUID equipeBId = partida.getEquipeB() == null ? null : partida.getEquipeB().getId();

        List<GoalEntry> goalsA = buildGoals(eventos, equipeAId, numeroPorAtleta, tempoPeriodo);
        List<GoalEntry> goalsB = buildGoals(eventos, equipeBId, numeroPorAtleta, tempoPeriodo);

        String capitaoA = inscritosA.stream()
                .filter(i -> Boolean.TRUE.equals(i.getIsCapitao()))
                .map(i -> Optional.ofNullable(i.getAtleta())
                        .map(a -> a.getUser() != null && a.getUser().getNomeCompleto() != null
                                ? a.getUser().getNomeCompleto()
                                : a.getNomeCompeticao())
                        .orElse(""))
                .findFirst().orElse("");

        String capitaoB = inscritosB.stream()
                .filter(i -> Boolean.TRUE.equals(i.getIsCapitao()))
                .map(i -> Optional.ofNullable(i.getAtleta())
                        .map(a -> a.getUser() != null && a.getUser().getNomeCompleto() != null
                                ? a.getUser().getNomeCompleto()
                                : a.getNomeCompeticao())
                        .orElse(""))
                .findFirst().orElse("");

        int faltasA1 = countFaltas(eventos, equipeAId, 1, tempoPeriodo);
        int faltasA2 = countFaltas(eventos, equipeAId, 2, tempoPeriodo);
        int pausasA1 = countPausas(eventos, equipeAId, 1);
        int pausasA2 = countPausas(eventos, equipeAId, 2);

        int faltasB1 = countFaltas(eventos, equipeBId, 1, tempoPeriodo);
        int faltasB2 = countFaltas(eventos, equipeBId, 2, tempoPeriodo);
        int pausasB1 = countPausas(eventos, equipeBId, 1);
        int pausasB2 = countPausas(eventos, equipeBId, 2);

        List<String> staffLinesA = staffA.stream()
                .map(s -> safeText(s.getCargo()) + " - " + safeText(s.getNome()))
                .toList();
        List<String> staffLinesB = staffB.stream()
                .map(s -> safeText(s.getCargo()) + " - " + safeText(s.getNome()))
                .toList();

        List<List<String>> iniciantesA = buildIniciantesGrid(inscritosA, eventos, equipeAId, numeroPorAtleta);
        List<List<String>> iniciantesB = buildIniciantesGrid(inscritosB, eventos, equipeBId, numeroPorAtleta);

        TeamPdfData teamA = new TeamPdfData(
                safeText(Optional.ofNullable(partida.getEquipeA()).map(e -> e.getNomeEquipe()).orElse(null)),
                rowsA, goalsA, capitaoA,
                staffLinesA,
                faltasA1, faltasA2, pausasA1, pausasA2,
                iniciantesA);
        TeamPdfData teamB = new TeamPdfData(
                safeText(Optional.ofNullable(partida.getEquipeB()).map(e -> e.getNomeEquipe()).orElse(null)),
                rowsB, goalsB, capitaoB,
                staffLinesB,
                faltasB1, faltasB2, pausasB1, pausasB2,
                iniciantesB);

        // Resolve campeonato from equipe or modalidade
        var campeonatoOpt = Optional.ofNullable(partida.getEquipeA())
                .map(eq -> eq.getCampeonato())
                .or(() -> Optional.ofNullable(partida.getEquipeB()).map(eq -> eq.getCampeonato()));
        String competicao = safeText(campeonatoOpt.map(c -> c.getNome())
                .orElse(Optional.ofNullable(partida.getModalidade())
                        .map(m -> m.getCampeonatoNome()).orElse(null)));
        String escudoCompeticao = campeonatoOpt.map(c -> c.getEscudoUrl()).orElse(null);

        String categoria = safeText(Optional.ofNullable(partida.getCategoria())
                .orElse(null));
        String dataStr = Optional.ofNullable(partida.getAgendadoPara())
                .map(DATE_FMT::format).orElse("");
        String numeroJogo = textOrBlank(partida.getId() != null
                ? partida.getId().toString().substring(0, 8).toUpperCase(Locale.ROOT)
                : null);
        String fase = safeText(Optional.ofNullable(partida.getFase())
                .orElse(null));
        String[] localParts = splitLocal(partida.getLocal());

        String escudoA = partida.getEquipeA() != null && partida.getEquipeA().getAtletica() != null
                ? partida.getEquipeA().getAtletica().getEscudoUrl()
                : null;
        String escudoB = partida.getEquipeB() != null && partida.getEquipeB().getAtletica() != null
                ? partida.getEquipeB().getAtletica().getEscudoUrl()
                : null;

        PeriodSummary ps = buildPeriodSummary(partida, eventos, equipeAId, equipeBId, tempoPeriodo);
        String headerSchedule = safeText(Optional.ofNullable(partida.getAgendadoPara())
                .map(ts -> DATE_FMT.format(ts) + " - " + TIME_FMT.format(ts)).orElse(null));

        return new SumulaData(teamA, teamB, competicao, categoria, numeroJogo, "", fase, dataStr,
                localParts[0], localParts[1], buildArbitrationLines(arbitros), ps,
                headerSchedule, safeText(teamA.nome() + " x " + teamB.nome()),
                escudoA, escudoB, escudoCompeticao);
    }

    private void putIfPresent(Map<UUID, Integer> map, CampeonatoAtleta i) {
        if (i.getAtleta() != null && i.getAtleta().getId() != null && i.getNumeroCamisa() != null)
            map.put(i.getAtleta().getId(), i.getNumeroCamisa());
    }

    private RosterRow rosterRow(CampeonatoAtleta inscrito, List<EventoPartida> ev) {
        String inscricaoId = inscrito.getId() != null
                ? inscrito.getId().toString().substring(0, 8).toUpperCase(Locale.ROOT)
                : "";

        String nomeAtleta = Optional.ofNullable(inscrito.getAtleta())
                .map(a -> a.getUser() != null && a.getUser().getNomeCompleto() != null ? a.getUser().getNomeCompleto()
                        : a.getNomeCompeticao())
                .orElse("");
        if (Boolean.TRUE.equals(inscrito.getIsGoleiro())) {
            nomeAtleta += " (G)";
        }
        if (Boolean.TRUE.equals(inscrito.getIsCapitao())) {
            nomeAtleta += " (C)";
        }

        return new RosterRow(
                inscricaoId,
                textOrBlank(Optional.ofNullable(inscrito.getNumeroCamisa()).map(String::valueOf).orElse(null)),
                safeText(nomeAtleta.isBlank() ? null : nomeAtleta),
                firstTempoOfTipo(ev, "CARTAO_AMARELO"),
                firstTempoOfTipo(ev, "CARTAO_VERMELHO"));
    }

    private String firstTempoOfTipo(List<EventoPartida> eventos, String tipo) {
        if (eventos == null)
            return "";
        return eventos.stream().filter(e -> isTipo(e, tipo))
                .map(e -> textOrBlank(e.getTempoCronometro()))
                .filter(s -> !s.isBlank()).findFirst().orElse("");
    }

    private List<GoalEntry> buildGoals(List<EventoPartida> eventos, UUID equipeId,
            Map<UUID, Integer> numMap, int tempoPeriodo) {
        if (equipeId == null)
            return List.of();
        return eventos.stream()
                .filter(e -> isTipo(e, "GOL"))
                .filter(e -> e.getEquipe() != null && Objects.equals(e.getEquipe().getId(), equipeId))
                .map(e -> new GoalEntry(
                        textOrBlank(Optional.ofNullable(e.getAtleta())
                                .map(a -> numMap.get(a.getId())).map(String::valueOf).orElse("")),
                        textOrBlank(e.getTempoCronometro()),
                        resolvePeriod(e.getTempoCronometro(), tempoPeriodo)))
                .limit(MAX_GOALS).toList();
    }

    private List<String> buildArbitrationLines(List<PartidaArbitro> arbitros) {
        if (arbitros == null)
            return List.of();
        return arbitros.stream()
                .map(a -> safeText(a.getFuncao()) + " - " + safeText(
                        a.getArbitro() == null ? null : a.getArbitro().getNomeExibicao()))
                .toList();
    }

    private PeriodSummary buildPeriodSummary(Partida partida, List<EventoPartida> eventos,
            UUID equipeAId, UUID equipeBId, int tempoPeriodo) {
        OffsetDateTime fim1 = firstCreatedAtOfTipo(eventos, "FIM_1_TEMPO");
        OffsetDateTime inicio2 = firstCreatedAtOfTipo(eventos, "INICIO_2_TEMPO");
        OffsetDateTime inicioProrrogacao = firstCreatedAtOfTipo(eventos, "PRORROGACAO");
        OffsetDateTime fimPartida = firstCreatedAtOfTipo(eventos, "FIM_PARTIDA");
        int golsA1 = countGoals(eventos, equipeAId, 1, tempoPeriodo);
        int golsB1 = countGoals(eventos, equipeBId, 1, tempoPeriodo);
        int golsA2 = countGoals(eventos, equipeAId, 2, tempoPeriodo);
        int golsB2 = countGoals(eventos, equipeBId, 2, tempoPeriodo);
        int golsAE = countGoals(eventos, equipeAId, 3, tempoPeriodo);
        int golsBE = countGoals(eventos, equipeBId, 3, tempoPeriodo);
        return new PeriodSummary(
                Optional.ofNullable(partida.getAgendadoPara()).map(TIME_FMT::format).orElse(""),
                Optional.ofNullable(partida.getIniciadaEm()).map(TIME_FMT::format).orElse(""),
                Optional.ofNullable(fim1).map(TIME_FMT::format).orElse(""),
                Optional.ofNullable(inicio2).map(TIME_FMT::format).orElse(""),
                Optional.ofNullable(partida.getEncerradaEm()).map(TIME_FMT::format).orElse(""),
                golsA1, golsB1, golsA2, golsB2,
                Optional.ofNullable(partida.getPlacarA()).orElse(golsA1 + golsA2 + golsAE),
                Optional.ofNullable(partida.getPlacarB()).orElse(golsB1 + golsB2 + golsBE),
                golsAE, golsBE,
                Optional.ofNullable(inicioProrrogacao).map(TIME_FMT::format).orElse(""),
                Optional.ofNullable(fimPartida).map(TIME_FMT::format).orElse(""));
    }

    private OffsetDateTime firstCreatedAtOfTipo(List<EventoPartida> eventos, String tipo) {
        return eventos.stream().filter(e -> isTipo(e, tipo))
                .map(EventoPartida::getCriadoEm).filter(Objects::nonNull).findFirst().orElse(null);
    }

    private int countGoals(List<EventoPartida> eventos, UUID equipeId, int period, int tempoPeriodo) {
        if (equipeId == null)
            return 0;
        OffsetDateTime tInicio2 = firstCreatedAtOfTipo(eventos, "INICIO_2_TEMPO");
        return (int) eventos.stream()
                .filter(e -> isTipo(e, "GOL"))
                .filter(e -> e.getEquipe() != null && Objects.equals(e.getEquipe().getId(), equipeId))
                .filter(e -> {
                    OffsetDateTime t = e.getCriadoEm();
                    if (t == null)
                        return period == 1;
                    int p = (tInicio2 != null && t.isAfter(tInicio2)) ? 2 : 1;
                    // period 3 = extra time (after 2nd period goals tracked separately)
                    if (period == 3) {
                        OffsetDateTime tFim2 = firstCreatedAtOfTipo(eventos, "FIM_2_TEMPO");
                        return tFim2 != null && t.isAfter(tFim2);
                    }
                    return p == period;
                })
                .count();
    }

    private int countFaltas(List<EventoPartida> eventos, UUID equipeId, int period, int tempoPeriodo) {
        if (equipeId == null)
            return 0;
        OffsetDateTime tInicio2 = firstCreatedAtOfTipo(eventos, "INICIO_2_TEMPO");
        return (int) eventos.stream()
                .filter(e -> isTipo(e, "FALTA"))
                .filter(e -> e.getEquipe() != null && Objects.equals(e.getEquipe().getId(), equipeId))
                .filter(e -> {
                    OffsetDateTime t = e.getCriadoEm();
                    if (t == null)
                        return period == 1;
                    int p = (tInicio2 != null && t.isAfter(tInicio2)) ? 2 : 1;
                    return p == period;
                })
                .count();
    }

    private int countPausas(List<EventoPartida> eventos, UUID equipeId, int targetPeriod) {
        if (equipeId == null)
            return 0;
        OffsetDateTime tInicio2 = firstCreatedAtOfTipo(eventos, "INICIO_2_TEMPO");
        System.out.println(
                "[DEBUG countPausas] equipeId=" + equipeId + " targetPeriod=" + targetPeriod + " tInicio2=" + tInicio2);

        // Log all events to see what tipo names exist
        eventos.forEach(e -> {
            String tipoNome = e.getTipoEvento() != null ? e.getTipoEvento().getNome() : "NULL";
            UUID evEquipeId = e.getEquipe() != null ? e.getEquipe().getId() : null;
            System.out.println("[DEBUG countPausas] evento tipo=" + tipoNome
                    + " equipe=" + evEquipeId
                    + " criadoEm=" + e.getCriadoEm()
                    + " isPausaTecnica=" + "PAUSA_TECNICA".equalsIgnoreCase(tipoNome)
                    + " equipeMatch=" + Objects.equals(evEquipeId, equipeId));
        });

        long count = eventos.stream()
                .filter(e -> isTipo(e, "PAUSA_TECNICA"))
                .filter(e -> e.getEquipe() != null && Objects.equals(e.getEquipe().getId(), equipeId))
                .filter(e -> {
                    OffsetDateTime tPausa = e.getCriadoEm();
                    if (tPausa == null)
                        return targetPeriod == 1;
                    int period = (tInicio2 != null && tPausa.isAfter(tInicio2)) ? 2 : 1;
                    return period == targetPeriod;
                })
                .count();
        System.out.println(
                "[DEBUG countPausas] RESULT equipeId=" + equipeId + " period=" + targetPeriod + " count=" + count);
        return (int) count;
    }

    private int resolvePeriod(String tempo, int tempoPeriodo) {
        int s = parseSeconds(tempo);
        if (s <= 0 || s <= tempoPeriodo * 60)
            return 1;
        if (s <= tempoPeriodo * 2 * 60)
            return 2;
        return 3;
    }

    private int parseSeconds(String tempo) {
        if (tempo == null || !tempo.contains(":"))
            return 0;
        try {
            String[] p = tempo.trim().split(":");
            return Integer.parseInt(p[0]) * 60 + Integer.parseInt(p[1]);
        } catch (RuntimeException e) {
            return 0;
        }
    }

    private boolean isTipo(EventoPartida e, String tipo) {
        return e.getTipoEvento() != null && tipo.equalsIgnoreCase(e.getTipoEvento().getCodigo());
    }

    /**
     * Builds the "Iniciantes" grid for a team.
     * Column 0..4 = one per starter position.
     * Row 0 = starter jersey number, row 1+ = substitution chain.
     */
    private List<List<String>> buildIniciantesGrid(
            List<CampeonatoAtleta> inscritos,
            List<EventoPartida> eventos,
            UUID equipeId,
            Map<UUID, Integer> numeroPorAtleta) {
        if (equipeId == null)
            return List.of();

        System.out.println("[DEBUG buildIniciantesGrid] equipeId=" + equipeId);
        System.out.println("[DEBUG buildIniciantesGrid] total inscritos=" + inscritos.size());
        inscritos.forEach(i -> System.out.println("[DEBUG buildIniciantesGrid] inscrito: atletaId="
                + (i.getAtleta() != null ? i.getAtleta().getId() : "null")
                + " numero=" + i.getNumeroCamisa()
                + " status=" + i.getStatus()));

        // Substitution events for this team, ordered by criadoEm (already sorted)
        List<EventoPartida> subs = eventos.stream()
                .filter(e -> Boolean.TRUE.equals(e.getIsSubstitution()))
                .filter(e -> e.getEquipe() != null && Objects.equals(e.getEquipe().getId(), equipeId))
                .filter(e -> e.getAtleta() != null && e.getAtletaSai() != null)
                .toList();

        System.out.println("[DEBUG buildIniciantesGrid] substitution events found=" + subs.size());
        subs.forEach(s -> System.out.println("[DEBUG buildIniciantesGrid] sub: atletaEntra="
                + s.getAtleta().getId() + " (num=" + numeroPorAtleta.get(s.getAtleta().getId()) + ")"
                + " atletaSai=" + s.getAtletaSai().getId() + " (num=" + numeroPorAtleta.get(s.getAtletaSai().getId())
                + ")"
                + " isSubstitution=" + s.getIsSubstitution()));

        // Players who ENTERED via substitution cannot be starters
        Set<UUID> enteredViaSub = subs.stream()
                .map(e -> e.getAtleta().getId())
                .collect(Collectors.toSet());

        System.out.println("[DEBUG buildIniciantesGrid] enteredViaSub=" + enteredViaSub);

        // Starters = first 5 inscritos (sorted by jersey number) who did NOT enter via
        // substitution
        List<UUID> starters = inscritos.stream()
                .sorted(Comparator.comparing(i -> Optional.ofNullable(i.getNumeroCamisa()).orElse(999)))
                .filter(i -> i.getAtleta() != null && !enteredViaSub.contains(i.getAtleta().getId()))
                .limit(5)
                .map(i -> i.getAtleta().getId())
                .toList();

        System.out.println("[DEBUG buildIniciantesGrid] starters (by exclusion) found=" + starters.size());
        starters.forEach(id -> System.out.println("[DEBUG buildIniciantesGrid] starter: atletaId=" + id
                + " numero=" + numeroPorAtleta.get(id)));

        // Build chain for each starter
        List<List<String>> columns = new ArrayList<>();
        for (UUID starterId : starters) {
            List<String> chain = new ArrayList<>();
            chain.add(String.valueOf(numeroPorAtleta.getOrDefault(starterId, 0)));

            UUID currentId = starterId;
            for (int safety = 0; safety < 20; safety++) {
                UUID cur = currentId;
                Optional<EventoPartida> subEvent = subs.stream()
                        .filter(e -> Objects.equals(e.getAtletaSai().getId(), cur))
                        .findFirst();
                if (subEvent.isPresent()) {
                    UUID nextId = subEvent.get().getAtleta().getId();
                    chain.add(String.valueOf(numeroPorAtleta.getOrDefault(nextId, 0)));
                    System.out.println("[DEBUG buildIniciantesGrid] chain: " + numeroPorAtleta.get(cur)
                            + " -> " + numeroPorAtleta.get(nextId));
                    currentId = nextId;
                } else {
                    break;
                }
            }
            System.out.println("[DEBUG buildIniciantesGrid] column chain=" + chain);
            columns.add(chain);
        }

        // Pad to 5 columns if fewer starters found
        while (columns.size() < 5) {
            columns.add(new ArrayList<>(List.of("")));
        }

        System.out.println("[DEBUG buildIniciantesGrid] final grid columns=" + columns.size());
        return columns;
    }

    // ─── HTML RENDERING ─────────────────────────────────────────────────────────

    private byte[] renderHtmlToPdf(String html) {
        try (ByteArrayOutputStream os = new ByteArrayOutputStream()) {
            PdfRendererBuilder builder = new PdfRendererBuilder();
            builder.useFastMode();
            builder.withHtmlContent(html, null);
            builder.toStream(os);
            builder.run();
            return os.toByteArray();
        } catch (Exception e) {
            throw new IllegalStateException("Não foi possível gerar a súmula oficial em PDF.", e);
        }
    }

    // ─── HTML GENERATION ────────────────────────────────────────────────────────

    private String buildHtml(SumulaData data) {
        return "<!DOCTYPE html>\n<html lang=\"pt-BR\">\n<head>\n"
                + "<meta charset=\"UTF-8\"/>\n"
                + "<style>" + css() + "</style>\n"
                + "</head>\n<body>\n"
                + "<div class=\"page\">"
                + headerHtml(data)
                + gameInfoHtml(data)
                + teamBlockHtml(data.teamA(), "A", data.periodSummary(), true)
                + teamBlockHtml(data.teamB(), "B", data.periodSummary(), false)
                + footerHtml(data)
                + "</div>\n</body>\n</html>";
    }

    // ── Header ───────────────────────────────────────────────────────────────────

    private String headerHtml(SumulaData data) {
        PeriodSummary ps = data.periodSummary();
        String placarStr = ps.goalsAFinal() + " x " + ps.goalsBFinal();
        return "<table class=\"hdr\" cellpadding=\"0\" cellspacing=\"0\">\n<tr>\n"
                + "<td class=\"hdr-left\">"
                + imgTag(data.escudoCompeticao())
                + "<div class=\"hdr-name\">" + e(data.competicao()) + "</div>"
                + "</td>\n"
                + "<td class=\"hdr-center\" align=\"center\">"
                + "<table cellpadding=\"0\" cellspacing=\"0\" style=\"margin: 0 auto;\">\n<tr>\n"
                + "<td style=\"text-align:right; vertical-align:middle; padding:0 10px;\">"
                + imgTag(data.escudoA()) + "</td>\n"
                + "<td style=\"text-align:center; vertical-align:middle; font-weight:bold; font-size:13px;\">"
                + e(data.headerMatchup())
                + "<div style=\"font-size:14px; font-weight:bold; margin-top:2px;\">" + e(placarStr) + "</div>"
                + "</td>\n"
                + "<td style=\"text-align:left; vertical-align:middle; padding:0 10px;\">"
                + imgTag(data.escudoB()) + "</td>\n"
                + "</tr>\n</table>"
                + "</td>\n"
                + "</tr>\n</table>\n";
    }

    private String imgTag(String url) {
        if (url == null || url.isBlank())
            return "";
        String dataUri = toBase64DataUri(url);
        if (dataUri == null)
            return "";
        return "<img src=\"" + dataUri + "\" style=\"width:45px; height:auto;\"/>";
    }

    /**
     * Downloads an image from a URL, converts it to PNG, and returns a base64 data
     * URI.
     * This is necessary because openhtmltopdf doesn't support WebP and may have
     * issues
     * fetching remote URLs.
     */
    private String toBase64DataUri(String url) {
        try {
            byte[] imageBytes = URI.create(url).toURL().openStream().readAllBytes();
            BufferedImage img = ImageIO.read(new ByteArrayInputStream(imageBytes));
            if (img == null)
                return null;
            ByteArrayOutputStream pngOut = new ByteArrayOutputStream();
            ImageIO.write(img, "png", pngOut);
            String b64 = Base64.getEncoder().encodeToString(pngOut.toByteArray());
            return "data:image/png;base64," + b64;
        } catch (Exception ex) {
            System.err.println("Failed to load image: " + url + " => " + ex.getMessage());
            return null;
        }
    }

    // ── Game info ────────────────────────────────────────────────────────────────

    private String gameInfoHtml(SumulaData data) {
        return "<div class=\"game-info\">"
                + "Horário estimado do jogo: " + e(data.headerSchedule())
                + "</div>\n";
    }

    // ── Team block ───────────────────────────────────────────────────────────────

    private String teamBlockHtml(TeamPdfData team, String letter, PeriodSummary ps, boolean showGeral) {
        return "<table class=\"team-tbl\" cellpadding=\"0\" cellspacing=\"0\">\n<tr>\n"
                + colPlayersHtml(team, letter)
                + colCardsHtml(team)
                + colMetasHtml(team)
                + colFaltasHtml(team)
                + (showGeral ? colGeralContagensHtml(ps) : "")
                + "</tr>\n"
                + "<tr><td colspan=\"" + (showGeral ? 5 : 4) + "\" class=\"obs-row\"></td></tr>\n"
                + "</table>\n";
    }

    private String colPlayersHtml(TeamPdfData team, String letter) {
        StringBuilder sb = new StringBuilder();
        sb.append("<td class=\"col-players\">\n");
        sb.append("<div class=\"col-title\">Saída da Equipe &quot;").append(letter)
                .append("&quot; ( X ) ").append(e(team.nome())).append("</div>\n");
        // Players table
        sb.append("<table class=\"itbl\" cellpadding=\"0\" cellspacing=\"0\">\n");
        sb.append("<tr>");
        sb.append("<th style=\"width:40px; border-top:none; border-left:none;\">Inscrição</th>");
        sb.append("<th style=\"width:25px; border-top:none;\">Nº</th>");
        sb.append("<th style=\"border-top:none; border-right:none;\">Jogadores</th>");
        sb.append("</tr>\n");
        List<RosterRow> rows = team.rows();
        for (int i = 0; i < MAX_PLAYERS; i++) {
            RosterRow row = i < rows.size() ? rows.get(i) : new RosterRow("", "", "", "", "");
            sb.append("<tr>");
            sb.append("<td style=\"border-left:none; text-align:center; font-size:6px;\">").append(e(row.inscricao()))
                    .append("</td>");
            sb.append("<td style=\"text-align:center;\">").append(e(row.numero())).append("</td>");
            sb.append("<td style=\"border-right:none; text-align:left; padding-left:4px; font-size:7px;\">")
                    .append(e(row.nome())).append("</td>");
            sb.append("</tr>\n");
        }
        sb.append("</table>\n");
        // Staff
        List<String> staff = team.staffLines();
        for (int i = 0; i < 5; i++) {
            String line = i < staff.size() ? staff.get(i) : "";
            String style = i == 4 ? " style=\"border-bottom:none;\"" : "";
            sb.append("<div class=\"staff-row\"" + style + ">").append(e(line)).append("</div>\n");
        }
        sb.append("</td>\n");
        return sb.toString();
    }

    private String colCardsHtml(TeamPdfData team) {
        StringBuilder sb = new StringBuilder();
        sb.append("<td class=\"col-cards\">\n");
        sb.append("<div class=\"col-title\" style=\"text-align:center;\">Técnico</div>\n");
        sb.append("<table class=\"itbl\" cellpadding=\"0\" cellspacing=\"0\">\n");
        sb.append("<tr>");
        sb.append("<th style=\"width:22px; border-top:none; border-left:none;\">N</th>");
        sb.append("<th style=\"border-top:none;\">Amar.</th>");
        sb.append("<th style=\"border-top:none;\">Verm.</th>");
        sb.append("<th colspan=\"5\" style=\"border-top:none; border-right:none;\">Iniciantes</th>");
        sb.append("</tr>\n");
        List<RosterRow> rows = team.rows();
        List<List<String>> grid = team.iniciantesGrid();
        for (int i = 0; i < MAX_PLAYERS; i++) {
            RosterRow row = i < rows.size() ? rows.get(i) : new RosterRow("", "", "", "", "");
            sb.append("<tr>");
            sb.append("<td style=\"border-left:none;\">").append(e(row.numero())).append("</td>");
            sb.append("<td>").append(e(row.amarelo())).append("</td>");
            sb.append("<td>").append(e(row.vermelho())).append("</td>");
            for (int col = 0; col < 5; col++) {
                String value = "";
                if (col < grid.size() && i < grid.get(col).size()) {
                    value = grid.get(col).get(i);
                }
                String style = col == 4 ? " style=\"border-right:none;\"" : "";
                sb.append("<td").append(style).append(">").append(e(value)).append("</td>");
            }
            sb.append("</tr>\n");
        }
        sb.append("</table>\n</td>\n");
        return sb.toString();
    }

    private String colMetasHtml(TeamPdfData team) {
        StringBuilder sb = new StringBuilder();
        sb.append("<td class=\"col-metas\">\n");
        sb.append("<div class=\"col-title\" style=\"text-align:center;\">Capitão (")
                .append(e(team.capitao())).append(")</div>\n");
        sb.append("<div class=\"metas-label\">Metas</div>\n");
        sb.append("<table class=\"metas-tbl\" cellpadding=\"0\" cellspacing=\"0\">\n");
        List<GoalEntry> goals = team.goals();
        for (int r = 0; r < 9; r++) {
            sb.append("<tr>\n");
            for (int c = 0; c < 3; c++) {
                int idx = r * 3 + c;
                String num = idx < goals.size() ? e(goals.get(idx).numeroJogador()) : "";
                String tempo = idx < goals.size() ? e(goals.get(idx).tempo()) : "";
                String rightBorder = c == 2 ? "border-right:none;" : "";
                sb.append("<td style=\"").append(rightBorder).append(" vertical-align:top; padding:0;\">");
                sb.append("<table cellpadding=\"0\" cellspacing=\"0\" style=\"width:100%;\">");
                sb.append("<tr>");
                sb.append("<td class=\"meta-idx\">").append(idx + 1).append("</td>");
                sb.append("<td class=\"meta-content\">");
                if (!num.isEmpty())
                    sb.append("<strong>").append(num).append("</strong>");
                if (!tempo.isEmpty())
                    sb.append("<br/>").append(tempo);
                sb.append("</td>");
                sb.append("</tr>");
                sb.append("</table>");
                sb.append("</td>\n");
            }
            sb.append("</tr>\n");
        }
        sb.append("</table>\n</td>\n");
        return sb.toString();
    }

    private String colFaltasHtml(TeamPdfData team) {
        StringBuilder sb = new StringBuilder();
        sb.append("<td class=\"col-geral\" style=\"width:94px; padding:0;\">\n");
        sb.append(
                "<table cellpadding=\"0\" cellspacing=\"0\" style=\"width:100%; height:100%; border-collapse:collapse;\">\n");

        // Faltas Acumuladas Section
        sb.append(
                "<tr><td style=\"height:50%; border-bottom:1px solid #000; vertical-align:top; text-align:center; padding:4px 0;\">\n");
        sb.append(
                "<div style=\"background:#000; color:#fff; font-size:7px; font-weight:bold; padding:2px; margin:0 2px 4px 2px;\">FALTAS ACUMULADAS</div>\n");
        sb.append("<div style=\"font-size:7px; font-weight:bold; margin-bottom:2px;\">1º Período</div>\n");
        sb.append(faltasBoxesHtml(team.faltas1()));
        sb.append(
                "<div style=\"font-size:7px; font-weight:bold; margin-top:4px; margin-bottom:2px;\">2º Período</div>\n");
        sb.append(faltasBoxesHtml(team.faltas2()));
        sb.append("</td></tr>\n");

        // Pedidos de Tempo Section
        sb.append("<tr><td style=\"height:50%; vertical-align:top; text-align:center; padding:4px 0;\">\n");
        sb.append(
                "<div style=\"background:#000; color:#fff; font-size:7px; font-weight:bold; padding:2px; margin:0 2px 4px 2px;\">PEDIDOS DE TEMPO</div>\n");
        sb.append("<div style=\"font-size:7px; font-weight:bold; margin-bottom:2px;\">1º Período</div>\n");
        sb.append(pausasBoxesHtml(team.pausas1()));
        sb.append(
                "<div style=\"font-size:7px; font-weight:bold; margin-top:4px; margin-bottom:2px;\">2º Período</div>\n");
        sb.append(pausasBoxesHtml(team.pausas2()));
        sb.append("</td></tr>\n");

        sb.append("</table>\n</td>\n");
        return sb.toString();
    }

    private String faltasBoxesHtml(int faltas) {
        StringBuilder sb = new StringBuilder();
        sb.append("<table style=\"margin:0 auto;\" cellspacing=\"2\"><tr>");
        for (int i = 1; i <= 5; i++) {
            String bg = (i <= faltas) ? "background:#000; color:#fff;" : "color:#000;";
            sb.append("<td style=\"width:10px; height:10px; border:1px solid #000; text-align:center; font-size:7px; ")
                    .append(bg).append("\">").append(i).append("</td>");
        }
        sb.append("</tr></table>");
        return sb.toString();
    }

    private String pausasBoxesHtml(int pausas) {
        String bg = (pausas >= 1) ? "background:#000;" : "";
        return "<table style=\"margin:0 auto;\" cellspacing=\"0\"><tr>\n"
                + "<td style=\"width:12px; height:12px; border:1px solid #000; " + bg + "\">&#160;</td>\n"
                + "</tr></table>";
    }

    private String colGeralContagensHtml(PeriodSummary ps) {
        StringBuilder sb = new StringBuilder();
        sb.append("<td class=\"col-geral\">\n");

        // Em Geral content
        sb.append("<div class=\"geral-title\">Em Geral</div>\n");

        // Schedule table
        sb.append("<table class=\"itbl\" cellpadding=\"0\" cellspacing=\"0\">\n");
        sb.append("<tr style=\"background:#f5f5f5;\">");
        sb.append("<th style=\"width:55px; border-top:none; border-left:none;\">Agendar</th>");
        sb.append("<th style=\"border-top:none;\">Lar</th>");
        sb.append("<th style=\"border-top:none; border-right:none;\">Ter</th>");
        sb.append("</tr>\n");
        sb.append(scheduleRow("1º Período", ps.start1(), ps.end1()));
        sb.append(scheduleRow("2º Período", ps.start2(), ps.end2()));
        sb.append(scheduleRow("P. Extra", ps.startExtra(), ps.endExtra()));
        sb.append("</table>\n");

        // Contagens
        sb.append("<div class=\"contagens-title\">Contagens</div>\n");
        sb.append("<table style=\"width:100%; border-collapse:collapse;\">\n");
        sb.append(scoreRow("1º Período", ps.goalsA1(), ps.goalsB1()));
        sb.append(scoreRow("2º Período", ps.goalsA2(), ps.goalsB2()));
        if (ps.goalsAExtra() > 0 || ps.goalsBExtra() > 0)
            sb.append(scoreRow("P. Extra", ps.goalsAExtra(), ps.goalsBExtra()));
        sb.append(scoreFinalRow("FINAL", ps.goalsAFinal(), ps.goalsBFinal()));
        sb.append("</table>\n");

        sb.append("</td>\n");
        return sb.toString();
    }

    private String scheduleRow(String label, String start, String end) {
        return "<tr>"
                + "<td style=\"border-left:none; font-size:9px;\">" + e(label) + "</td>"
                + "<td>" + e(start) + "</td>"
                + "<td style=\"border-right:none;\">" + e(end) + "</td>"
                + "</tr>\n";
    }

    private String scoreRow(String label, int a, int b) {
        return "<tr style=\"height:20px;\">"
                + "<td style=\"border:none; font-size:9px; width:50px; vertical-align:middle;\">" + e(label) + "</td>"
                + "<td style=\"border:none; width:32px; vertical-align:middle;\">"
                + "<div class=\"placar-box\">" + a + "</div></td>"
                + "<td style=\"border:none; padding:0 2px; vertical-align:middle; text-align:center; width:12px;\">X</td>"
                + "<td style=\"border:none; width:32px; vertical-align:middle;\">"
                + "<div class=\"placar-box\">" + b + "</div></td>"
                + "</tr>\n";
    }

    private String scoreFinalRow(String label, int a, int b) {
        return "<tr style=\"height:20px;\">"
                + "<td style=\"border:none; font-size:9px; font-weight:bold; width:50px; vertical-align:middle;\">"
                + e(label) + "</td>"
                + "<td style=\"border:none; width:32px; vertical-align:middle;\">"
                + "<div class=\"placar-box placar-final\">" + a + "</div></td>"
                + "<td style=\"border:none; padding:0 2px; vertical-align:middle; text-align:center; width:12px;\">X</td>"
                + "<td style=\"border:none; width:32px; vertical-align:middle;\">"
                + "<div class=\"placar-box placar-final\">" + b + "</div></td>"
                + "</tr>\n";
    }

    // ── Footer ───────────────────────────────────────────────────────────────────

    private String footerHtml(SumulaData data) {
        StringBuilder sb = new StringBuilder();
        sb.append("<div class=\"footer\">\n");

        // Identificação (full-width)
        sb.append("<div class=\"fw-row\">Identificação do Jogo").append("</div>\n");

        // Competição / Categoria
        sb.append("<table cellpadding=\"0\" cellspacing=\"0\" class=\"ft-row\">\n<tr>\n");
        sb.append("<td class=\"ft-label\">Competição: ").append(e(data.competicao())).append("</td>\n");
        sb.append("<td class=\"ft-value\">Categoria: ").append(e(data.categoria())).append("</td>\n");
        sb.append("</tr>\n</table>\n");

        // Nº Jogo / Grupo / Fase / Data
        sb.append("<table cellpadding=\"0\" cellspacing=\"0\" class=\"ft-row\">\n<tr>\n");
        sb.append("<td class=\"ft-quarter\">Nº Jogo: ").append(e(data.numeroJogo())).append("</td>\n");
        sb.append("<td class=\"ft-quarter\">Grupo: ").append(e(data.grupo())).append("</td>\n");
        sb.append("<td class=\"ft-quarter\">Fase: ").append(e(data.fase())).append("</td>\n");
        sb.append("<td class=\"ft-quarter\">Data: ").append(e(data.data())).append("</td>\n");
        sb.append("</tr>\n</table>\n");

        // Equipe de Arbitragem (full-width)
        sb.append("<div class=\"fw-row\">Equipe de Arbitragem</div>\n");

        // Arbitration lines
        List<String> arb = data.arbitrationLines();
        for (String line : arb) {
            sb.append("<table cellpadding=\"0\" cellspacing=\"0\" class=\"ft-row\">\n<tr>\n");
            sb.append("<td class=\"ft-arb\">").append(e(line)).append("</td>\n");
            sb.append("<td class=\"ft-sig\"></td>\n");
            sb.append("</tr>\n</table>\n");
        }

        sb.append("</div>\n");
        return sb.toString();
    }

    // ─── CSS ────────────────────────────────────────────────────────────────────

    private static String css() {
        return """
                @page { size: A4; margin: 2mm; }
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { font-family: Arial, sans-serif; font-size: 9px; }
                .page { border: 2px solid black; }

                /* HEADER */
                .hdr { width: 100%; border-collapse: collapse; border-bottom: 2px solid black; }
                .hdr-left { width: 100px; border-right: 2px solid black; padding: 4px;
                    vertical-align: middle; text-align: center; }
                .hdr-center { padding: 4px; vertical-align: middle; }
                .hdr-name { font-size: 8px; font-weight: bold; text-align: center; line-height: 1.1; }

                /* GAME INFO */
                .game-info { border-bottom: 2px solid black; padding: 3px 6px; text-align: right;
                    font-size: 8px; font-weight: bold; }

                /* TEAM BLOCK */
                .team-tbl { width: 100%; border-collapse: collapse; border-bottom: 2px solid black; }
                .col-players { width: 28%; border-right: 1px solid black; vertical-align: top; }
                .col-cards   { width: 20%; border-right: 1px solid black; vertical-align: top; }
                .col-metas   { width: 26%; border-right: 1px solid black; vertical-align: top; }
                .col-geral   { vertical-align: top; }
                .obs-row { height: 30px; border-top: 1px solid black; padding: 2px;
                    vertical-align: top; font-size: 7px; color: #bbb; }

                /* COLUMN TITLE */
                .col-title { border-bottom: 1px solid black; padding: 2px 4px; font-weight: bold;
                    font-size: 8px; min-height: 18px; }

                /* INNER TABLE (players / cards / schedule) */
                .itbl { width: 100%; border-collapse: collapse; }
                .itbl th { border: 1px solid black; padding: 1px 1px; font-size: 7px;
                    font-weight: bold; text-align: center; background: #f5f5f5; }
                .itbl td { border: 1px solid black; padding: 0 1px; font-size: 7px;
                    text-align: center; height: 14px; vertical-align: middle; }

                /* STAFF */
                .staff-row { border-top: 1px solid black; border-bottom: 1px solid black;
                    padding: 1px 3px; font-size: 7px; min-height: 14px; }

                /* METAS */
                .metas-label { padding: 1px 4px; font-size: 7px; border-bottom: 1px solid black;
                    background: #fff; }
                .metas-tbl { width: 100%; border-collapse: collapse; }
                .metas-tbl td { border: 1px solid black; height: 30px; width: 33.33%; }
                .meta-idx { width: 16px; border-right: 1px solid black; text-align: center;
                    font-size: 6px; background: #f9f9f9; padding: 1px; vertical-align: middle; }
                .meta-content { text-align: center; font-size: 7px; vertical-align: middle;
                    padding: 1px; }

                /* V-BAR */
                .v-bar { background: #000; vertical-align: top; text-align: center;
                    border-right: 1px solid #555; padding-top: 2px; }
                .v-bar-text { color: #fff; font-size: 6px; font-weight: bold;
                    line-height: 1.1; text-align: center; letter-spacing: 0; }

                /* GERAL */
                .geral-title { background: #f5f5f5; border-bottom: 1px solid black;
                    padding: 2px; font-weight: bold; font-size: 7px; text-align: center; }
                .contagens-title { padding: 2px 4px; font-size: 7px; font-weight: bold;
                    border-top: 1px solid black; }
                .placar-box { border: 1px solid black; width: 22px; height: 18px;
                    display: inline-block; text-align: center; font-weight: bold;
                    font-size: 10px; line-height: 18px; vertical-align: middle; }
                .placar-final { background: #fffacd; }

                /* FOOTER */
                .footer { padding: 3px 4px; }
                .fw-row { border: 1px solid black; margin-bottom: 1px; padding: 2px 4px;
                    text-align: center; background: #f5f5f5; font-weight: bold; font-size: 8px;
                    min-height: 16px; }
                .ft-row { width: 100%; border-collapse: collapse; margin-bottom: 1px; }
                .ft-label { border: 1px solid black; padding: 2px 3px; font-weight: bold;
                    font-size: 7px; width: 55%; vertical-align: middle; }
                .ft-value { border: 1px solid black; padding: 2px 3px; font-size: 7px;
                    vertical-align: middle; }
                .ft-quarter { border: 1px solid black; padding: 2px 3px; font-size: 7px;
                    width: 25%; vertical-align: middle; }
                .ft-arb { border: 1px solid black; padding: 2px 3px; font-weight: bold;
                    font-size: 7px; width: 65%; vertical-align: middle; min-height: 16px; }
                .ft-sig { border: 1px solid black; font-size: 7px; vertical-align: middle; }
                """;
    }

    // ─── UTILITY ────────────────────────────────────────────────────────────────

    private static String e(String value) {
        if (value == null)
            return "";
        return value.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;");
    }

    private String safeText(String value) {
        return value == null || value.isBlank() ? "" : sanitize(value);
    }

    private String textOrBlank(String value) {
        return value == null ? "" : sanitize(value);
    }

    private String sanitize(String value) {
        return value.replace('\u0000', ' ').replace('\n', ' ').replace('\r', ' ')
                .replaceAll("\\s+", " ").trim();
    }

    private String[] splitLocal(String local) {
        if (local == null || local.isBlank())
            return new String[] { "", "" };
        for (String sep : new String[] { "/", " - ", " — ", "," }) {
            if (local.contains(sep)) {
                String[] p = local.split(java.util.regex.Pattern.quote(sep), 2);
                return new String[] { safeText(p[0]), safeText(p[1]) };
            }
        }
        return new String[] { safeText(local), "" };
    }

    // ─── RECORDS ────────────────────────────────────────────────────────────────

    private record SumulaData(
            TeamPdfData teamA, TeamPdfData teamB,
            String competicao, String categoria, String numeroJogo, String grupo,
            String fase, String data, String ginasio, String cidade,
            List<String> arbitrationLines, PeriodSummary periodSummary,
            String headerSchedule, String headerMatchup,
            String escudoA, String escudoB, String escudoCompeticao) {
    }

    private record TeamPdfData(
            String nome,
            List<RosterRow> rows,
            List<GoalEntry> goals,
            String capitao,
            List<String> staffLines,
            int faltas1,
            int faltas2,
            int pausas1,
            int pausas2,
            List<List<String>> iniciantesGrid) {
    }

    private record RosterRow(String inscricao, String numero, String nome, String amarelo, String vermelho) {
    }

    private record GoalEntry(String numeroJogador, String tempo, int period) {
    }

    private record PeriodSummary(
            String scheduled1, String start1, String end1, String start2, String end2,
            int goalsA1, int goalsB1, int goalsA2, int goalsB2,
            int goalsAFinal, int goalsBFinal, int goalsAExtra, int goalsBExtra,
            String startExtra, String endExtra) {
    }
}