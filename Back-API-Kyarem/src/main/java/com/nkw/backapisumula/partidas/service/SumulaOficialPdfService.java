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

        String competicao = safeText(Optional.ofNullable(partida.getEquipeA())
                .map(e -> e.getCampeonato())
                .map(c -> c.getNome())
                .orElse(Optional.ofNullable(partida.getModalidade()).map(m -> m.getCampeonatoNome()).orElse(null)));
        String categoria = safeText(Optional.ofNullable(partida.getModalidade()).map(m -> m.getNome()).orElse(null));
        String dataStr = Optional.ofNullable(partida.getAgendadoPara()).map(DATE_FMT::format).orElse("");
        String numeroJogo = textOrBlank(partida.getId() != null
                ? partida.getId().toString().substring(0, 8).toUpperCase(Locale.ROOT) : null);
        String fase = safeText(Optional.ofNullable(partida.getStatus()).map(Object::toString).orElse(null));
        String[] localParts = splitLocal(partida.getLocal());

        String escudoA = partida.getEquipeA() != null && partida.getEquipeA().getAtletica() != null
                ? partida.getEquipeA().getAtletica().getEscudoUrl() : null;
        String escudoB = partida.getEquipeB() != null && partida.getEquipeB().getAtletica() != null
                ? partida.getEquipeB().getAtletica().getEscudoUrl() : null;

        return new SumulaData(
                teamA, teamB, competicao, categoria, numeroJogo, "", fase, dataStr,
                localParts[0], localParts[1],
                buildArbitrationLines(arbitros),
                buildPeriodSummary(partida, eventos, equipeAId, equipeBId, tempoPeriodo),
                safeText(Optional.ofNullable(partida.getAgendadoPara())
                        .map(ts -> DATE_FMT.format(ts) + " - " + TIME_FMT.format(ts)).orElse(null)),
                safeText(teamA.nome() + " x " + teamB.nome()),
                escudoA, escudoB
        );
    }

    private void putIfPresent(Map<UUID, Integer> map, EquipeAtletaInscrito i) {
        if (i.getAtleta() != null && i.getAtleta().getId() != null && i.getNumeroCamisa() != null) {
            map.put(i.getAtleta().getId(), i.getNumeroCamisa());
        }
    }

    private RosterRow rosterRow(EquipeAtletaInscrito inscrito, List<EventoPartida> eventosJogador) {
        return new RosterRow(
                textOrBlank(Optional.ofNullable(inscrito.getNumeroCamisa()).map(String::valueOf).orElse(null)),
                safeText(Optional.ofNullable(inscrito.getAtleta()).map(a -> a.getNome()).orElse(null)),
                firstTempoOfTipo(eventosJogador, "CARTAO_AMARELO"),
                firstTempoOfTipo(eventosJogador, "CARTAO_VERMELHO")
        );
    }

    private String firstTempoOfTipo(List<EventoPartida> eventos, String tipo) {
        if (eventos == null) return "";
        return eventos.stream()
                .filter(e -> isTipo(e, tipo))
                .map(e -> textOrBlank(e.getTempoCronometro()))
                .filter(s -> !s.isBlank())
                .findFirst().orElse("");
    }

    private List<GoalEntry> buildGoals(List<EventoPartida> eventos, UUID equipeId,
                                       Map<UUID, Integer> numeroPorAtleta, int tempoPeriodo) {
        if (equipeId == null) return List.of();
        return eventos.stream()
                .filter(e -> isTipo(e, "GOL"))
                .filter(e -> e.getEquipe() != null && Objects.equals(e.getEquipe().getId(), equipeId))
                .map(e -> new GoalEntry(
                        textOrBlank(Optional.ofNullable(e.getAtleta())
                                .map(a -> numeroPorAtleta.get(a.getId())).map(String::valueOf).orElse("")),
                        textOrBlank(e.getTempoCronometro()),
                        resolvePeriod(e.getTempoCronometro(), tempoPeriodo)
                ))
                .limit(MAX_GOALS)
                .toList();
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
                .filter(a -> normalize(a.getFuncao()).contains(fragment))
                .findFirst()
                .map(a -> label + " - " + safeText(a.getArbitro() == null ? null : a.getArbitro().getNomeExibicao()))
                .orElse(label + " -");
    }

    private PeriodSummary buildPeriodSummary(Partida partida, List<EventoPartida> eventos,
                                             UUID equipeAId, UUID equipeBId, int tempoPeriodo) {
        OffsetDateTime fim1 = firstCreatedAtOfTipo(eventos, "FIM_1_TEMPO");
        OffsetDateTime inicio2 = firstCreatedAtOfTipo(eventos, "INICIO_2_TEMPO");
        int golsA1 = countGoalsForPeriod(eventos, equipeAId, 1, tempoPeriodo);
        int golsB1 = countGoalsForPeriod(eventos, equipeBId, 1, tempoPeriodo);
        int golsA2 = countGoalsForPeriod(eventos, equipeAId, 2, tempoPeriodo);
        int golsB2 = countGoalsForPeriod(eventos, equipeBId, 2, tempoPeriodo);
        int golsAE = countGoalsForPeriod(eventos, equipeAId, 3, tempoPeriodo);
        int golsBE = countGoalsForPeriod(eventos, equipeBId, 3, tempoPeriodo);
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
                .findFirst().orElse(null);
    }

    private int countGoalsForPeriod(List<EventoPartida> eventos, UUID equipeId, int period, int tempoPeriodo) {
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

    // ─── HTML GENERATION ────────────────────────────────────────────────────────

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

    private String buildHtml(SumulaData data) {
        return "<!DOCTYPE html>\n<html lang=\"pt-BR\">\n<head>\n"
                + "<meta charset=\"UTF-8\"/>\n"
                + "<style>\n" + css() + "\n</style>\n"
                + "</head>\n<body>\n<div class=\"container\">\n"
                + headerHtml(data)
                + "<div class=\"game-info\">" + e(data.headerSchedule()) + "</div>\n"
                + teamHtml(data.teamA(), "A", data)
                + teamHtml(data.teamB(), "B", data)
                + footerHtml(data)
                + "</div>\n</body>\n</html>";
    }

    private String headerHtml(SumulaData data) {
        return "<div class=\"header\">\n"
                + "  <div class=\"header-left\">\n"
                + "    <div class=\"header-left-text\">" + e(data.competicao()) + "</div>\n"
                + "  </div>\n"
                + "  <div class=\"header-center\">\n"
                + "    <div class=\"header-score-group\">\n"
                + "      <div class=\"header-logo\">"
                + logoImg(data.escudoA(), "Logo A")
                + "</div>\n"
                + "    </div>\n"
                + "    <div class=\"header-score-text\">" + e(data.headerMatchup()) + "</div>\n"
                + "    <div class=\"header-score-group\">\n"
                + "      <div class=\"header-logo\">"
                + logoImg(data.escudoB(), "Logo B")
                + "</div>\n"
                + "    </div>\n"
                + "  </div>\n"
                + "</div>\n";
    }

    private String logoImg(String url, String alt) {
        if (url == null || url.isBlank()) return "";
        return "<img src=\"" + e(url) + "\" alt=\"" + alt + "\" />";
    }

    private String teamHtml(TeamPdfData team, String letter, SumulaData data) {
        PeriodSummary ps = data.periodSummary();
        List<RosterRow> rows = team.rows();

        StringBuilder sb = new StringBuilder();
        sb.append("<div class=\"f4-body\">\n");
        sb.append("  <div class=\"f4-team\">\n");

        // ── Col 1: Jogadores + Staff ──────────────────────────────────────────
        sb.append("    <div class=\"f4-col\" style=\"width:28%; flex-shrink:0;\">\n");
        sb.append("      <div class=\"f4-section-title\">")
          .append("Saída da Equipe &quot;").append(letter).append("&quot; ( X ) ").append(e(team.nome()))
          .append("</div>\n");
        sb.append("      <table class=\"f4-table\" style=\"border:none;\">\n");
        sb.append("        <thead><tr>");
        sb.append("<th style=\"width:55px; border-left:none; border-top:none;\">Inscrição</th>");
        sb.append("<th style=\"border-right:none; border-top:none;\">Jogadores</th>");
        sb.append("</tr></thead>\n        <tbody>\n");
        for (int i = 0; i < MAX_PLAYERS; i++) {
            RosterRow row = i < rows.size() ? rows.get(i) : new RosterRow("", "", "", "");
            sb.append("          <tr>");
            sb.append("<td style=\"border-left:none;\">").append(e(row.numero())).append("</td>");
            sb.append("<td class=\"f4-player-name\" style=\"border-right:none;\">").append(e(row.nome())).append("</td>");
            sb.append("</tr>\n");
        }
        sb.append("        </tbody>\n      </table>\n");
        List<String> staff = team.staffLines();
        String[] staffLabels = {"Treinador -", "Prep. Físico -", "Asst. Técnico -", "Fisio -"};
        for (int i = 0; i < 4; i++) {
            String line = i < staff.size() ? staff.get(i) : staffLabels[i];
            sb.append("      <div class=\"f4-staff-row\"").append(i == 3 ? " style=\"border-bottom:none;\"" : "").append(">");
            sb.append(e(line)).append("</div>\n");
        }
        sb.append("    </div>\n");

        // ── Col 2: Cartões + Iniciantes ───────────────────────────────────────
        sb.append("    <div class=\"f4-col\" style=\"width:20%; flex-shrink:0;\">\n");
        sb.append("      <div class=\"f4-section-title\" style=\"justify-content:center;\">Técnico</div>\n");
        sb.append("      <table class=\"f4-table\" style=\"border:none;\">\n");
        sb.append("        <thead><tr>");
        sb.append("<th style=\"width:28px; border-left:none; border-top:none;\">N</th>");
        sb.append("<th style=\"border-top:none;\">Amarelo</th>");
        sb.append("<th style=\"border-top:none;\">Vermelho</th>");
        sb.append("<th colspan=\"5\" style=\"border-right:none; border-top:none;\">Iniciantes</th>");
        sb.append("</tr></thead>\n        <tbody>\n");
        for (int i = 0; i < MAX_PLAYERS; i++) {
            RosterRow row = i < rows.size() ? rows.get(i) : new RosterRow("", "", "", "");
            sb.append("          <tr>");
            sb.append("<td style=\"border-left:none;\">").append(e(row.numero())).append("</td>");
            sb.append("<td>").append(e(row.amarelo())).append("</td>");
            sb.append("<td>").append(e(row.vermelho())).append("</td>");
            sb.append("<td></td><td></td><td></td><td></td>");
            sb.append("<td style=\"border-right:none;\"></td>");
            sb.append("</tr>\n");
        }
        sb.append("        </tbody>\n      </table>\n");
        sb.append("    </div>\n");

        // ── Col 3: Capitão + Metas ────────────────────────────────────────────
        sb.append("    <div class=\"f4-col\" style=\"width:28%; flex-shrink:0;\">\n");
        sb.append("      <div class=\"f4-section-title\" style=\"justify-content:center;\">Capitão (")
          .append(e(team.capitao())).append(")</div>\n");
        sb.append("      <div class=\"metas-container\">\n");
        sb.append("        <div class=\"metas-label\">Metas</div>\n");
        sb.append("        <div class=\"f4-meta-grid\">\n");
        List<GoalEntry> goals = team.goals();
        for (int i = 0; i < MAX_GOALS; i++) {
            String num = i < goals.size() ? e(goals.get(i).numeroJogador()) : "";
            String tempo = i < goals.size() ? e(goals.get(i).tempo()) : "";
            sb.append("          <div class=\"meta-cell\">");
            sb.append("<div class=\"meta-num\">").append(i + 1).append("</div>");
            sb.append("<div class=\"meta-data\"><strong>").append(num).append("</strong>");
            sb.append("<span>").append(tempo).append("</span></div>");
            sb.append("</div>\n");
        }
        sb.append("        </div>\n      </div>\n");
        sb.append("    </div>\n");

        // ── Col 4: Faltas + Pedidos + Geral ───────────────────────────────────
        sb.append("    <div class=\"f4-col\" style=\"flex-direction:row; flex:1; border-right:none;\">\n");
        sb.append("      <div class=\"v-bar\"><div class=\"v-text\">Faltas Acumuladas</div></div>\n");
        sb.append("      <div style=\"width:20px; background:#fff; border-right:1px solid #000;\"></div>\n");
        sb.append("      <div class=\"v-bar\"><div class=\"v-text\">Pedidos de Tempo</div></div>\n");
        sb.append("      <div class=\"geral-content\">\n");
        sb.append("        <div class=\"f4-section-title\" style=\"background:#f5f5f5; border-bottom:1px solid #000;\">Em Geral</div>\n");
        sb.append("        <table class=\"f4-table horarios-table\" style=\"border:none;\">\n");
        sb.append("          <tr style=\"background:#f5f5f5;\">");
        sb.append("<th style=\"border-left:none;\">Agendar</th><th>Lar</th><th style=\"border-right:none;\">Termino</th>");
        sb.append("</tr>\n");
        sb.append("          <tr>");
        sb.append("<td style=\"border-left:none;\">1º Tempo</td>");
        sb.append("<td>").append(e(ps.start1())).append("</td>");
        sb.append("<td style=\"border-right:none;\">").append(e(ps.end1())).append("</td>");
        sb.append("</tr>\n");
        sb.append("          <tr>");
        sb.append("<td style=\"border-left:none;\">2º Tempo</td>");
        sb.append("<td>").append(e(ps.start2())).append("</td>");
        sb.append("<td style=\"border-right:none;\">").append(e(ps.end2())).append("</td>");
        sb.append("</tr>\n");
        sb.append("        </table>\n");
        sb.append("        <div class=\"contagens-area\">\n");
        sb.append("          <div style=\"font-size:10px; font-weight:bold; margin-bottom:5px;\">Contagens</div>\n");
        sb.append("          <table style=\"width:100%; border-collapse:collapse;\">\n");
        sb.append(scoreRow("1º Tempo", ps.goalsA1(), ps.goalsB1()));
        sb.append(scoreRow("2º Tempo", ps.goalsA2(), ps.goalsB2()));
        sb.append(scoreRow("Total", ps.goalsAFinal(), ps.goalsBFinal()));
        if (ps.goalsAExtra() > 0 || ps.goalsBExtra() > 0) {
            sb.append(scoreRow("Prorrog.", ps.goalsAExtra(), ps.goalsBExtra()));
        }
        sb.append("          </table>\n        </div>\n      </div>\n");
        sb.append("    </div>\n");

        sb.append("  </div>\n"); // f4-team
        sb.append("  <div style=\"background:#fff; border-top:1px solid #000; height:80px; padding:10px; font-size:10px;\"></div>\n");
        sb.append("</div>\n"); // f4-body
        return sb.toString();
    }

    private String scoreRow(String label, int a, int b) {
        return "            <tr style=\"height:35px;\">"
                + "<td style=\"text-align:left; border:none; font-size:10px;\">" + label + "</td>"
                + "<td style=\"border:none;\"><div class=\"placar-box\">" + a + "</div></td>"
                + "<td style=\"border:none; padding:0 5px;\">X</td>"
                + "<td style=\"border:none;\"><div class=\"placar-box\">" + b + "</div></td>"
                + "</tr>\n";
    }

    private String footerHtml(SumulaData data) {
        StringBuilder sb = new StringBuilder();
        sb.append("<div class=\"footer\">\n");

        sb.append("  <div class=\"footer-row full-width\">");
        sb.append("<div class=\"footer-full-width-content\">").append(e(data.headerMatchup())).append("</div>");
        sb.append("</div>\n");

        sb.append("  <div class=\"footer-row\">");
        sb.append("<div class=\"footer-label\">Composição: ").append(e(data.competicao())).append("</div>");
        sb.append("<div class=\"footer-content\">Categoria: ").append(e(data.categoria())).append("</div>");
        sb.append("</div>\n");

        sb.append("  <div class=\"footer-half-row\">");
        sb.append("<div class=\"footer-half-left\">Nº Jogo: ").append(e(data.numeroJogo())).append("</div>");
        sb.append("<div class=\"footer-half-right\">");
        sb.append("<div class=\"footer-third-cell\">Grupo: ").append(e(data.grupo())).append("</div>");
        sb.append("<div class=\"footer-third-cell\">Fase: ").append(e(data.fase())).append("</div>");
        sb.append("<div class=\"footer-third-cell\">Data: ").append(e(data.data())).append("</div>");
        sb.append("</div></div>\n");

        sb.append("  <div class=\"footer-row full-width\">");
        sb.append("<div class=\"footer-full-width-content\">Equipe de Arbitragem</div>");
        sb.append("</div>\n");

        List<String> arb = data.arbitrationLines();
        for (int i = 0; i < 6; i++) {
            String line = i < arb.size() ? arb.get(i) : "";
            sb.append("  <div class=\"footer-row\">");
            sb.append("<div class=\"footer-label\">").append(e(line)).append("</div>");
            sb.append("<div class=\"footer-content\"></div>");
            sb.append("</div>\n");
        }

        sb.append("</div>\n");
        return sb.toString();
    }

    // ─── CSS ────────────────────────────────────────────────────────────────────

    private static String css() {
        return """
                @page { size: A4; margin: 5mm; }
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { font-family: Arial, sans-serif; background-color: white; font-size: 12px; }
                .container { border: 3px solid black; }

                /* HEADER */
                .header { display: flex; border-bottom: 3px solid black; }
                .header-left { width: 120px; border-right: 3px solid black; padding: 10px; display: flex;
                    flex-direction: column; align-items: center; justify-content: center; }
                .header-left img { width: 60px; height: auto; }
                .header-left-text { font-size: 10px; font-weight: bold; text-align: center; line-height: 1.2; }
                .header-center { flex: 1; display: flex; align-items: center; justify-content: center;
                    padding: 10px; }
                .header-score-group { display: flex; flex-direction: column; align-items: center; }
                .header-logo { width: 80px; height: 100px; display: flex; align-items: center; justify-content: center; }
                .header-logo img { width: 100%; height: auto; }
                .header-score-text { font-size: 12px; font-weight: bold; text-align: center;
                    flex: 1; padding: 0 10px; }

                /* GAME INFO */
                .game-info { border-bottom: 3px solid black; padding: 10px;
                    text-align: right; font-size: 11px; font-weight: bold; }

                /* F4 BODY */
                .f4-body { border-bottom: 3px solid #191919; }
                .f4-team { display: flex; border-bottom: 1px solid #191919; }
                .f4-col { border-right: 1px solid #000; display: flex; flex-direction: column; }
                .f4-section-title { border-bottom: 1px solid #000; padding: 8px 6px; font-weight: bold;
                    font-size: 11px; min-height: 35px; display: flex; align-items: center; }
                .f4-table { width: 100%; border-collapse: collapse; }
                .f4-table th { border: 1px solid #191919; padding: 3px 2px; font-size: 10px;
                    font-weight: bold; text-align: center; background-color: #fff; }
                .f4-table td { border: 1px solid #191919; padding: 2px 3px; font-size: 10px;
                    text-align: center; height: 22px; vertical-align: middle; }
                .f4-player-name { text-align: left; padding-left: 6px; font-size: 9px; }
                .f4-staff-row { border-top: 1px solid #191919; border-bottom: 1px solid #191919;
                    padding: 3px 5px; font-size: 9px; }

                /* METAS */
                .metas-container { display: flex; flex-direction: column; flex: 1; }
                .metas-label { padding: 4px 8px; font-size: 10px; border-bottom: 1px solid #000; }
                .f4-meta-grid { display: flex; flex-wrap: wrap; flex: 1;
                    background-color: #000; gap: 1px; }
                .meta-cell { display: flex; background-color: #fff; height: 48px;
                    width: calc(33.33% - 1px); }
                .meta-num { width: 25px; font-size: 9px; border-right: 1px solid #000;
                    display: flex; align-items: center; justify-content: center;
                    background-color: #f9f9f9; }
                .meta-data { flex: 1; display: flex; flex-direction: column; align-items: center;
                    justify-content: center; font-size: 10px; line-height: 1.2; }

                /* V-BAR (faltas / pedidos de tempo) */
                .v-bar { background-color: #000; color: #fff; width: 30px; display: flex;
                    align-items: center; justify-content: center; border-right: 1px solid #fff; }
                .v-text { writing-mode: vertical-rl; transform: rotate(180deg);
                    white-space: nowrap; font-size: 9px; font-weight: bold; text-transform: uppercase; }

                /* GERAL */
                .geral-content { flex: 1; display: flex; flex-direction: column; }
                .horarios-table td { height: 30px; }
                .contagens-area { padding: 10px; border-top: 1px solid #000; }
                .placar-box { border: 1px solid #000; width: 35px; height: 30px; display: inline-flex;
                    align-items: center; justify-content: center; font-weight: bold; font-size: 13px; }

                /* FOOTER */
                .footer { padding: 10px; }
                .footer-row { display: flex; margin-bottom: 2px; border: 1px solid black; min-height: 25px; }
                .footer-label { width: 350px; border-right: 1px solid black; padding: 5px;
                    font-weight: bold; font-size: 10px; display: flex; align-items: center; }
                .footer-content { flex: 1; padding: 5px; font-size: 10px; display: flex; align-items: center; }
                .footer-row.full-width { justify-content: center; align-items: center; text-align: center;
                    background-color: #f5f5f5; font-weight: bold; }
                .footer-full-width-content { width: 100%; text-align: center; font-weight: bold;
                    display: flex; align-items: center; justify-content: center; padding: 5px; }
                .footer-half-row { display: flex; margin-bottom: 2px; border: 1px solid black; min-height: 25px; }
                .footer-half-left { flex: 1; border-right: 1px solid black; padding: 5px;
                    font-weight: bold; font-size: 10px; display: flex; align-items: center; }
                .footer-half-right { flex: 1; display: flex; }
                .footer-third-cell { flex: 1; border-right: 1px solid black; padding: 5px;
                    font-size: 10px; display: flex; align-items: center; }
                .footer-third-cell:last-child { border-right: none; }
                """;
    }

    // ─── UTILITY ────────────────────────────────────────────────────────────────

    /** HTML escape */
    private static String e(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
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
            String escudoA, String escudoB
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
