import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/helpers/evento_partida_model.dart';
import 'package:kyarem_eventos/models/partida_model.dart';
import 'package:kyarem_eventos/services/partida_service.dart';
import 'package:kyarem_eventos/models/atleta_model.dart';
import 'package:kyarem_eventos/services/pdf_service.dart';
import 'package:printing/printing.dart';
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

  List<SummaryEventItem> _eventosExibidos = [];
  bool _carregando = false;
  Partida? _partidaApi;
  List<Atleta> _jogadoresA = [];
  List<Atleta> _jogadoresB = [];

  @override
  void initState() {
    super.initState();

    if (widget.partidaId != null) {
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
      await _carregarAtletasEquipes();
    } catch (e) {
      debugPrint('Erro ao carregar partida da API: $e');
    }
  }

  Future<void> _carregarAtletasEquipes() async {
    if (_partidaApi == null) return;
    try {
      final aId = _partidaApi!.equipeAId;
      final bId = _partidaApi!.equipeBId;

      if (aId.isNotEmpty) {
        final inscritosA = await _partidaService.buscarInscritos(aId);
        _jogadoresA = inscritosA
            .map((m) => Atleta.fromMap(m as Map<String, dynamic>))
            .toList();
      }
      if (bId.isNotEmpty) {
        final inscritosB = await _partidaService.buscarInscritos(bId);
        _jogadoresB = inscritosB
            .map((m) => Atleta.fromMap(m as Map<String, dynamic>))
            .toList();
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Erro ao carregar atletas para edição: $e');
    }
  }

  Future<void> _abrirPdfFechado(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<DropdownMenuItem<String>> _buildAtletasItems(String equipeId) {
    final lista = equipeId == _partidaApi?.equipeAId
        ? _jogadoresA
        : _jogadoresB;
    return lista
        .map(
          (a) => DropdownMenuItem(
            value: a.atletaId,
            child: Text(
              '${a.numero} - ${a.nome}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        )
        .toList();
  }

  Future<void> _abrirEdicaoEvento(SummaryEventItem item) async {
    if (_partidaApi == null || widget.partidaId == null) return;

    // Loading rápido antes de buscar tipos/atletas
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00FFC2)),
        ),
      );
    }

    final tipos = await _partidaService.buscarTiposDeEventoDaPartida(
      _partidaApi!.modalidadeId,
    );

    // garante atletas carregados para os dropdowns
    if (_jogadoresA.isEmpty && _jogadoresB.isEmpty) {
      await _carregarAtletasEquipes();
    }

    if (mounted) {
      Navigator.of(context).pop(); // fecha loading
    }

    final isFinalizada =
        _partidaApi!.status.trim().toLowerCase() == 'finalizada';
    if (!isFinalizada) return;

    String? tipoSelecionadoId = item.tipoEventoId;
    String? equipeSelecionadaId = item.equipeId ?? _partidaApi!.equipeAId;
    String? atletaEntraId = item.atletaId;
    String? atletaSaiId = item.atletaSaiId;
    bool isSubstitution = item.isSubstitution;
    String descricao = item.evento.observacao ?? '';

    final descricaoController = TextEditingController(text: descricao);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2D2D2D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Editar evento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF2D2D2D),
                      value: tipoSelecionadoId,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de evento',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      items: tipos
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(
                                t.nomeFormatado,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setModalState(() => tipoSelecionadoId = v),
                    ),
                    const SizedBox(height: 12),
                    // Equipe (opcional para eventos gerais; obrigatória se houver atleta)
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF2D2D2D),
                      value: equipeSelecionadaId,
                      decoration: const InputDecoration(
                        labelText: 'Equipe (se aplicável)',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: _partidaApi!.equipeAId,
                          child: Text(
                            widget.timeA,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: _partidaApi!.equipeBId,
                          child: Text(
                            widget.timeB,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (v) =>
                          setModalState(() => equipeSelecionadaId = v),
                    ),
                    const SizedBox(height: 12),
                    // Toggle substituição
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'É substituição?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      value: isSubstitution,
                      onChanged: (v) {
                        setModalState(() {
                          isSubstitution = v;
                          if (!v) {
                            atletaSaiId = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // Atleta entra
                    if (equipeSelecionadaId != null)
                      DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF2D2D2D),
                        value: atletaEntraId,
                        decoration: const InputDecoration(
                          labelText: 'Atleta (entra) - opcional',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        items: _buildAtletasItems(equipeSelecionadaId!),
                        onChanged: (v) =>
                            setModalState(() => atletaEntraId = v),
                      ),
                    const SizedBox(height: 8),
                    // Atleta sai (apenas se substituição)
                    if (isSubstitution && equipeSelecionadaId != null)
                      DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF2D2D2D),
                        value: atletaSaiId,
                        decoration: const InputDecoration(
                          labelText: 'Atleta (sai)',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        items: _buildAtletasItems(equipeSelecionadaId!),
                        onChanged: (v) => setModalState(() => atletaSaiId = v),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descricaoController,
                      onChanged: (v) => descricao = v,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (tipoSelecionadoId == null ||
                              tipoSelecionadoId!.isEmpty) {
                            Navigator.pop(context);
                            return;
                          }

                          // Se tiver atleta, precisa de equipe
                          if ((atletaEntraId != null || atletaSaiId != null) &&
                              (equipeSelecionadaId == null ||
                                  equipeSelecionadaId!.isEmpty)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Selecione a equipe para associar o atleta.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          await _partidaService.atualizarEvento(
                            partidaId: widget.partidaId!,
                            eventoId: item.id,
                            tipoEventoId: tipoSelecionadoId!,
                            equipeId: equipeSelecionadaId,
                            atletaId: atletaEntraId,
                            atletaSaiId: atletaSaiId,
                            isSubstitution: isSubstitution,
                            tempoFormatado: item.evento.horario,
                            descricao: descricao,
                          );

                          if (!mounted) return;
                          setState(() {
                            final idx = _eventosExibidos.indexWhere(
                              (e) => e.id == item.id,
                            );
                            if (idx >= 0) {
                              _eventosExibidos[idx] = SummaryEventItem(
                                id: item.id,
                                tipoEventoId: tipoSelecionadoId!,
                                equipeId: equipeSelecionadaId,
                                atletaId: atletaEntraId,
                                atletaSaiId: atletaSaiId,
                                isSubstitution: isSubstitution,
                                tempoCronometro: item.evento.horario,
                                evento: EventoPartida(
                                  tipo: tipos
                                      .firstWhere(
                                        (t) => t.id == tipoSelecionadoId,
                                        orElse: () => tipos.first,
                                      )
                                      .nomeFormatado,
                                  jogadorNome: item.evento.jogadorNome,
                                  jogadorNumero: item.evento.jogadorNumero,
                                  corTime: item.evento.corTime,
                                  horario: item.evento.horario,
                                  observacao: descricao,
                                ),
                              );
                            }
                          });

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FFC2),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          'Salvar alterações',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmarExclusaoEvento(SummaryEventItem item) async {
    if (widget.partidaId == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir evento'),
          content: const Text('Tem certeza que deseja excluir este evento?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    await _partidaService.excluirEvento(
      partidaId: widget.partidaId!,
      eventoId: item.id,
    );

    if (!mounted) return;
    setState(() {
      _eventosExibidos.removeWhere((e) => e.id == item.id);
    });
  }

  Future<void> _fecharSumula() async {
    final id = widget.partidaId;
    if (id == null) return;

    setState(() => _carregando = true);

    bool loadingDialogOpen = false;
    if (mounted) {
      loadingDialogOpen = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (_) {
          return const Center(
            child: SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                color: Color(0xFF00FFC2),
                strokeWidth: 6,
              ),
            ),
          );
        },
      );
    }

    try {
      final (code, detail) = await _partidaService.endPartida(id);
      if (!mounted) return;

      if (code == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              detail?.isNotEmpty == true
                  ? 'Falha ao fechar súmula: $detail'
                  : 'Falha ao fechar súmula (conflito 409).',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Súmula fechada com sucesso.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _carregarPartidaDaApi();
    } catch (e) {
      debugPrint('Erro ao fechar súmula: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível fechar a súmula: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (loadingDialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _gerarPdfOficial() async {
    final id = widget.partidaId;
    if (id == null) {
      final List<EventoPartida> eventosTyped = _eventosExibidos
          .map((e) => e.evento)
          .toList();
      await PdfService.gerarSumulaPartida(
        context: context,
        timeA: widget.timeA,
        timeB: widget.timeB,
        golsA: widget.golsA,
        golsB: widget.golsB,
        eventos: eventosTyped,
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 16),
            Expanded(child: Text('Gerando súmula oficial...')),
          ],
        ),
      ),
    );

    try {
      final bytes = await _partidaService.baixarSumulaOficialPdf(id);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Sumula_Oficial_${widget.timeA}_x_${widget.timeB}.pdf',
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível gerar a súmula oficial: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _carregarEventosDoBanco() async {
    setState(() => _carregando = true);

    try {
      final raw = await _partidaService.buscarEventosDaPartida(
        widget.partidaId!,
      );

      final eventos = raw.map((ev) {
        final tipoNome = (ev['tipo_evento']?['nome']?.toString() ?? 'Evento');
        final id = ev['id']?.toString() ?? '';
        final equipeId = ev['equipe_id']?.toString();
        final atletaId = ev['atleta_id']?.toString();
        final atletaSaiId = ev['atleta_sai_id']?.toString();
        final isSub = ev['is_substitution'] == true;
        final tipoEventoId = ev['tipo_evento_id']?.toString() ?? '';
        final tempo = ev['tempo_cronometro']?.toString() ?? '00:00';

        return SummaryEventItem(
          id: id,
          tipoEventoId: tipoEventoId,
          tempoCronometro: tempo,
          equipeId: equipeId,
          atletaId: atletaId,
          atletaSaiId: atletaSaiId,
          isSubstitution: isSub,
          evento: EventoPartida(
            tipo: tipoNome,
            jogadorNome: null,
            jogadorNumero: null,
            corTime: null,
            horario: tempo,
            observacao: ev['descricao_detalhada']?.toString() ?? '',
          ),
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
            const GradientBackground(heightFactor: 1.0),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 20,
                                  color: Colors.grey,
                                ),
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
                          if (_eventosExibidos.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                "Nenhum evento registrado.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            Opacity(
                              opacity: _carregando ? 0.35 : 1.0,
                              child: IgnorePointer(
                                ignoring: _carregando,
                                child: SummaryEventList(
                                  eventos: _eventosExibidos,
                                  podeEditar:
                                      _partidaApi?.status
                                          .trim()
                                          .toLowerCase() ==
                                      'finalizada',
                                  onEdit: _abrirEdicaoEvento,
                                  onDelete: _confirmarExclusaoEvento,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
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

                      await _gerarPdfOficial();
                    },
                    onClosePressed:
                        (_partidaApi?.status.trim().toLowerCase() ==
                                'finalizada' &&
                            !_carregando)
                        ? _fecharSumula
                        : null,
                    onHomePressed: () {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/home', (route) => false);
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
