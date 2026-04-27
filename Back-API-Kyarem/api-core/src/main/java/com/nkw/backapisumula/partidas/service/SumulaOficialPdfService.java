package com.nkw.backapisumula.partidas.service;

import com.nkw.backapisumula.partidas.EventoPartida;
import com.nkw.backapisumula.partidas.Partida;
import com.nkw.backapisumula.partidas.repo.EventoPartidaRepository;
import com.nkw.backapisumula.partidas.repo.PartidaRepository;
import com.openhtmltopdf.pdfboxout.PdfRendererBuilder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayOutputStream;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class SumulaOficialPdfService {

    private static final DateTimeFormatter DATE_TIME_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private final PartidaRepository partidaRepo;
    private final EventoPartidaRepository eventoRepo;

    public SumulaOficialPdfService(PartidaRepository partidaRepo, EventoPartidaRepository eventoRepo) {
        this.partidaRepo = partidaRepo;
        this.eventoRepo = eventoRepo;
    }

    @Transactional(readOnly = true)
    public byte[] gerarPdf(UUID partidaId) {
        Partida partida = partidaRepo.findById(partidaId)
                .orElseThrow(() -> new IllegalStateException("Partida não encontrada."));
        List<EventoPartida> eventos = eventoRepo.findByPartidaIdWithDetails(partidaId);

        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            PdfRendererBuilder builder = new PdfRendererBuilder();
            builder.useFastMode();
            builder.withHtmlContent(buildHtml(partida, eventos), null);
            builder.toStream(out);
            builder.run();
            return out.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Erro ao gerar PDF da súmula.", e);
        }
    }

    private String buildHtml(Partida partida, List<EventoPartida> eventos) {
        StringBuilder sb = new StringBuilder();
        sb.append("<html><head><meta charset=\"UTF-8\"/><style>");
        sb.append("body{font-family:Arial,sans-serif;font-size:12px;color:#111;padding:24px;}");
        sb.append("h1,h2{margin:0 0 12px 0;}table{width:100%;border-collapse:collapse;margin-top:16px;}");
        sb.append("th,td{border:1px solid #ccc;padding:6px;vertical-align:top;text-align:left;}");
        sb.append("th{background:#f3f3f3;} .meta{margin:4px 0;} .muted{color:#666;}");
        sb.append("</style></head><body>");

        sb.append("<h1>Súmula da Partida</h1>");
        sb.append("<div class=\"meta\"><strong>ID:</strong> ").append(e(partida.getId() != null ? partida.getId().toString() : "")).append("</div>");
        sb.append("<div class=\"meta\"><strong>Status:</strong> ").append(e(partida.getStatus())).append("</div>");
        sb.append("<div class=\"meta\"><strong>Equipe A:</strong> ").append(e(nomeEquipe(partida.getEquipeA()))).append("</div>");
        sb.append("<div class=\"meta\"><strong>Equipe B:</strong> ").append(e(nomeEquipe(partida.getEquipeB()))).append("</div>");
        sb.append("<div class=\"meta\"><strong>Modalidade:</strong> ").append(e(
                partida.getModalidade() != null ? partida.getModalidade().getNome() : "")).append("</div>");
        sb.append("<div class=\"meta\"><strong>Competição:</strong> ").append(e(
                partida.getModalidade() != null ? partida.getModalidade().getCampeonatoNome() : "")).append("</div>");
        sb.append("<div class=\"meta\"><strong>Agendada para:</strong> ").append(e(format(partida.getAgendadoPara()))).append("</div>");
        sb.append("<div class=\"meta\"><strong>Local:</strong> ").append(e(partida.getLocal())).append("</div>");
        sb.append("<div class=\"meta\"><strong>Placar:</strong> ")
                .append(Optional.ofNullable(partida.getPlacarA()).orElse(0))
                .append(" x ")
                .append(Optional.ofNullable(partida.getPlacarB()).orElse(0))
                .append("</div>");

        sb.append("<h2>Eventos</h2>");
        sb.append("<table><thead><tr>");
        sb.append("<th>Horário</th><th>Período</th><th>Tempo</th><th>Tipo</th><th>Equipe</th><th>Atleta</th><th>Detalhes</th>");
        sb.append("</tr></thead><tbody>");

        if (eventos.isEmpty()) {
            sb.append("<tr><td colspan=\"7\" class=\"muted\">Nenhum evento registrado.</td></tr>");
        } else {
            for (EventoPartida evento : eventos) {
                sb.append("<tr>");
                sb.append("<td>").append(e(format(evento.getCriadoEm()))).append("</td>");
                sb.append("<td>").append(e(evento.getPeriodo())).append("</td>");
                sb.append("<td>").append(e(evento.getTempoCronometro())).append("</td>");
                sb.append("<td>").append(e(evento.getTipoEvento() != null ? evento.getTipoEvento().getNome() : "")).append("</td>");
                sb.append("<td>").append(e(nomeEquipe(evento.getEquipe()))).append("</td>");
                sb.append("<td>").append(e(evento.getAtleta() != null ? evento.getAtleta().getNome() : "")).append("</td>");
                sb.append("<td>").append(e(descricaoEvento(evento))).append("</td>");
                sb.append("</tr>");
            }
        }

        sb.append("</tbody></table></body></html>");
        return sb.toString();
    }

    private String nomeEquipe(com.nkw.backapisumula.competicao.CampeonatoTime equipe) {
        return equipe != null ? Optional.ofNullable(equipe.getNomeEquipe()).orElse("") : "";
    }

    private String descricaoEvento(EventoPartida evento) {
        if (evento.getDescricaoDetalhada() != null && !evento.getDescricaoDetalhada().isBlank()) {
            return evento.getDescricaoDetalhada();
        }
        if (evento.getDadosExtras() != null && !evento.getDadosExtras().isNull()) {
            return evento.getDadosExtras().toString();
        }
        if (Boolean.TRUE.equals(evento.getIsSubstitution()) && evento.getAtletaSai() != null) {
            return "Substituição: sai " + evento.getAtletaSai().getNome();
        }
        return "";
    }

    private String format(OffsetDateTime value) {
        return value != null ? DATE_TIME_FMT.format(value) : "";
    }

    private String e(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }
}
