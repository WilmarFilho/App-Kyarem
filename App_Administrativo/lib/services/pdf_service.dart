import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/helpers/evento_partida_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Serviço responsável por gerar o PDF da súmula da partida
/// com detalhes do jogo e lista de todos os eventos.
class PdfService {
  PdfService._();

  static Future<pw.Document> _buildDocumentoSumula({
    required BuildContext context,
    required String timeA,
    required String timeB,
    required int golsA,
    required int golsB,
    required List<EventoPartida> eventos,
  }) async {
    final pdf = pw.Document(title: 'Súmula da Partida', author: 'App Árbitro');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Text(
            'SÚMULA DA PARTIDA',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ),
        build: (context) => [
          _buildSecaoDetalhes(
            timeA: timeA,
            timeB: timeB,
            golsA: golsA,
            golsB: golsB,
          ),
          pw.SizedBox(height: 24),
          _buildSecaoEventos(eventos),
        ],
      ),
    );
    return pdf;
  }

  /// Gera os bytes do PDF da súmula (para upload ou salvamento).
  static Future<List<int>> gerarSumulaBytes({
    required BuildContext context,
    required String timeA,
    required String timeB,
    required int golsA,
    required int golsB,
    required List<EventoPartida> eventos,
  }) async {
    final doc = await _buildDocumentoSumula(
      context: context,
      timeA: timeA,
      timeB: timeB,
      golsA: golsA,
      golsB: golsB,
      eventos: eventos,
    );
    return doc.save();
  }

  /// Gera o PDF da súmula e abre a pré-visualização (fluxo atual).
  static Future<void> gerarSumulaPartida({
    required BuildContext context,
    required String timeA,
    required String timeB,
    required int golsA,
    required int golsB,
    required List<EventoPartida> eventos,
  }) async {
    final doc = await _buildDocumentoSumula(
      context: context,
      timeA: timeA,
      timeB: timeB,
      golsA: golsA,
      golsB: golsB,
      eventos: eventos,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Sumula_Partida_${timeA}_x_$timeB.pdf',
    );
  }

  static pw.Widget _buildSecaoDetalhes({
    required String timeA,
    required String timeB,
    required int golsA,
    required int golsB,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DETALHES DA PARTIDA',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey800),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              pw.Expanded(
                child: pw.Text(
                  timeA,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
              pw.Text(
                '$golsA x $golsB',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  timeB,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSecaoEventos(List<EventoPartida> eventos) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RESUMO DOS EVENTOS',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        if (eventos.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 16),
            child: pw.Text(
              'Nenhum evento registrado.',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          )
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(4),
              2: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _cell('Tempo', isHeader: true),
                  _cell('Descrição / Detalhe', isHeader: true),
                  _cell('Jogador', isHeader: true),
                ],
              ),
              ...eventos.map(
                (ev) => pw.TableRow(
                  children: [
                    _cell(ev.horario),
                    _cell(ev.descricao),
                    _cell(
                      ev.jogadorNome ?? ev.jogadorNumero?.toString() ?? '—',
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
