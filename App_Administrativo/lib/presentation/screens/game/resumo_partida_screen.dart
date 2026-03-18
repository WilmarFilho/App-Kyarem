import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:kyarem_eventos/models/helpers/evento_partida_model.dart';
import 'package:kyarem_eventos/models/partida_model.dart';
import 'package:kyarem_eventos/services/partida_service.dart';
import 'package:kyarem_eventos/services/pdf_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/game/summary_header.dart';
import '../../widgets/game/summary_score_card.dart';
import '../../widgets/game/summary_event_list.dart';
import '../../widgets/game/summary_action_buttons.dart';

class MatchSummaryScreen extends StatefulWidget {
  final String timeA;
  final String timeB;
  final int golsA;
  final int golsB;
  final List<dynamic> eventos;
  final String? partidaId; // ← novo, opcional para busca retroativa
  final String? escudoA;
  final String? escudoB;

  const MatchSummaryScreen({
    super.key,
    required this.timeA,
    required this.timeB,
    this.escudoA,
    this.escudoB,
    required this.golsA,
    required this.golsB,
    this.eventos = const [],
    this.partidaId,
  });

  @override
  State<MatchSummaryScreen> createState() => _MatchSummaryScreenState();
}

class _MatchSummaryScreenState extends State<MatchSummaryScreen> {
  final PartidaService _partidaService = PartidaService();

  List<dynamic> _eventosExibidos = [];
  bool _carregando = false;
  Partida? _partidaApi;

  @override
  void initState() {
    super.initState();

    if (widget.eventos.isNotEmpty) {
      // Fluxo normal: veio direto da tela de arbitragem
      _eventosExibidos = widget.eventos;
    } else if (widget.partidaId != null) {
      // Fluxo retroativo: partida já finalizada, busca do banco
      _carregarEventosDoBanco();
    }

    if (widget.partidaId != null) {
      _carregarPartidaDaApi();
    }
  }

  Future<void> _carregarPartidaDaApi() async {
    try {
      final p = await _partidaService.buscarPartidaPorId(widget.partidaId!);
      if (!mounted) return;
      setState(() => _partidaApi = p);
    } catch (e) {
      debugPrint('Erro ao carregar partida da API: $e');
    }
  }

  Future<void> _fecharSumula() async {
    final id = widget.partidaId;
    if (id == null) return;

    setState(() => _carregando = true);
    try {
      // 1) Gera o PDF final da súmula em memória
      final List<EventoPartida> eventosTyped =
          _eventosExibidos is List<EventoPartida>
              ? _eventosExibidos as List<EventoPartida>
              : _eventosExibidos.cast<EventoPartida>();

      final bytes = await PdfService.gerarSumulaBytes(
        context: context,
        timeA: widget.timeA,
        timeB: widget.timeB,
        golsA: widget.golsA,
        golsB: widget.golsB,
        eventos: eventosTyped,
      );

      // 2) Faz upload no bucket do Supabase
      final client = Supabase.instance.client;
      const bucket = 'sumulas'; // ajuste o nome do bucket se for diferente
      final path =
          'partidas/$id/sumula_${DateTime.now().toUtc().toIso8601String()}.pdf';

      await client.storage
          .from(bucket)
          .uploadBinary(path, Uint8List.fromList(bytes));

      final publicUrl = client.storage.from(bucket).getPublicUrl(path);

      // 3) Chama o endpoint /end enviando a URL para persistir em sumulaPdfUrl
      await _partidaService.endPartida(id, sumulaPdfUrl: publicUrl);
      await _carregarPartidaDaApi(); // atualiza status/URL
    } catch (e) {
      debugPrint('Erro ao fechar súmula: $e');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrirPdfFechado(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _carregarEventosDoBanco() async {
    setState(() => _carregando = true);

    try {
      final raw = await _partidaService.buscarEventosDaPartida(widget.partidaId!);

      // Converte os Maps do banco em EventoPartida para manter compatibilidade
      final eventos = raw.map((ev) {
        final tipoNome = (ev['tipo_evento']?['nome']?.toString() ?? 'Evento');
        return EventoPartida(
          tipo: tipoNome,
          jogadorNome: null,    // ajuste se seu modelo suportar
          jogadorNumero: null,
          corTime: null,
          horario: ev['tempo_cronometro']?.toString() ?? '00:00',
        );
      }).toList();

      if (mounted) {
        setState(() {
          _eventosExibidos = eventos;
          _carregando = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar eventos da partida: $e');
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            const GradientBackground(heightFactor: 0.9),
            SafeArea(
              child: Column(
                children: [
                  const SummaryHeader(),
                  SummaryScoreCard(
                    timeA: widget.timeA,
                    timeB: widget.timeB,
                    escudoA: widget.escudoA,
                    escudoB: widget.escudoB,
                    golsA: widget.golsA,
                    golsB: widget.golsB,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 20, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          "RESUMO DOS EVENTOS",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _carregando
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF00FFC2),
                            ),
                          )
                        : _eventosExibidos.isEmpty
                            ? const Center(
                                child: Text(
                                  "Nenhum evento registrado.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : SummaryEventList(eventos: _eventosExibidos),
                  ),
                  SummaryActionButtons(
                    onPdfPressed: () async {
                      final st = _partidaApi?.status.trim().toLowerCase();
                      final pdfUrl = _partidaApi?.sumulaPdfUrl?.trim();

                      if (st == 'fechada' &&
                          pdfUrl != null &&
                          pdfUrl.isNotEmpty) {
                        await _abrirPdfFechado(pdfUrl);
                        return;
                      }

                      final List<EventoPartida> eventosTyped =
                          _eventosExibidos is List<EventoPartida>
                              ? _eventosExibidos as List<EventoPartida>
                              : _eventosExibidos.cast<EventoPartida>();
                      await PdfService.gerarSumulaPartida(
                        context: context,
                        timeA: widget.timeA,
                        timeB: widget.timeB,
                        golsA: widget.golsA,
                        golsB: widget.golsB,
                        eventos: eventosTyped,
                      );
                    },
                    onClosePressed:
                        (_partidaApi?.status.trim().toLowerCase() == 'finalizada')
                            ? _fecharSumula
                            : null,
                    onHomePressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home',
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}