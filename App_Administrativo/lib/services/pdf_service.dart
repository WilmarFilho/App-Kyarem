import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/partida_model.dart';
import '../data/models/evento_model.dart';

class PdfService {
  static Future<void> gerarSumulaPdf(Partida partida, List<Evento> eventos) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // CABEÇALHO
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("SUMULA OFICIAL DE PARTIDA", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    pw.Text("ID: ${partida.id}"),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // INFO PARTIDA
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(children: [
                    pw.Text(partida.nomeTimeA, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text("${partida.sumula.placarTimeA}", style: pw.TextStyle(fontSize: 30)),
                  ]),
                  pw.Text("X", style: pw.TextStyle(fontSize: 20)),
                  pw.Column(children: [
                    pw.Text(partida.nomeTimeB, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text("${partida.sumula.placarTimeB}", style: pw.TextStyle(fontSize: 30)),
                  ]),
                ],
              ),
              pw.Divider(),

              // CRONOLOGIA (TABELA)
              pw.Text("RELATORIO DE EVENTOS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                context: context,
                data: <List<String>>[
                  <String>['Hora', 'Atleta', 'Evento', 'Time'],
                  ...eventos.map((ev) => [
                        ev.timestamp.toString().substring(11, 16),
                        ev.atletaNome,
                        ev.tipo,
                        // Aqui você pode adicionar uma lógica para identificar o time se tiver no modelo
                        "Registrado" 
                      ])
                ],
              ),

              pw.Spacer(),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text("Gerado automaticamente pelo App Árbitro - ${DateTime.now().toString()}"),
              )
            ],
          );
        },
      ),
    );

    // Abre a pré-visualização de impressão do sistema
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'sumula_partida_${partida.id}.pdf',
    );
  }
}