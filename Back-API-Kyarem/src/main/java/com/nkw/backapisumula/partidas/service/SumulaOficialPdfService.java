package com.nkw.backapisumula.partidas.service;

import com.nkw.backapisumula.competicao.EquipeAtletaInscrito;
import com.nkw.backapisumula.competicao.repo.EquipeAtletaInscritoRepository;
import com.nkw.backapisumula.partidas.EventoPartida;
import com.nkw.backapisumula.partidas.Partida;
import com.nkw.backapisumula.partidas.PartidaArbitro;
import com.nkw.backapisumula.partidas.repo.EventoPartidaRepository;
import com.nkw.backapisumula.partidas.repo.PartidaArbitroRepository;
import com.nkw.backapisumula.partidas.repo.PartidaRepository;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDFont;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class SumulaOficialPdfService {

    private static final String TEMPLATE_PATH = "templates/sumula-futsal-limpa.pdf";
    private static final PDFont FONT = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
    private static final PDFont FONT_BOLD = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("HH:mm");

    private static final float[] TEAM_A_ROW_YS = {
            733.1f, 718.4f, 703.7f, 689.0f, 674.4f, 659.7f, 645.0f, 630.3f, 615.6f, 601.0f, 586.3f, 571.6f, 556.9f, 542.3f
    };
    private static final float[] TEAM_B_ROW_YS = {
            421.4f, 406.7f, 392.1f, 377.4f, 362.7f, 348.0f, 333.3f, 318.7f, 304.0f, 289.3f, 274.6f, 260.0f, 245.3f, 230.6f
    };
    private static final float[] TEAM_A_STAFF_YS = {527.6f, 512.9f, 498.2f, 483.6f};
    private static final float[] TEAM_B_STAFF_YS = {215.9f, 201.3f, 186.6f};

    private static final float X_REG = 10.6f;
    private static final float X_NAME = 48.0f;
    private static final float X_NUM = 154.4f;
    private static final float X_YELLOW = 178f;
    private static final float X_RED = 213f;

    private static final float[] GOAL_COL_X = {265f, 290f, 316f};
    private static final float[] GOAL_TIME_X = {278f, 303f, 329f};
    private static final float GOAL_A_START_Y = 733f;
    private static final float GOAL_B_START_Y = 421f;
    private static final float GOAL_TIME_OFFSET = -12f;
    private static final float GOAL_ROW_STEP = -14.6f;

    private final PartidaRepository partidaRepo;
    private final EventoPartidaRepository eventoRepo;
    private final PartidaArbitroRepository partidaArbitroRepo;
    private final EquipeAtletaInscritoRepository inscritosRepo;

    public SumulaOficialPdfService(
            PartidaRepository partidaRepo,
            EventoPartidaRepository eventoRepo,
            PartidaArbitroRepository partidaArbitroRepo,
            EquipeAtletaInscritoRepository inscritosRepo
    ) {
        this.partidaRepo = partidaRepo;
        this.eventoRepo = eventoRepo;
        this.partidaArbitroRepo = partidaArbitroRepo;
        this.inscritosRepo = inscritosRepo;
    }

    @Transactional(readOnly = true)
    public byte[] gerarPdf(UUID partidaId) {
        Partida partida = partidaRepo.findById(partidaId)
                .orElseThrow(() -> new IllegalStateException("Partida não encontrada."));
        List<EventoPartida> eventos = eventoRepo.findByPartidaIdWithDetails(partidaId);
        List<PartidaArbitro> arbitros = partidaArbitroRepo.findByPartidaIdWithArbitro(partidaId);
        List<EquipeAtletaInscrito> inscritosA = partida.getEquipeA() == null
                ? List.of()
                : inscritosRepo.findByEquipe_Id(partida.getEquipeA().getId());
        List<EquipeAtletaInscrito> inscritosB = partida.getEquipeB() == null
                ? List.of()
                : inscritosRepo.findByEquipe_Id(partida.getEquipeB().getId());

        SumulaData data = buildData(partida, inscritosA, inscritosB, arbitros, eventos);

        try (InputStream in = new ClassPathResource(TEMPLATE_PATH).getInputStream();
             PDDocument document = Loader.loadPDF(in.readAllBytes());
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {

            PDPage page = document.getPage(0);
            try (PDPageContentStream cs = new PDPageContentStream(document, page, PDPageContentStream.AppendMode.APPEND, true, true)) {
                drawHeader(cs, page.getMediaBox(), data, document);
                drawTeam(cs, data.teamA(), TEAM_A_ROW_YS, TEAM_A_STAFF_YS, GOAL_A_START_Y);
                drawTeam(cs, data.teamB(), TEAM_B_ROW_YS, TEAM_B_STAFF_YS, GOAL_B_START_Y);
                drawIdentification(cs, data);
                drawArbitration(cs, data.arbitrationLines());
                drawPeriodSummary(cs, data.periodSummary());
            }

            document.save(out);
            return out.toByteArray();
        } catch (IOException e) {
            throw new IllegalStateException("Não foi possível gerar a súmula oficial em PDF.", e);
        }
    }

    private SumulaData buildData(
            Partida partida,
            List<EquipeAtletaInscrito> inscritosA,
            List<EquipeAtletaInscrito> inscritosB,
            List<PartidaArbitro> arbitros,
            List<EventoPartida> eventos
    ) {
        int tempoPeriodo = Optional.ofNullable(partida.getModalidade())
                .map(m -> m.getTempoPartidaMinutos())
                .filter(v -> v > 0)
                .orElse(20);

        Map<UUID, Integer> numeroPorAtleta = new HashMap<>();
        inscritosA.forEach(i -> putIfPresent(numeroPorAtleta, i));
        inscritosB.forEach(i -> putIfPresent(numeroPorAtleta, i));

        Map<UUID, List<EventoPartida>> eventosPorJogador = eventos.stream()
                .filter(e -> e.getAtleta() != null && e.getAtleta().getId() != null)
                .collect(Collectors.groupingBy(e -> e.getAtleta().getId(), LinkedHashMap::new, Collectors.toList()));

        List<RosterRow> rowsA = inscritosA.stream()
                .sorted(Comparator.comparing(i -> Optional.ofNullable(i.getNumeroCamisa()).orElse(999)))
                .limit(TEAM_A_ROW_YS.length)
                .map(i -> rosterRow(i, eventosPorJogador.get(i.getAtleta().getId())))
                .toList();

        List<RosterRow> rowsB = inscritosB.stream()
                .sorted(Comparator.comparing(i -> Optional.ofNullable(i.getNumeroCamisa()).orElse(999)))
                .limit(TEAM_B_ROW_YS.length)
                .map(i -> rosterRow(i, eventosPorJogador.get(i.getAtleta().getId())))
                .toList();

        UUID equipeAId = partida.getEquipeA() == null ? null : partida.getEquipeA().getId();
        UUID equipeBId = partida.getEquipeB() == null ? null : partida.getEquipeB().getId();

        List<GoalEntry> goalsA = buildGoals(eventos, equipeAId, numeroPorAtleta, tempoPeriodo);
        List<GoalEntry> goalsB = buildGoals(eventos, equipeBId, numeroPorAtleta, tempoPeriodo);

        TeamPdfData teamA = new TeamPdfData(
                safeText(Optional.ofNullable(partida.getEquipeA()).map(e -> e.getNomeEquipe()).orElse(null)),
                rowsA,
                goalsA,
                "Não informado",
                List.of(
                        "Treinador - Não informado",
                        "Preparador Físico - Não informado",
                        "Assistente Técnico - Não informado",
                        "Fisioterapeuta - Não informado"
                )
        );
        TeamPdfData teamB = new TeamPdfData(
                safeText(Optional.ofNullable(partida.getEquipeB()).map(e -> e.getNomeEquipe()).orElse(null)),
                rowsB,
                goalsB,
                "Não informado",
                List.of(
                        "Treinador - Não informado",
                        "Atendente - Não informado",
                        "Preparador Físico - Não informado"
                )
        );

        String competicao = safeText(Optional.ofNullable(partida.getEquipeA())
                .map(e -> e.getCampeonato())
                .map(c -> c.getNome())
                .orElse(Optional.ofNullable(partida.getModalidade()).map(m -> m.getCampeonatoNome()).orElse(null)));
        String categoria = safeText(Optional.ofNullable(partida.getModalidade()).map(m -> m.getNome()).orElse(null));
        String data = Optional.ofNullable(partida.getAgendadoPara()).map(DATE_FMT::format).orElse("Não informado");
        String numeroJogo = textOrBlank(partida.getId() != null ? partida.getId().toString().substring(0, 8).toUpperCase(Locale.ROOT) : null);
        String fase = safeText(Optional.ofNullable(partida.getStatus()).orElse(null));

        String local = safeText(partida.getLocal());
        String[] localParts = splitLocal(partida.getLocal());

        List<String> arbitrationLines = buildArbitrationLines(arbitros);
        PeriodSummary periodSummary = buildPeriodSummary(partida, eventos, equipeAId, equipeBId, tempoPeriodo);

        String escudoA = partida.getEquipeA() != null && partida.getEquipeA().getAtletica() != null 
                ? partida.getEquipeA().getAtletica().getEscudoUrl() : null;
        String escudoB = partida.getEquipeB() != null && partida.getEquipeB().getAtletica() != null 
                ? partida.getEquipeB().getAtletica().getEscudoUrl() : null;

        return new SumulaData(
                teamA,
                teamB,
                competicao,
                categoria,
                numeroJogo,
                "Não informado",
                fase,
                data,
                localParts[0],
                localParts[1],
                arbitrationLines,
                periodSummary,
                safeText(Optional.ofNullable(partida.getAgendadoPara()).map(ts -> DATE_FMT.format(ts) + " - " + TIME_FMT.format(ts)).orElse(null)),
                safeText(teamA.nome() + " x " + teamB.nome()),
                escudoA,
                escudoB
        );
    }

    private void putIfPresent(Map<UUID, Integer> numeroPorAtleta, EquipeAtletaInscrito i) {
        if (i.getAtleta() != null && i.getAtleta().getId() != null && i.getNumeroCamisa() != null) {
            numeroPorAtleta.put(i.getAtleta().getId(), i.getNumeroCamisa());
        }
    }

    private RosterRow rosterRow(EquipeAtletaInscrito inscrito, List<EventoPartida> eventosJogador) {
        String amarelo = firstTempoOfTipo(eventosJogador, "CARTAO_AMARELO");
        String vermelho = firstTempoOfTipo(eventosJogador, "CARTAO_VERMELHO");
        return new RosterRow(
                "",
                safeText(Optional.ofNullable(inscrito.getAtleta()).map(a -> a.getNome()).orElse(null)),
                textOrBlank(Optional.ofNullable(inscrito.getNumeroCamisa()).map(String::valueOf).orElse(null)),
                amarelo,
                vermelho
        );
    }

    private String firstTempoOfTipo(List<EventoPartida> eventosJogador, String tipo) {
        if (eventosJogador == null) return "";
        return eventosJogador.stream()
                .filter(e -> isTipo(e, tipo))
                .map(e -> textOrBlank(e.getTempoCronometro()))
                .filter(s -> !s.isBlank())
                .findFirst()
                .orElse("");
    }

    private List<GoalEntry> buildGoals(List<EventoPartida> eventos, UUID equipeId, Map<UUID, Integer> numeroPorAtleta, int tempoPeriodo) {
        if (equipeId == null) return List.of();
        return eventos.stream()
                .filter(e -> isTipo(e, "GOL"))
                .filter(e -> e.getEquipe() != null && Objects.equals(e.getEquipe().getId(), equipeId))
                .map(e -> new GoalEntry(
                        textOrBlank(Optional.ofNullable(e.getAtleta()).map(a -> numeroPorAtleta.get(a.getId())).map(String::valueOf).orElse("")),
                        textOrBlank(e.getTempoCronometro()),
                        resolvePeriod(e.getTempoCronometro(), tempoPeriodo)
                ))
                .limit(27)
                .toList();
    }

    private List<String> buildArbitrationLines(List<PartidaArbitro> arbitros) {
        String arbitro1 = lineForRole(arbitros, "principal", "Árbitro");
        String arbitro2 = lineForRole(arbitros, "aux", "Árbitro");
        String anotador1 = lineForRole(arbitros, "cronomet", "Anotador Cronometrista");
        String anotador2 = lineForRole(arbitros, "anot", "Anotador Cronometrista");
        String representante1 = lineForRole(arbitros, "represent", "Representante");
        String representante2 = lineForRole(arbitros, "deleg", "Representante");
        return List.of(arbitro1, arbitro2, anotador1, anotador2, representante1, representante2);
    }

    private String lineForRole(List<PartidaArbitro> arbitros, String fragment, String label) {
        return arbitros.stream()
                .filter(a -> normalize(a.getFuncao()).contains(fragment))
                .findFirst()
                .map(a -> label + " - " + safeText(a.getArbitro() == null ? null : a.getArbitro().getNomeExibicao()))
                .orElse(label + " - Não informado");
    }

    private PeriodSummary buildPeriodSummary(Partida partida, List<EventoPartida> eventos, UUID equipeAId, UUID equipeBId, int tempoPeriodo) {
        int golsA1 = countGoalsForPeriod(eventos, equipeAId, 1, tempoPeriodo);
        int golsB1 = countGoalsForPeriod(eventos, equipeBId, 1, tempoPeriodo);
        int golsA2 = countGoalsForPeriod(eventos, equipeAId, 2, tempoPeriodo);
        int golsB2 = countGoalsForPeriod(eventos, equipeBId, 2, tempoPeriodo);
        int golsAE = countGoalsForPeriod(eventos, equipeAId, 3, tempoPeriodo);
        int golsBE = countGoalsForPeriod(eventos, equipeBId, 3, tempoPeriodo);

        OffsetDateTime fim1 = firstCreatedAtOfTipo(eventos, "FIM_1_TEMPO");
        OffsetDateTime inicio2 = firstCreatedAtOfTipo(eventos, "INICIO_2_TEMPO");

        return new PeriodSummary(
                Optional.ofNullable(partida.getAgendadoPara()).map(TIME_FMT::format).orElse(""),
                Optional.ofNullable(partida.getIniciadaEm()).map(TIME_FMT::format).orElse(""),
                Optional.ofNullable(fim1).map(TIME_FMT::format).orElse(""),
                Optional.ofNullable(inicio2).map(TIME_FMT::format).orElse(""),
                Optional.ofNullable(partida.getEncerradaEm()).map(TIME_FMT::format).orElse(""),
                golsA1, golsB1, golsA2, golsB2,
                Optional.ofNullable(partida.getPlacarA()).orElse(golsA1 + golsA2 + golsAE),
                Optional.ofNullable(partida.getPlacarB()).orElse(golsB1 + golsB2 + golsBE),
                golsAE, golsBE
        );
    }

    private OffsetDateTime firstCreatedAtOfTipo(List<EventoPartida> eventos, String tipo) {
        return eventos.stream()
                .filter(e -> isTipo(e, tipo))
                .map(EventoPartida::getCriadoEm)
                .filter(Objects::nonNull)
                .findFirst()
                .orElse(null);
    }

    private int countGoalsForPeriod(List<EventoPartida> eventos, UUID equipeId, int period, int tempoPeriodo) {
        if (equipeId == null) return 0;
        return (int) eventos.stream()
                .filter(e -> isTipo(e, "GOL"))
                .filter(e -> e.getEquipe() != null && Objects.equals(e.getEquipe().getId(), equipeId))
                .filter(e -> resolvePeriod(e.getTempoCronometro(), tempoPeriodo) == period)
                .count();
    }

    private int resolvePeriod(String tempoCronometro, int tempoPeriodo) {
        int seconds = parseTempoSeconds(tempoCronometro);
        if (seconds <= 0) return 1;
        if (seconds <= tempoPeriodo * 60) return 1;
        if (seconds <= tempoPeriodo * 2 * 60) return 2;
        return 3;
    }

    private int parseTempoSeconds(String tempoCronometro) {
        if (tempoCronometro == null || !tempoCronometro.contains(":")) return 0;
        try {
            String[] parts = tempoCronometro.trim().split(":");
            return Integer.parseInt(parts[0]) * 60 + Integer.parseInt(parts[1]);
        } catch (RuntimeException ex) {
            return 0;
        }
    }

    private boolean isTipo(EventoPartida e, String tipo) {
        return e.getTipoEvento() != null && tipo.equalsIgnoreCase(e.getTipoEvento().getNome());
    }

    private void drawHeader(PDPageContentStream cs, PDRectangle box, SumulaData data, PDDocument document) throws IOException {
        fittedText(cs, FONT_BOLD, 8.2f, 255f, 736f, 180f, data.headerMatchup());
        fittedText(cs, FONT, 7.2f, 381f, 717f, 190f, data.headerSchedule());

        float logoWidth = 34.0f;
        float logoHeight = 42.6f;
        float logoY = 776.0f;
        
        drawImageFromUrl(document, cs, data.escudoA(), 213.0f, logoY, logoWidth, logoHeight);
        drawImageFromUrl(document, cs, data.escudoB(), 401.6f, logoY, logoWidth, logoHeight);
    }

    private void drawImageFromUrl(PDDocument document, PDPageContentStream cs, String urlStr, float x, float y, float w, float h) {
        if (urlStr == null || urlStr.isBlank()) return;
        try (InputStream in = java.net.URI.create(urlStr).toURL().openStream()) {
            org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject image = org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject.createFromByteArray(document, in.readAllBytes(), "logo");
            cs.drawImage(image, x, y, w, h);
        } catch (Exception e) {
            // Log or ignore image download failure
        }
    }

    private void drawTeam(PDPageContentStream cs, TeamPdfData team, float[] rowYs, float[] staffYs, float goalStartY) throws IOException {
        for (int i = 0; i < rowYs.length && i < team.rows().size(); i++) {
            RosterRow row = team.rows().get(i);
            float y = rowYs[i];
            fittedText(cs, FONT, 6.2f, X_REG, y, 28f, row.inscricao());
            fittedText(cs, FONT, 6.4f, X_NAME, y, 118f, row.nome());
            centeredText(cs, FONT, 6.5f, X_NUM, y, 18f, row.numero());
            centeredText(cs, FONT, 6.1f, X_YELLOW, y, 27f, row.amarelo());
            centeredText(cs, FONT, 6.1f, X_RED, y, 27f, row.vermelho());
        }

        text(cs, FONT, 6.5f, 314f, rowYs[0] + 26f, team.capitao());

        for (int i = 0; i < staffYs.length && i < team.staffLines().size(); i++) {
            fittedText(cs, FONT, 6.7f, 40f, staffYs[i], 190f, team.staffLines().get(i));
        }

        drawGoals(cs, team.goals(), goalStartY);
    }

    private void drawGoals(PDPageContentStream cs, List<GoalEntry> goals, float startY) throws IOException {
        for (int i = 0; i < goals.size() && i < 27; i++) {
            GoalEntry goal = goals.get(i);
            int row = i / 3;
            int col = i % 3;
            float y = startY + (row * GOAL_ROW_STEP);
            centeredText(cs, FONT_BOLD, 7f, GOAL_COL_X[col], y, 22f, goal.numeroJogador());
            centeredText(cs, FONT_BOLD, 6.6f, GOAL_TIME_X[col], y + GOAL_TIME_OFFSET, 26f, goal.tempo());
        }
    }

    private void drawIdentification(PDPageContentStream cs, SumulaData data) throws IOException {
        fittedText(cs, FONT_BOLD, 7f, 58f, 120f, 185f, data.competicao());
        fittedText(cs, FONT_BOLD, 7f, 268f, 120f, 180f, data.categoria());
        fittedText(cs, FONT_BOLD, 7f, 46f, 106f, 90f, data.numeroJogo());
        fittedText(cs, FONT_BOLD, 7f, 212f, 106f, 80f, data.grupo());
        fittedText(cs, FONT_BOLD, 7f, 319f, 106f, 150f, data.fase());
        fittedText(cs, FONT_BOLD, 7f, 494f, 106f, 70f, data.data());
        fittedText(cs, FONT_BOLD, 7f, 45f, 93f, 96f, data.ginasio());
        fittedText(cs, FONT_BOLD, 7f, 152f, 93f, 110f, data.cidade());
    }

    private void drawArbitration(PDPageContentStream cs, List<String> lines) throws IOException {
        float[] ys = {78f, 64f, 53f, 43f, 31f, 18f};
        for (int i = 0; i < ys.length && i < lines.size(); i++) {
            fittedText(cs, FONT_BOLD, 7f, 8f, ys[i], 540f, lines.get(i));
        }
    }

    private void drawPeriodSummary(PDPageContentStream cs, PeriodSummary summary) throws IOException {
        text(cs, FONT_BOLD, 7f, 505f, 648f, summary.scheduled1());
        text(cs, FONT_BOLD, 7f, 545f, 648f, summary.start1());
        text(cs, FONT_BOLD, 7f, 574f, 648f, summary.end1());
        text(cs, FONT_BOLD, 7f, 545f, 626f, summary.start2());
        text(cs, FONT_BOLD, 7f, 574f, 626f, summary.end2());

        centeredText(cs, FONT_BOLD, 7f, 489f, 566f, 14f, String.valueOf(summary.goalsA1()));
        centeredText(cs, FONT_BOLD, 7f, 517f, 566f, 14f, "X");
        centeredText(cs, FONT_BOLD, 7f, 545f, 566f, 14f, String.valueOf(summary.goalsB1()));

        centeredText(cs, FONT_BOLD, 7f, 489f, 542f, 14f, String.valueOf(summary.goalsA2()));
        centeredText(cs, FONT_BOLD, 7f, 517f, 542f, 14f, "X");
        centeredText(cs, FONT_BOLD, 7f, 545f, 542f, 14f, String.valueOf(summary.goalsB2()));

        centeredText(cs, FONT_BOLD, 7f, 489f, 518f, 14f, String.valueOf(summary.goalsAFinal()));
        centeredText(cs, FONT_BOLD, 7f, 517f, 518f, 14f, "X");
        centeredText(cs, FONT_BOLD, 7f, 545f, 518f, 14f, String.valueOf(summary.goalsBFinal()));

        centeredText(cs, FONT_BOLD, 7f, 489f, 494f, 14f, String.valueOf(summary.goalsAExtra()));
        centeredText(cs, FONT_BOLD, 7f, 517f, 494f, 14f, "X");
        centeredText(cs, FONT_BOLD, 7f, 545f, 494f, 14f, String.valueOf(summary.goalsBExtra()));
    }

    private void text(PDPageContentStream cs, PDFont font, float fontSize, float x, float y, String value) throws IOException {
        if (value == null || value.isBlank()) return;
        cs.beginText();
        cs.setFont(font, fontSize);
        cs.newLineAtOffset(x, y);
        cs.showText(sanitize(value));
        cs.endText();
    }

    private void fittedText(PDPageContentStream cs, PDFont font, float fontSize, float x, float y, float maxWidth, String value) throws IOException {
        if (value == null || value.isBlank()) return;
        String sanitized = sanitize(value);
        float size = fontSize;
        while (size > 5f && textWidth(font, size, sanitized) > maxWidth) {
            size -= 0.2f;
        }
        text(cs, font, size, x, y, sanitized);
    }

    private void centeredText(PDPageContentStream cs, PDFont font, float fontSize, float x, float y, float width, String value) throws IOException {
        if (value == null || value.isBlank()) return;
        String sanitized = sanitize(value);
        float textWidth = textWidth(font, fontSize, sanitized);
        float offsetX = x + Math.max(0f, (width - textWidth) / 2f);
        text(cs, font, fontSize, offsetX, y, sanitized);
    }

    private float textWidth(PDFont font, float size, String value) throws IOException {
        return font.getStringWidth(value) / 1000f * size;
    }

    private String sanitize(String value) {
        return value.replace('\u0000', ' ')
                .replace('\n', ' ')
                .replace('\r', ' ')
                .replaceAll("\\s+", " ")
                .trim();
    }

    private String[] splitLocal(String local) {
        if (local == null || local.isBlank()) return new String[]{"Não informado", "Não informado"};
        String[] separators = {"/", " - ", " — ", ","};
        for (String sep : separators) {
            if (local.contains(sep)) {
                String[] parts = local.split(java.util.regex.Pattern.quote(sep), 2);
                return new String[]{safeText(parts[0]), safeText(parts[1])};
            }
        }
        return new String[]{safeText(local), "Não informado"};
    }

    private String safeText(String value) {
        return value == null || value.isBlank() ? "Não informado" : sanitize(value);
    }

    private String textOrBlank(String value) {
        return value == null ? "" : sanitize(value);
    }

    private String normalize(String value) {
        return value == null ? "" : value.toLowerCase(Locale.ROOT)
                .replace("ã", "a")
                .replace("á", "a")
                .replace("â", "a")
                .replace("é", "e")
                .replace("ê", "e")
                .replace("í", "i")
                .replace("ó", "o")
                .replace("ô", "o")
                .replace("õ", "o")
                .replace("ú", "u")
                .replace("ç", "c");
    }

    private record SumulaData(
            TeamPdfData teamA,
            TeamPdfData teamB,
            String competicao,
            String categoria,
            String numeroJogo,
            String grupo,
            String fase,
            String data,
            String ginasio,
            String cidade,
            List<String> arbitrationLines,
            PeriodSummary periodSummary,
            String headerSchedule,
            String headerMatchup,
            String escudoA,
            String escudoB
    ) {}

    private record TeamPdfData(
            String nome,
            List<RosterRow> rows,
            List<GoalEntry> goals,
            String capitao,
            List<String> staffLines
    ) {}

    private record RosterRow(String inscricao, String nome, String numero, String amarelo, String vermelho) {}

    private record GoalEntry(String numeroJogador, String tempo, int period) {}

    private record PeriodSummary(
            String scheduled1,
            String start1,
            String end1,
            String start2,
            String end2,
            int goalsA1,
            int goalsB1,
            int goalsA2,
            int goalsB2,
            int goalsAFinal,
            int goalsBFinal,
            int goalsAExtra,
            int goalsBExtra
    ) {}
}
