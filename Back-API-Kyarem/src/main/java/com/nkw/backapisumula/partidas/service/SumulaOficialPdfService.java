package com.nkw.backapisumula.partidas.service;

import com.nkw.backapisumula.competicao.EquipeAtletaInscrito;
import com.nkw.backapisumula.competicao.repo.EquipeAtletaInscritoRepository;
import com.nkw.backapisumula.partidas.EventoPartida;
import com.nkw.backapisumula.partidas.Partida;
import com.nkw.backapisumula.partidas.PartidaArbitro;
import com.nkw.backapisumula.partidas.repo.EventoPartidaRepository;
import com.nkw.backapisumula.partidas.repo.PartidaArbitroRepository;
import com.nkw.backapisumula.partidas.repo.PartidaRepository;
import com.openhtmltopdf.pdfboxout.PdfRendererBuilder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayOutputStream;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class SumulaOficialPdfService {

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");
    private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("HH:mm");
    private static final int MAX_PLAYERS = 13;
    private static final int MAX_GOALS = 27;

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

    // ─── PUBLIC API ─────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public byte[] gerarPdf(UUID partidaId) {
        Partida partida = partidaRepo.findById(partidaId)
                .orElseThrow(() -> new IllegalStateException("Partida não encontrada."));
        List<EventoPartida> eventos = eventoRepo.findByPartidaIdWithDetails(partidaId);
        List<PartidaArbitro> arbitros = partidaArbitroRepo.findByPartidaIdWithArbitro(partidaId);
        List<EquipeAtletaInscrito> inscritosA = partida.getEquipeA() == null ? List.of()
                : inscritosRepo.findByEquipe_Id(partida.getEquipeA().getId());
        List<EquipeAtletaInscrito> inscritosB = partida.getEquipeB() == null ? List.of()
                : inscritosRepo.findByEquipe_Id(partida.getEquipeB().getId());

        SumulaData data = buildData(partida, inscritosA, inscritosB, arbitros, eventos);
        return renderHtmlToPdf(buildHtml(data));
    }

    // ─── DATA BUILDING ──────────────────────────────────────────────────────────

    private SumulaData buildData(
            Partida partida,
            List<EquipeAtletaInscrito> inscritosA,
            List<EquipeAtletaInscrito> inscritosB,
            List<PartidaArbitro> arbitros,
            List<EventoPartida> eventos
    ) {
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

        TeamPdfData teamA = new TeamPdfData(
                safeText(Optional.ofNullable(partida.getEquipeA()).map(e -> e.getNomeEquipe()).orElse(null)),
                rowsA, goalsA, "",
                List.of("Treinador -", "Prep. Físico -", "Asst. Técnico -", "Fisio -")
        );
        TeamPdfData teamB = new TeamPdfData(
                safeText(Optional.ofNullable(partida.getEquipeB()).map(e -> e.getNomeEquipe()).orElse(null)),
                rowsB, goalsB, "",
                List.of("Treinador -", "Prep. Físico -", "Asst. Técnico -", "Fisio -")
        );

        // Resolve campeonato from equipe or modalidade
        var campeonatoOpt = Optional.ofNullable(partida.getEquipeA())
                .map(eq -> eq.getCampeonato())
                .or(() -> Optional.ofNullable(partida.getEquipeB()).map(eq -> eq.getCampeonato()));
        String competicao = safeText(campeonatoOpt.map(c -> c.getNome())
                .orElse(Optional.ofNullable(partida.getModalidade())
                        .map(m -> m.getCampeonatoNome()).orElse(null)));
        String escudoCompeticao = campeonatoOpt.map(c -> c.getEscudoUrl()).orElse(null);

        String categoria = safeText(Optional.ofNullable(partida.getModalidade())
                .map(m -> m.getNome()).orElse(null));
        String dataStr = Optional.ofNullable(partida.getAgendadoPara())
                .map(DATE_FMT::format).orElse("");
        String numeroJogo = textOrBlank(partida.getId() != null
                ? partida.getId().toString().substring(0, 8).toUpperCase(Locale.ROOT) : null);
        String fase = safeText(Optional.ofNullable(partida.getStatus())
                .map(Object::toString).orElse(null));
        String[] localParts = splitLocal(partida.getLocal());

        String escudoA = partida.getEquipeA() != null && partida.getEquipeA().getAtletica() != null
                ? partida.getEquipeA().getAtletica().getEscudoUrl() : null;
        String escudoB = partida.getEquipeB() != null && partida.getEquipeB().getAtletica() != null
                ? partida.getEquipeB().getAtletica().getEscudoUrl() : null;

        PeriodSummary ps = buildPeriodSummary(partida, eventos, equipeAId, equipeBId, tempoPeriodo);
        String headerSchedule = safeText(Optional.ofNullable(partida.getAgendadoPara())
                .map(ts -> DATE_FMT.format(ts) + " - " + TIME_FMT.format(ts)).orElse(null));

        return new SumulaData(teamA, teamB, competicao, categoria, numeroJogo, "", fase, dataStr,
                localParts[0], localParts[1], buildArbitrationLines(arbitros), ps,
                headerSchedule, safeText(teamA.nome() + " x " + teamB.nome()),
                escudoA, escudoB, escudoCompeticao);
    }

    private void putIfPresent(Map<UUID, Integer> map, EquipeAtletaInscrito i) {
        if (i.getAtleta() != null && i.getAtleta().getId() != null && i.getNumeroCamisa() != null)
            map.put(i.getAtleta().getId(), i.getNumeroCamisa());
    }

    private RosterRow rosterRow(EquipeAtletaInscrito inscrito, List<EventoPartida> ev) {
        return new RosterRow(
                textOrBlank(Optional.ofNullable(inscrito.getNumeroCamisa()).map(String::valueOf).orElse(null)),
                safeText(Optional.ofNullable(inscrito.getAtleta()).map(a -> a.getNome()).orElse(null)),
                firstTempoOfTipo(ev, "CARTAO_AMARELO"),
                firstTempoOfTipo(ev, "CARTAO_VERMELHO")
        );
    }

    private String firstTempoOfTipo(List<EventoPartida> eventos, String tipo) {
        if (eventos == null) return "";
        return eventos.stream().filter(e -> isTipo(e, tipo))
                .map(e -> textOrBlank(e.getTempoCronometro()))
                .filter(s -> !s.isBlank()).findFirst().orElse("");
    }

    private List<GoalEntry> buildGoals(List<EventoPartida> eventos, UUID equipeId,
                                       Map<UUID, Integer> numMap, int tempoPeriodo) {
        if (equipeId == null) return List.of();
        return eventos.stream()
                .filter(e -> isTipo(e, "GOL"))
                .filter(e -> e.getEquipe() != null && Objects.equals(e.getEquipe().getId(), equipeId))
                .map(e -> new GoalEntry(
                        textOrBlank(Optional.ofNullable(e.getAtleta())
                                .map(a -> numMap.get(a.getId())).map(String::valueOf).orElse("")),
                        textOrBlank(e.getTempoCronometro()),
                        resolvePeriod(e.getTempoCronometro(), tempoPeriodo)
                ))
                .limit(MAX_GOALS).toList();
    }

    private List<String> buildArbitrationLines(List<PartidaArbitro> arbitros) {
        return List.of(
                lineForRole(arbitros, "principal", "Árbitro"),
                lineForRole(arbitros, "aux", "Árbitro"),
                lineForRole(arbitros, "cronomet", "Anotador Cronometrista"),
                lineForRole(arbitros, "anot", "Anotador Cronometrista"),
                lineForRole(arbitros, "represent", "Representante"),
                lineForRole(arbitros, "deleg", "Representante")
        );
    }

    private String lineForRole(List<PartidaArbitro> arbitros, String fragment, String label) {
        return arbitros.stream()
                .filter(a -> normalize(a.getFuncao()).contains(fragment)).findFirst()
                .map(a -> label + " - " + safeText(
                        a.getArbitro() == null ? null : a.getArbitro().getNomeExibicao()))
                .orElse(label + " -");
    }

    private PeriodSummary buildPeriodSummary(Partida partida, List<EventoPartida> eventos,
                                             UUID equipeAId, UUID equipeBId, int tempoPeriodo) {
        OffsetDateTime fim1 = firstCreatedAtOfTipo(eventos, "FIM_1_TEMPO");
        OffsetDateTime inicio2 = firstCreatedAtOfTipo(eventos, "INICIO_2_TEMPO");
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
                golsAE, golsBE
        );
    }

    private OffsetDateTime firstCreatedAtOfTipo(List<EventoPartida> eventos, String tipo) {
        return eventos.stream().filter(e -> isTipo(e, tipo))
                .map(EventoPartida::getCriadoEm).filter(Objects::nonNull).findFirst().orElse(null);
    }

    private int countGoals(List<EventoPartida> eventos, UUID equipeId, int period, int tempoPeriodo) {
        if (equipeId == null) return 0;
        return (int) eventos.stream()
                .filter(e -> isTipo(e, "GOL"))
                .filter(e -> e.getEquipe() != null && Objects.equals(e.getEquipe().getId(), equipeId))
                .filter(e -> resolvePeriod(e.getTempoCronometro(), tempoPeriodo) == period)
                .count();
    }

    private int resolvePeriod(String tempo, int tempoPeriodo) {
        int s = parseSeconds(tempo);
        if (s <= 0 || s <= tempoPeriodo * 60) return 1;
        if (s <= tempoPeriodo * 2 * 60) return 2;
        return 3;
    }

    private int parseSeconds(String tempo) {
        if (tempo == null || !tempo.contains(":")) return 0;
        try {
            String[] p = tempo.trim().split(":");
            return Integer.parseInt(p[0]) * 60 + Integer.parseInt(p[1]);
        } catch (RuntimeException e) {
            return 0;
        }
    }

    private boolean isTipo(EventoPartida e, String tipo) {
        return e.getTipoEvento() != null && tipo.equalsIgnoreCase(e.getTipoEvento().getNome());
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
        return "<table class=\"hdr\" cellpadding=\"0\" cellspacing=\"0\">\n<tr>\n"
                + "<td class=\"hdr-left\">"
                + imgTag(data.escudoCompeticao())
                + "<div class=\"hdr-name\">" + e(data.competicao()) + "</div>"
                + "</td>\n"
                + "<td class=\"hdr-center\">"
                + "<table cellpadding=\"0\" cellspacing=\"0\" style=\"width:100%;\">\n<tr>\n"
                + "<td style=\"width:80px; text-align:center; vertical-align:middle; padding:5px;\">"
                + imgTag(data.escudoA()) + "</td>\n"
                + "<td style=\"text-align:center; vertical-align:middle; font-weight:bold; font-size:13px;\">"
                + e(data.headerMatchup()) + "</td>\n"
                + "<td style=\"width:80px; text-align:center; vertical-align:middle; padding:5px;\">"
                + imgTag(data.escudoB()) + "</td>\n"
                + "</tr>\n</table>"
                + "</td>\n"
                + "</tr>\n</table>\n";
    }

    private String imgTag(String url) {
        if (url == null || url.isBlank()) return "";
        return "<img src=\"" + e(url) + "\" style=\"width:60px; height:auto;\"/>";
    }

    // ── Game info ────────────────────────────────────────────────────────────────

    private String gameInfoHtml(SumulaData data) {
        return "<div class=\"game-info\">"
                + "Horário estimado do jogo: " + e(data.headerSchedule())
                + "</div>\n";
    }

    // ── Team block ───────────────────────────────────────────────────────────────

    private String teamBlockHtml(TeamPdfData team, String letter, PeriodSummary ps, boolean showGeral) {
        int colspan = showGeral ? 4 : 3;
        return "<table class=\"team-tbl\" cellpadding=\"0\" cellspacing=\"0\">\n<tr>\n"
                + colPlayersHtml(team, letter)
                + colCardsHtml(team)
                + colMetasHtml(team)
                + (showGeral ? colGeralHtml(ps) : "")
                + "</tr>\n"
                + "<tr><td colspan=\"" + colspan + "\" class=\"obs-row\"></td></tr>\n"
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
        sb.append("<th style=\"width:45px; border-top:none; border-left:none;\">Inscrição</th>");
        sb.append("<th style=\"border-top:none; border-right:none;\">Jogadores</th>");
        sb.append("</tr>\n");
        List<RosterRow> rows = team.rows();
        for (int i = 0; i < MAX_PLAYERS; i++) {
            RosterRow row = i < rows.size() ? rows.get(i) : new RosterRow("", "", "", "");
            sb.append("<tr>");
            sb.append("<td style=\"border-left:none; text-align:center;\">").append(e(row.numero())).append("</td>");
            sb.append("<td style=\"border-right:none; text-align:left; padding-left:4px; font-size:9px;\">")
                    .append(e(row.nome())).append("</td>");
            sb.append("</tr>\n");
        }
        sb.append("</table>\n");
        // Staff
        List<String> staff = team.staffLines();
        String[] lbl = {"Treinador -", "Prep. Físico -", "Asst. Técnico -", "Fisio -"};
        for (int i = 0; i < 4; i++) {
            String line = i < staff.size() ? staff.get(i) : lbl[i];
            String style = i == 3 ? " style=\"border-bottom:none;\"" : "";
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
        for (int i = 0; i < MAX_PLAYERS; i++) {
            RosterRow row = i < rows.size() ? rows.get(i) : new RosterRow("", "", "", "");
            sb.append("<tr>");
            sb.append("<td style=\"border-left:none;\">").append(e(row.numero())).append("</td>");
            sb.append("<td>").append(e(row.amarelo())).append("</td>");
            sb.append("<td>").append(e(row.vermelho())).append("</td>");
            sb.append("<td></td><td></td><td></td><td></td>");
            sb.append("<td style=\"border-right:none;\"></td>");
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
                if (!num.isEmpty()) sb.append("<strong>").append(num).append("</strong>");
                if (!tempo.isEmpty()) sb.append("<br/>").append(tempo);
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

    private String colGeralHtml(PeriodSummary ps) {
        StringBuilder sb = new StringBuilder();
        sb.append("<td class=\"col-geral\">\n");
        sb.append("<table cellpadding=\"0\" cellspacing=\"0\" style=\"width:100%; height:100%; border-collapse:collapse;\">\n<tr>\n");

        // Faltas Acumuladas bar
        sb.append("<td class=\"v-bar\" style=\"width:28px;\">");
        sb.append(vBarLabel("Faltas Acumuladas"));
        sb.append("</td>\n");

        // Faults marking strip
        sb.append("<td style=\"width:18px; border-right:1px solid #000; vertical-align:top;\"></td>\n");

        // Pedidos de Tempo bar
        sb.append("<td class=\"v-bar\" style=\"width:28px;\">");
        sb.append(vBarLabel("Pedidos de Tempo"));
        sb.append("</td>\n");

        // Em Geral content
        sb.append("<td style=\"vertical-align:top;\">\n");
        sb.append("<div class=\"geral-title\">Em Geral</div>\n");

        // Schedule table
        sb.append("<table class=\"itbl\" cellpadding=\"0\" cellspacing=\"0\">\n");
        sb.append("<tr style=\"background:#f5f5f5;\">");
        sb.append("<th style=\"width:55px; border-top:none; border-left:none;\">Agendar</th>");
        sb.append("<th style=\"border-top:none;\">Lar</th>");
        sb.append("<th style=\"border-top:none; border-right:none;\">Termino</th>");
        sb.append("</tr>\n");
        sb.append(scheduleRow("1º Período", ps.start1(), ps.end1()));
        sb.append(scheduleRow("2º Período", ps.start2(), ps.end2()));
        sb.append(scheduleRow("P. Extra", "", ""));
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

        sb.append("</td>\n</tr>\n</table>\n</td>\n");
        return sb.toString();
    }

    private String vBarLabel(String text) {
        StringBuilder sb = new StringBuilder("<div class=\"v-bar-text\">");
        for (int i = 0; i < text.length(); i++) {
            char c = text.charAt(i);
            if (c == ' ') sb.append("<br/>");
            else sb.append(Character.toUpperCase(c));
        }
        sb.append("</div>");
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
        return "<tr style=\"height:28px;\">"
                + "<td style=\"border:none; font-size:9px; width:50px; vertical-align:middle;\">" + e(label) + "</td>"
                + "<td style=\"border:none; width:32px; vertical-align:middle;\">"
                + "<div class=\"placar-box\">" + a + "</div></td>"
                + "<td style=\"border:none; padding:0 2px; vertical-align:middle; text-align:center; width:12px;\">X</td>"
                + "<td style=\"border:none; width:32px; vertical-align:middle;\">"
                + "<div class=\"placar-box\">" + b + "</div></td>"
                + "</tr>\n";
    }

    private String scoreFinalRow(String label, int a, int b) {
        return "<tr style=\"height:28px;\">"
                + "<td style=\"border:none; font-size:9px; font-weight:bold; width:50px; vertical-align:middle;\">" + e(label) + "</td>"
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
        sb.append("<div class=\"fw-row\">").append(e(data.headerMatchup())).append("</div>\n");

        // Composição / Categoria
        sb.append("<table cellpadding=\"0\" cellspacing=\"0\" class=\"ft-row\">\n<tr>\n");
        sb.append("<td class=\"ft-label\">Composição: ").append(e(data.competicao())).append("</td>\n");
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
        for (int i = 0; i < 6; i++) {
            String line = i < arb.size() ? arb.get(i) : "";
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
                @page { size: A4; margin: 4mm; }
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { font-family: Arial, sans-serif; font-size: 11px; }
                .page { border: 3px solid black; }

                /* HEADER */
                .hdr { width: 100%; border-collapse: collapse; border-bottom: 3px solid black; }
                .hdr-left { width: 120px; border-right: 3px solid black; padding: 10px;
                    vertical-align: middle; text-align: center; }
                .hdr-center { padding: 8px; vertical-align: middle; }
                .hdr-name { font-size: 10px; font-weight: bold; text-align: center; line-height: 1.2; }

                /* GAME INFO */
                .game-info { border-bottom: 3px solid black; padding: 8px 10px; text-align: right;
                    font-size: 10px; font-weight: bold; }

                /* TEAM BLOCK */
                .team-tbl { width: 100%; border-collapse: collapse; border-bottom: 3px solid black; }
                .col-players { width: 28%; border-right: 1px solid black; vertical-align: top; }
                .col-cards   { width: 20%; border-right: 1px solid black; vertical-align: top; }
                .col-metas   { width: 28%; border-right: 1px solid black; vertical-align: top; }
                .col-geral   { vertical-align: top; }
                .obs-row { height: 55px; border-top: 1px solid black; padding: 5px;
                    vertical-align: top; font-size: 9px; color: #bbb; }

                /* COLUMN TITLE */
                .col-title { border-bottom: 1px solid black; padding: 5px 6px; font-weight: bold;
                    font-size: 10px; min-height: 28px; }

                /* INNER TABLE (players / cards / schedule) */
                .itbl { width: 100%; border-collapse: collapse; }
                .itbl th { border: 1px solid black; padding: 2px 2px; font-size: 9px;
                    font-weight: bold; text-align: center; background: #f5f5f5; }
                .itbl td { border: 1px solid black; padding: 1px 2px; font-size: 9px;
                    text-align: center; height: 19px; vertical-align: middle; }

                /* STAFF */
                .staff-row { border-top: 1px solid black; border-bottom: 1px solid black;
                    padding: 3px 5px; font-size: 9px; min-height: 19px; }

                /* METAS */
                .metas-label { padding: 3px 6px; font-size: 9px; border-bottom: 1px solid black;
                    background: #fff; }
                .metas-tbl { width: 100%; border-collapse: collapse; }
                .metas-tbl td { border: 1px solid black; height: 44px; width: 33.33%; }
                .meta-idx { width: 20px; border-right: 1px solid black; text-align: center;
                    font-size: 8px; background: #f9f9f9; padding: 2px 1px; vertical-align: middle; }
                .meta-content { text-align: center; font-size: 9px; vertical-align: middle;
                    padding: 2px; }

                /* V-BAR */
                .v-bar { background: #000; vertical-align: top; text-align: center;
                    border-right: 1px solid #555; padding-top: 4px; }
                .v-bar-text { color: #fff; font-size: 7px; font-weight: bold;
                    line-height: 1.15; text-align: center; letter-spacing: 0; }

                /* GERAL */
                .geral-title { background: #f5f5f5; border-bottom: 1px solid black;
                    padding: 4px; font-weight: bold; font-size: 9px; text-align: center; }
                .contagens-title { padding: 4px 6px; font-size: 9px; font-weight: bold;
                    border-top: 1px solid black; }
                .placar-box { border: 1px solid black; width: 28px; height: 24px;
                    display: inline-block; text-align: center; font-weight: bold;
                    font-size: 12px; line-height: 24px; vertical-align: middle; }
                .placar-final { background: #fffacd; }

                /* FOOTER */
                .footer { padding: 6px 8px; }
                .fw-row { border: 1px solid black; margin-bottom: 2px; padding: 4px 8px;
                    text-align: center; background: #f5f5f5; font-weight: bold; font-size: 10px;
                    min-height: 22px; }
                .ft-row { width: 100%; border-collapse: collapse; margin-bottom: 2px; }
                .ft-label { border: 1px solid black; padding: 4px 5px; font-weight: bold;
                    font-size: 9px; width: 55%; vertical-align: middle; }
                .ft-value { border: 1px solid black; padding: 4px 5px; font-size: 9px;
                    vertical-align: middle; }
                .ft-quarter { border: 1px solid black; padding: 4px 5px; font-size: 9px;
                    width: 25%; vertical-align: middle; }
                .ft-arb { border: 1px solid black; padding: 4px 5px; font-weight: bold;
                    font-size: 9px; width: 65%; vertical-align: middle; min-height: 22px; }
                .ft-sig { border: 1px solid black; font-size: 9px; vertical-align: middle; }
                """;
    }

    // ─── UTILITY ────────────────────────────────────────────────────────────────

    private static String e(String value) {
        if (value == null) return "";
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
        if (local == null || local.isBlank()) return new String[]{"", ""};
        for (String sep : new String[]{"/", " - ", " — ", ","}) {
            if (local.contains(sep)) {
                String[] p = local.split(java.util.regex.Pattern.quote(sep), 2);
                return new String[]{safeText(p[0]), safeText(p[1])};
            }
        }
        return new String[]{safeText(local), ""};
    }

    private String normalize(String value) {
        if (value == null) return "";
        return value.toLowerCase(Locale.ROOT)
                .replace("ã", "a").replace("á", "a").replace("â", "a")
                .replace("é", "e").replace("ê", "e").replace("í", "i")
                .replace("ó", "o").replace("ô", "o").replace("õ", "o")
                .replace("ú", "u").replace("ç", "c");
    }

    // ─── RECORDS ────────────────────────────────────────────────────────────────

    private record SumulaData(
            TeamPdfData teamA, TeamPdfData teamB,
            String competicao, String categoria, String numeroJogo, String grupo,
            String fase, String data, String ginasio, String cidade,
            List<String> arbitrationLines, PeriodSummary periodSummary,
            String headerSchedule, String headerMatchup,
            String escudoA, String escudoB, String escudoCompeticao
    ) {}

    private record TeamPdfData(
            String nome, List<RosterRow> rows, List<GoalEntry> goals,
            String capitao, List<String> staffLines
    ) {}

    private record RosterRow(String numero, String nome, String amarelo, String vermelho) {}

    private record GoalEntry(String numeroJogador, String tempo, int period) {}

    private record PeriodSummary(
            String scheduled1, String start1, String end1, String start2, String end2,
            int goalsA1, int goalsB1, int goalsA2, int goalsB2,
            int goalsAFinal, int goalsBFinal, int goalsAExtra, int goalsBExtra
    ) {}
}
