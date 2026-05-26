import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/partida_model.dart';
import 'package:kyarem_eventos/models/match_rules.dart';
import 'package:kyarem_eventos/models/tipo_evento_model.dart';
import 'package:kyarem_eventos/models/atleta_model.dart';
import 'package:kyarem_eventos/models/helpers/evento_partida_model.dart';
import 'package:kyarem_eventos/presentation/screens/game/resumo_partida_screen.dart';
import 'package:kyarem_eventos/presentation/screens/game/eliminatorias_post_match_screen.dart';
import 'package:kyarem_eventos/services/partida_service.dart';
import 'package:printing/printing.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/game/game_scoreboard.dart';
import '../../widgets/game/game_events_feed.dart';
import '../../widgets/game/game_timer_card.dart';
import '../../widgets/game/game_field.dart';
import '../../widgets/game/game_actions_panel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum PeriodoPartida {
  naoIniciada,
  pausada,
  primeiroTempo,
  intervalo,
  segundoTempo,
  prorrogacao,
  acrescimo,
  aguardandoPenaltis,
  finalizada,
  fechada,
}

class _ObservacaoEventoModal extends StatefulWidget {
  final String tituloEvento;
  final String? nomeJogador;

  const _ObservacaoEventoModal({required this.tituloEvento, this.nomeJogador});

  @override
  State<_ObservacaoEventoModal> createState() => _ObservacaoEventoModalState();
}

class _ObservacaoEventoModalState extends State<_ObservacaoEventoModal> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2D2D2D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Barra superior
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),

            const SizedBox(height: 18),

            /// Título
            const Text(
              'Detalhar evento',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            /// Descrição
            Text(
              widget.nomeJogador == null || widget.nomeJogador!.trim().isEmpty
                  ? 'Adicione uma observação para ${widget.tituloEvento}. Esse campo é opcional.'
                  : 'Adicione uma observação para ${widget.tituloEvento} de ${widget.nomeJogador}. Esse campo é opcional.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            /// Campo texto
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              minLines: 3,
              maxLength: 280,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ex.: toque por trás, reclamação, lance confuso...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 8),

            /// Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, ''),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Sem observação'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final texto = controller.text.trim();
                      Navigator.pop(context, texto);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FFC2),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Salvar evento',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PartidaRunningScreen extends StatefulWidget {
  final Partida partida;
  final PartidaService? partidaService;

  const PartidaRunningScreen({
    super.key,
    required this.partida,
    this.partidaService,
  });

  @override
  State<PartidaRunningScreen> createState() => _PartidaRunningScreenState();
}

class _PartidaRunningScreenState extends State<PartidaRunningScreen>
    with WidgetsBindingObserver {
  static const String _statusAguardandoPenaltis = 'pênaltis';
  MatchRules _matchRules = const MatchRules();

  late final PartidaService _partidaService =
      widget.partidaService ?? PartidaService();
  List<TipoEventoEsporte> _tiposDeEventosDisponiveis = [];

  late int _golsA;
  late int _golsB;
  bool _carregandoDados = true;

  String _nomeTimeA = "Time A";
  String _nomeTimeB = "Time B";

  List<Atleta> _jogadoresA = [];
  List<Atleta> _jogadoresB = [];
  List<Atleta> _reservasA = [];
  List<Atleta> _reservasB = [];

  late PeriodoPartida _periodoAtual;
  PeriodoPartida? _periodoAntesDoAcrescimo;
  PeriodoPartida? _periodoAntesDoPausa;

  Timer? _intervaloTimer;
  int _segundosIntervalo = 0;

  Timer? _timer;
  int _segundos = 0;
  bool _rodando = false;

  int _segundosPausa = 0;
  bool _partidaJaIniciou = false;

  bool _emPausaTecnica = false;
  String _timeEmPausaTecnica = '';
  int _segundosPausaTecnica = 0;

  Timer? _timerPausaTecnica;
  Timer? _timerAcrescimo;
  Timer? _timerProrrogacao;
  Timer? _timerPausa;

  Atleta? _jogadorSelecionado;

  final List<EventoPartida> _eventosPartida = [];

  RealtimeChannel? _partidaChannel;
  RealtimeChannel? _eventosChannel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _golsA = widget.partida.placarA;
    _golsB = widget.partida.placarB;
    _nomeTimeA = widget.partida.equipeA?.nome ?? "Time A";
    _nomeTimeB = widget.partida.equipeB?.nome ?? "Time B";

    _periodoAtual = _converterStatusParaPeriodo(widget.partida.status);
    if (_periodoAtual != PeriodoPartida.naoIniciada &&
        _periodoAtual != PeriodoPartida.aguardandoPenaltis) {
      _partidaJaIniciou = true;
    }

    // Se entrar em partida encerrada, não liga timers nem permite interação
    if (_periodoAtual == PeriodoPartida.finalizada ||
        _periodoAtual == PeriodoPartida.aguardandoPenaltis ||
        _periodoAtual == PeriodoPartida.fechada) {
      _rodando = false;
      _timer?.cancel();
      _timerPausa?.cancel();
    }

    // Se a partida já entrar pausada, recupera qual era o status antes da pausa
    if (_periodoAtual == PeriodoPartida.pausada) {
      final rawAntes = widget.partida.periodoAntesPausa?.trim();
      if (rawAntes != null && rawAntes.isNotEmpty) {
        _periodoAntesDoPausa = _converterStatusParaPeriodo(rawAntes);
        if (_periodoAntesDoPausa != PeriodoPartida.naoIniciada &&
            _periodoAntesDoPausa != PeriodoPartida.finalizada) {
          _partidaJaIniciou = true;
        }
      }
    }

    _carregarDadosIniciais();
  }

  void _initRealtimeListeners() {
    _partidaChannel = _partidaService.subscribeRealtimePartida(
      widget.partida.id,
      onUpdate: (payload) {
        if (!mounted) return;
        final novoStatus = payload['status']?.toString() ?? '';
        if (novoStatus.isNotEmpty) {
          final novoPeriodo = _converterStatusParaPeriodo(novoStatus);
          if (novoPeriodo != _periodoAtual) {
            setState(() {
              _periodoAtual = novoPeriodo;
              if (novoPeriodo == PeriodoPartida.finalizada ||
                  novoPeriodo == PeriodoPartida.fechada) {
                _rodando = false;
                _timer?.cancel();
                _timerPausa?.cancel();
              }
            });
          }
        }
      },
    );

    _eventosChannel = _partidaService.subscribeRealtimeEventos(
      widget.partida.id,
      onInsert: (payload) {
        if (!mounted) return;
        // Atualizar eventos - a lista principal é atualizada por websockets
        _carregarEventosSalvos();
      },
    );
  }

  // Localize o método _carregarDadosIniciais e adicione _carregarEventosSalvos()
  Future<void> _carregarDadosIniciais() async {
    setState(() => _carregandoDados = true);

    try {
      // Atualizar o status da partida antes de carregar o resto para garantir que o _sincronizarCronometro funcione
      final partidaAtualizada = await _partidaService.buscarPartidaPorId(widget.partida.id);
      if (partidaAtualizada != null) {
        _periodoAtual = _converterStatusParaPeriodo(partidaAtualizada.status);
      }

      // Fase 1: carregar tipos de eventos, atletas e nomes em paralelo.
      await Future.wait([
        _buscarConfiguracoesDeEventos(),
        _carregarAtletas(),
        _carregarNomesEquipes(),
      ]);

      // Fase 2: carregar eventos — agora _tiposDeEventosDisponiveis e
      // _jogadoresA/_jogadoresB já estão preenchidos.
      await _carregarEventosSalvos();

      // Fase 3: Sincronizar cronômetro com os eventos ANTES de liberar a UI
      if (_periodoAtual == PeriodoPartida.aguardandoPenaltis ||
          (_periodoAtual == PeriodoPartida.pausada &&
              _periodoAntesDoPausa == PeriodoPartida.aguardandoPenaltis)) {
        if (mounted) {
          await _abrirTelaPenaltis();
        }
      } else {
        await _sincronizarCronometro();
        _initRealtimeListeners();
      }
    } catch (e) {
      debugPrint("Erro no carregamento inicial: $e");
    } finally {
      if (mounted) {
        setState(() => _carregandoDados = false);
      }
    }
  }

  // Crie o método para converter os dados do banco para o modelo do Feed
  Future<void> _carregarEventosSalvos() async {
    try {
      final rawEventos = await _partidaService.buscarEventosDaPartida(
        widget.partida.id,
      );

      _recuperarDadosPerdidosDosEventos(rawEventos);

      final listaConvertida = rawEventos
          .map((ev) {
            // A API retorna campos camelCase planos — sem objetos aninhados
            final tipoEventoId = ev['tipoEventoId']?.toString() ?? '';
            final atletaId = ev['atletaId']?.toString();
            final equipeId = ev['equipeId']?.toString();

            // Resolve o nome do tipo cruzando com a lista já carregada
            final tipoEvento = _tiposDeEventosDisponiveis
                .where((t) => t.id == tipoEventoId)
                .firstOrNull;
            final tipoNome = tipoEvento?.nome ?? tipoEventoId;

            // Resolve nome e número do atleta cruzando com os jogadores carregados
            Atleta? atleta;
            if (atletaId != null && atletaId.isNotEmpty) {
              atleta = [
                ..._jogadoresA,
                ..._jogadoresB,
                ..._reservasA,
                ..._reservasB,
              ].where((a) => a.atletaId == atletaId).firstOrNull;
            }

            // Determina cor pelo equipeId
            Color? corDinamica;
            if (equipeId != null) {
              corDinamica = equipeId == widget.partida.equipeAId
                  ? Colors.orange
                  : Colors.blue;
            }

            return EventoPartida(
              tipo: tipoNome,
              jogadorNome: atleta?.nome,
              jogadorNumero: atleta?.numero,
              corTime: corDinamica,
              horario: ev['tempoCronometro']?.toString() ?? '00:00',
              observacao: ev['descricaoDetalhada']?.toString() ?? '',
            );
          })
          .toList()
          .reversed
          .toList();

      setState(() {
        _eventosPartida.clear();
        _eventosPartida.addAll(listaConvertida);
      });
    } catch (e) {
      debugPrint("Erro ao carregar eventos salvos: $e");
    }
  }

  void _recuperarDadosPerdidosDosEventos(List<dynamic> rawEventos) {
    if (_periodoAtual == PeriodoPartida.naoIniciada) return;

    final eventosCronologicos = rawEventos.reversed.toList();

    int pausasTimeA1 = 0;
    int pausasTimeB1 = 0;
    int pausasTimeA2 = 0;
    int pausasTimeB2 = 0;

    int tempAcrescimo = 0;
    bool hasAcrescimo = false;

    int tempProrrogacao = 0;
    bool hasProrrogacao = false;

    for (var ev in eventosCronologicos) {
      // API retorna camelCase plano
      final tipoEventoId = ev['tipoEventoId']?.toString() ?? '';
      final tipoEvento = _tiposDeEventosDisponiveis
          .where((t) => t.id == tipoEventoId)
          .firstOrNull;
      final tipoNome = (tipoEvento?.nome ?? '').toUpperCase();
      final descricao = ev['descricaoDetalhada']?.toString() ?? '';
      final equipeId = ev['equipeId']?.toString() ?? '';
      final tempoJogo = _parseTempoCronometro(
        ev['tempoCronometro']?.toString() ?? '00:00',
      );

      if (tipoNome.contains('PAUSA_TECNICA')) {
        bool isTimeA = equipeId == widget.partida.equipeAId;
        if (tempoJogo <= _matchRules.duracaoPrimeiroTempoSegundos) {
          if (isTimeA) {
            pausasTimeA1++;
          } else {
            pausasTimeB1++;
          }
        } else {
          if (isTimeA) {
            pausasTimeA2++;
          } else {
            pausasTimeB2++;
          }
        }
      }

      if (tipoNome == 'ACRESCIMO_DADO') {
        final match = RegExp(r'(\d+)').firstMatch(descricao);
        if (match != null) {
          int minutos = int.parse(match.group(1)!);
          tempAcrescimo = minutos * 60;
          hasAcrescimo = true;
        }
      }

      if (tipoNome == 'PRORROGACAO_DADA') {
        final match = RegExp(r'(\d+)').firstMatch(descricao);
        if (match != null) {
          int minutos = int.parse(match.group(1)!);
          tempProrrogacao = minutos * 60;
          hasProrrogacao = true;
        }
      }
    }

    setState(() {
      _pausasTecnicasTimeAPrimeiroTempo = pausasTimeA1;
      _pausasTecnicasTimeBPrimeiroTempo = pausasTimeB1;
      _pausasTecnicasTimeASegundoTempo = pausasTimeA2;
      _pausasTecnicasTimeBSegundoTempo = pausasTimeB2;

      _tempoAcrescimo = tempAcrescimo;
      _temAcrescimo = hasAcrescimo;

      _tempoProrrogacao = tempProrrogacao;
      _temProrrogacao = hasProrrogacao;
    });
  }

  Future<void> _carregarNomesEquipes() async {
    try {
      final enriched = await _partidaService.carregarEquipesDaPartida(
        widget.partida,
      );
      if (!mounted) return;
      setState(() {
        _nomeTimeA = enriched.equipeA?.nome ?? _nomeTimeA;
        _nomeTimeB = enriched.equipeB?.nome ?? _nomeTimeB;
      });
    } catch (e) {
      debugPrint("Erro ao carregar nomes das equipes: $e");
    }
  }

  Future<void> _gerarPdfOficial() async {
    final id = widget.partida.id;

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
        name: 'Sumula_Oficial}.pdf',
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

  Future<void> _carregarAtletas() async {
    try {
      final resultados = await Future.wait([
        _partidaService.buscarInscritos(widget.partida.equipeAId),
        _partidaService.buscarInscritos(widget.partida.equipeBId),
      ]);
      _distribuirJogadores(resultados[0], true);
      _distribuirJogadores(resultados[1], false);
    } catch (e) {
      debugPrint("Erro ao carregar atletas: $e");
    }
  }

  void _distribuirJogadores(List<dynamic> inscritos, bool isTimeA) {
    // 1. Definição fixa das cores
    final corFixa = isTimeA ? Colors.orange : Colors.blue;

    List<Atleta> titulares = [];
    List<Atleta> reservas = [];

    for (var cada in inscritos) {
      // Transforma o Map da API em objeto Atleta
      final atleta = Atleta.fromMap(cada);

      // 2. Injeta a cor fixa no objeto para uso posterior no feed/detalhes
      atleta.corTime = corFixa;

      if (atleta.ativo == true) {
        titulares.add(atleta);
      } else {
        reservas.add(atleta);
      }
    }

    setState(() {
      if (isTimeA) {
        _jogadoresA = titulares;
        _reservasA = reservas;
        _posicionarJogadoresNoCampo(_jogadoresA, true);
      } else {
        _jogadoresB = titulares;
        _reservasB = reservas;
        _posicionarJogadoresNoCampo(_jogadoresB, false);
      }
    });
  }

  void _posicionarJogadoresNoCampo(List<Atleta> jogadores, bool isTimeA) {
    final posicoesA = [
      const Offset(0.03, 0.45),
      const Offset(0.20, 0.45),
      const Offset(0.30, 0.15),
      const Offset(0.30, 0.75),
      const Offset(0.35, 0.45),
    ];
    final posicoesB = [
      const Offset(0.87, 0.45),
      const Offset(0.73, 0.45),
      const Offset(0.65, 0.15),
      const Offset(0.65, 0.75),
      const Offset(0.57, 0.45),
    ];

    final listaPosicoes = isTimeA ? posicoesA : posicoesB;

    for (int i = 0; i < jogadores.length; i++) {
      if (i < listaPosicoes.length) {
        jogadores[i].posicao = listaPosicoes[i];
      }
    }
  }

  String _normalizarTexto(String? valor) {
    return (valor ?? '')
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('_', ' ');
  }

  bool get _ehEliminatoria =>
      _normalizarTexto(widget.partida.fase) == 'eliminatorias';

  bool get _precisaPenaltis => _ehEliminatoria && _golsA == _golsB;

  List<Atleta> _todosJogadores(List<Atleta> titulares, List<Atleta> reservas) {
    return [...titulares, ...reservas];
  }

  // Função auxiliar para o mapeamento
  PeriodoPartida _converterStatusParaPeriodo(String status) {
    switch (_normalizarTexto(status)) {
      case 'agendada':
        return PeriodoPartida.naoIniciada;
      case 'pausada':
        return PeriodoPartida.pausada;
      case '1° tempo':
        return PeriodoPartida.primeiroTempo;
      case '2° tempo':
        return PeriodoPartida.segundoTempo;
      case 'acréscimo':
        return PeriodoPartida.acrescimo;
      case 'intervalo':
        return PeriodoPartida.intervalo;
      case 'prorrogação':
        return PeriodoPartida.prorrogacao;
      case 'penaltis':
        return PeriodoPartida.aguardandoPenaltis;
      case 'finalizada':
        return PeriodoPartida.finalizada;
      case 'fechada':
        return PeriodoPartida.fechada;

      default:
        return PeriodoPartida.naoIniciada;
    }
  }

  String? _converterPeriodoParaStatus(PeriodoPartida periodo) {
    switch (periodo) {
      case PeriodoPartida.naoIniciada:
        return 'agendada';
      case PeriodoPartida.pausada:
        return 'pausada';
      case PeriodoPartida.primeiroTempo:
        return '1° tempo';
      case PeriodoPartida.intervalo:
        return 'intervalo';
      case PeriodoPartida.segundoTempo:
        return '2° tempo';
      case PeriodoPartida.prorrogacao:
        return 'prorrogação';
      case PeriodoPartida.acrescimo:
        return 'acréscimo';
      case PeriodoPartida.aguardandoPenaltis:
        return _statusAguardandoPenaltis;
      case PeriodoPartida.finalizada:
        return 'finalizada';
      case PeriodoPartida.fechada:
        return 'fechada';
    }
  }

  Future<void> _buscarConfiguracoesDeEventos() async {
    try {
      // Aqui carregamos configurações e regrasEfetivasJson simultaneamente
      final configModalidade = await _partidaService
          .buscarConfiguracaoModalidadeDaPartida(widget.partida.modalidadeId);

      if (configModalidade != null) {
        final rules = MatchRules.fromRegras(configModalidade);
        setState(() {
          _matchRules = rules;
        });
      }

      final tipos = await _partidaService.buscarTiposDeEventoDaPartida(
        widget.partida.modalidadeId,
      );
      setState(() {
        _tiposDeEventosDisponiveis = tipos;
      });
    } catch (e) {
      debugPrint('[_carregarDadosModalidade] Erro: $e');
    }
  }

  // Método para registrar eventos sistêmicos usando as IDs reais carregadas
  Future<void> _registrarEventoSistemico(
    String nomeEventoNoBanco, {
    String descricao = '',
    String? tempoOverride,
  }) async {
    debugPrint("REGISTRANDO EVENTO: $nomeEventoNoBanco");
    // 1. Tentar encontrar o tipo de evento na lista carregada
    final tipoEvento = _tiposDeEventosDisponiveis.firstWhere(
      (e) => e.codigo == nomeEventoNoBanco,
      orElse: () => TipoEventoEsporte(
        id: '',
        nome: nomeEventoNoBanco,
        modalidadeCatalogoId: '',
        idx: 0,
      ),
    );

    // 2. Registrar visualmente no feed
    final eventoFeed = EventoPartida(
      tipo:
          nomeEventoNoBanco, // O switch do descricao no modelo vai precisar lidar com isso
      jogadorNome: null,
      jogadorNumero: null,
      corTime: null,
      horario: tempoOverride ?? _formatarTempo(_segundos),
    );

    setState(() {
      _eventosPartida.insert(0, eventoFeed);
    });

    // 3. Salvar no Banco de Dados com a ID real
    if (tipoEvento.id.isNotEmpty) {
      debugPrint("SALVANDO EVENTO NO BANCO: ${tipoEvento.id}");
      await _partidaService.salvarEvento(
        descricao: descricao,
        partidaId: widget.partida.id,
        tipoEventoId: tipoEvento.id,
        tempoFormatado: tempoOverride ?? _formatarTempo(_segundos),
      );
    }
  }

  /// Registers an event WITH equipeId so it goes to /eventos (not /eventos-gerais)
  Future<void> _registrarEventoComEquipe(
    String nomeEventoNoBanco, {
    required String? equipeId,
    String descricao = '',
    String? tempoOverride,
  }) async {
    debugPrint(
      "REGISTRANDO EVENTO COM EQUIPE: $nomeEventoNoBanco equipeId=$equipeId",
    );
    final tipoEvento = _tiposDeEventosDisponiveis.firstWhere(
      (e) => e.codigo == nomeEventoNoBanco,
      orElse: () => TipoEventoEsporte(
        id: '',
        nome: nomeEventoNoBanco,
        modalidadeCatalogoId: '',
        idx: 0,
      ),
    );

    final eventoFeed = EventoPartida(
      tipo: nomeEventoNoBanco,
      jogadorNome: null,
      jogadorNumero: null,
      corTime: null,
      horario: tempoOverride ?? _formatarTempo(_segundos),
    );

    setState(() {
      _eventosPartida.insert(0, eventoFeed);
    });

    if (tipoEvento.id.isNotEmpty && equipeId != null && equipeId.isNotEmpty) {
      debugPrint(
        "SALVANDO EVENTO COM EQUIPE NO BANCO: ${tipoEvento.id} equipe=$equipeId",
      );
      await _partidaService.salvarEvento(
        descricao: descricao,
        partidaId: widget.partida.id,
        equipeId: equipeId,
        tipoEventoId: tipoEvento.id,
        tempoFormatado: tempoOverride ?? _formatarTempo(_segundos),
      );
    } else if (tipoEvento.id.isNotEmpty) {
      await _partidaService.salvarEvento(
        descricao: descricao,
        partidaId: widget.partida.id,
        tipoEventoId: tipoEvento.id,
        tempoFormatado: tempoOverride ?? _formatarTempo(_segundos),
      );
    }
  }

  // Variáveis para controle de prorrogação
  int _tempoProrrogacao = 0; // Em segundos
  bool _temProrrogacao = false;
  bool _estaNaProrrogacao = false;

  // Variáveis para controle de acrescimo
  int _tempoAcrescimo = 0; // Em segundos
  bool _temAcrescimo = false;
  bool _estaNoAcrescimo = false;

  // Controle de uso das pausas técnicas por período
  int _pausasTecnicasTimeAPrimeiroTempo = 0;
  int _pausasTecnicasTimeBPrimeiroTempo = 0;
  int _pausasTecnicasTimeASegundoTempo = 0;
  int _pausasTecnicasTimeBSegundoTempo = 0;
  String? _equipeIdEmPausaTecnica; // tracks which team requested the pause

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _timer?.cancel(); // Limpar timer ao sair da tela
    _timerPausa?.cancel(); // Limpar timer de pausa
    _timerPausaTecnica?.cancel(); // Limpar timer de pausa técnica
    _timerAcrescimo?.cancel(); // Limpar timer do acrescimo
    _timerProrrogacao?.cancel(); // Limpar timer da prorrogação
    _intervaloTimer?.cancel(); // Não esqueça de cancelar no dispose
    _partidaChannel?.unsubscribe();
    _eventosChannel?.unsubscribe();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sincronizarCronometro();
    }
  }

  /// Reconstrói o estado do cronômetro a partir do último evento salvo no banco
  Future<void> _sincronizarCronometro() async {
    // Só faz sentido sincronizar se a partida já começou
    if (_periodoAtual == PeriodoPartida.naoIniciada ||
        _periodoAtual == PeriodoPartida.aguardandoPenaltis ||
        _periodoAtual == PeriodoPartida.finalizada ||
        _periodoAtual == PeriodoPartida.fechada) {
      return;
    }

    final ultimoEvento = await _partidaService.buscarUltimoEventoComTempo(
      widget.partida.id,
    );

    if (!mounted) return;

    // Se não encontrou evento, mas a partida está pausada, mantém em 0
    if (ultimoEvento == null) {
      if (_periodoAtual == PeriodoPartida.pausada ||
          _periodoAtual == PeriodoPartida.intervalo) {
        _timer?.cancel();
        setState(() => _rodando = false);
      }
      return;
    }

    final int segundosAncora = _parseTempoCronometro(
      ultimoEvento['tempo_cronometro'].toString(),
    );

    final DateTime? timestampAncora = ultimoEvento['criado_em'] != null
        ? DateTime.tryParse(ultimoEvento['criado_em'].toString())
        : null;

    // Identifica pausa usando código (mais confiável) ou nome do tipo de evento
    final tipoId = ultimoEvento['tipo_evento_id']?.toString() ?? '';
    final tipoCodigo =
        ultimoEvento['tipo_evento_codigo']?.toString().toUpperCase() ?? '';
    final tipoEvento = _tiposDeEventosDisponiveis.firstWhere(
      (e) => e.id == tipoId,
      orElse: () =>
          TipoEventoEsporte(id: '', nome: '', modalidadeCatalogoId: '', idx: 0),
    );
    final rawNome = tipoEvento.nome.toUpperCase();

    final eventoIndicaPausa =
        tipoCodigo.contains('PAUSADA') ||
        tipoCodigo.contains('PAUSA') ||
        tipoCodigo.contains('INTERVALO') ||
        tipoCodigo.contains('FIM_') ||
        rawNome.contains('PAUSADA') ||
        rawNome.contains('PAUSA_TECNICA') ||
        rawNome.contains('INTERVALO') ||
        rawNome.contains('FIM_');

    final partidaPausada =
        _periodoAtual == PeriodoPartida.pausada ||
        _periodoAtual == PeriodoPartida.intervalo;

    final periodoEfetivo = _periodoAtual == PeriodoPartida.pausada
        ? (_periodoAntesDoPausa ?? _periodoAtual)
        : _periodoAtual;

    if (partidaPausada || eventoIndicaPausa) {
      // Partida estava pausada: congela no tempo do evento
      _timer?.cancel();
      setState(() {
        _rodando = false;
        _segundos = segundosAncora;
      });
      debugPrint(
        '[Cronômetro] Sincronizado PAUSADO em ${_formatarTempo(segundosAncora)}',
      );
    } else {
      // Partida estava rodando: recalcula considerando o tempo passado
      // Só possível se temos o timestamp do último evento
      if (timestampAncora == null) {
        // Sem timestamp: congela no último tempo conhecido
        _timer?.cancel();
        setState(() {
          _rodando = false;
          _segundos = segundosAncora;
        });
        debugPrint(
          '[Cronômetro] Sem timestamp — congelado em ${_formatarTempo(segundosAncora)}',
        );
        return;
      }

      final segundosDecorridos = DateTime.now()
          .toUtc()
          .difference(timestampAncora.toUtc())
          .inSeconds;

      int segundosRecuperados = segundosAncora + segundosDecorridos;

      // Não ultrapassa o limite do período se não há acréscimo
      if (periodoEfetivo == PeriodoPartida.primeiroTempo &&
          segundosRecuperados > _matchRules.duracaoPrimeiroTempoSegundos &&
          !_temAcrescimo) {
        segundosRecuperados = _matchRules.duracaoPrimeiroTempoSegundos;
      } else if (periodoEfetivo == PeriodoPartida.segundoTempo &&
          segundosRecuperados > _matchRules.duracaoSegundoTempoSegundos &&
          !_temAcrescimo) {
        segundosRecuperados = _matchRules.duracaoSegundoTempoSegundos;
      }

      _timer?.cancel();
      _timerPausa?.cancel();
      setState(() {
        _rodando = true;
        _segundos = segundosRecuperados;
        _partidaJaIniciou = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _segundos++);
          _verificarFimPeriodo();
        }
      });
      debugPrint(
        '[Cronômetro] Sincronizado RODANDO em ${_formatarTempo(segundosRecuperados)}',
      );
    }
  }

  /// Converte "MM:SS" → total em segundos
  int _parseTempoCronometro(String tempo) {
    final partes = tempo.split(':');
    if (partes.length != 2) return 0;
    final min = int.tryParse(partes[0]) ?? 0;
    final seg = int.tryParse(partes[1]) ?? 0;
    return min * 60 + seg;
  }

  // Verifica se deve finalizar período automaticamente
  void _verificarFimPeriodo() {
    switch (_periodoAtual) {
      case PeriodoPartida.primeiroTempo:
        if (_segundos >= _matchRules.duracaoPrimeiroTempoSegundos) {
          if (_temAcrescimo && !_estaNoAcrescimo) {
            _iniciarAcrescimo();
          } else {
            _finalizarPrimeiroTempo();
          }
        }
        break;
      case PeriodoPartida.segundoTempo:
        if (_segundos >= _matchRules.duracaoSegundoTempoSegundos) {
          // 1º Prioridade: Se tem acréscimo e ainda não iniciou, inicia o acréscimo
          if (_temAcrescimo && !_estaNoAcrescimo) {
            _iniciarAcrescimo();
          }
          // 2º Prioridade: Se não tem acréscimo (ou já acabou) e tem prorrogação finaliza o segundo tempo para zerar cronometro e começar a prorrogação assim que arbitro despausar
          else if (_temProrrogacao && !_estaNaProrrogacao) {
            _finalizarSegundoTempo();
          }
          // 3º Prioridade: Finaliza se não houver mais nada pendente
          else {
            _finalizarPartida();
          }
        }
        break;
      case PeriodoPartida.acrescimo:
        // Se os segundos contados atingirem o tempo definido no modal
        if (_segundos >= _tempoAcrescimo) {
          _timer?.cancel();
          setState(() {
            _rodando = false;
          });
          if (_periodoAntesDoAcrescimo == PeriodoPartida.primeiroTempo) {
            _finalizarPrimeiroTempo();
          } else if (_periodoAntesDoAcrescimo == PeriodoPartida.segundoTempo &&
              _temProrrogacao &&
              !_estaNaProrrogacao) {
            _finalizarSegundoTempo();
          }
          // 3º Prioridade: Finaliza se não houver mais nada pendente
          else {
            _finalizarPartida();
          }
        }
        break;
      case PeriodoPartida.prorrogacao:
        if (_segundos >= _tempoProrrogacao) {
          _finalizarPartida();
        }
        break;
      default:
        break;
    }
  }

  void _iniciarTimerIntervalo() {
    _intervaloTimer?.cancel();
    setState(() {
      _segundosIntervalo = 0;
    });

    _intervaloTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_periodoAtual == PeriodoPartida.intervalo) {
        setState(() {
          _segundosIntervalo++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  // Inicia período de prorrogação
  void _iniciarProrrogacao() {
    _timer?.cancel();
    setState(() {
      _rodando = true;
      _estaNaProrrogacao = true;
      _periodoAtual = PeriodoPartida.prorrogacao;
      _segundos = 0; // Reset do cronômetro para a prorrogação
    });

    _partidaService.atualizarPartida(
      widget.partida.id,
      novoStatus: 'prorrogação',
    );
  }

  // Inicia período de prorrogação
  void _iniciarAcrescimo() {
    _timer?.cancel(); // Cancela qualquer timer ativo

    final novoTempoAcrescimo =
        _segundos + _tempoAcrescimo; // captura o valor atual

    setState(() {
      _periodoAntesDoAcrescimo = _periodoAtual;
      _rodando = true;
      _estaNoAcrescimo = true;
      _periodoAtual = PeriodoPartida.acrescimo;
      _tempoAcrescimo = novoTempoAcrescimo;
    });

    // Inicia o contador
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _segundos++); // só incrementa
        _verificarFimPeriodo(); // fora do setState
      }
    });

    _partidaService.atualizarPartida(
      widget.partida.id,
      novoStatus: 'acréscimo',
    );

    _registrarEventoSistemico('ACRESCIMO');
  }

  void _finalizarPrimeiroTempo() {
    _timer?.cancel();
    _timerPausa?.cancel();

    setState(() {
      _rodando = false;
      _periodoAtual = PeriodoPartida.intervalo;
      _periodoAntesDoPausa = PeriodoPartida.primeiroTempo;
      _temAcrescimo = false;
      _tempoAcrescimo = 0;
      _estaNoAcrescimo = false;
    });

    _partidaService.atualizarPartida(
      widget.partida.id,
      novoStatus: 'intervalo',
    );
    _registrarEventoSistemico('FIM_1_TEMPO');

    if (_temProrrogacao) {
      _registrarEventoSistemico('INTERVALO');
      // 🔥 DISPARA O CRONÔMETRO DE INTERVALO AQUI
      _iniciarTimerIntervalo();
    }
  }

  // Finaliza o segundo tempo e a partida
  void _finalizarPartida() {
    _timer?.cancel();
    _timerPausa?.cancel();

    final precisaPenaltis = _precisaPenaltis;

    setState(() {
      _rodando = false;
      _periodoAtual = precisaPenaltis
          ? PeriodoPartida.aguardandoPenaltis
          : PeriodoPartida.finalizada;
    });

    _partidaService.atualizarPartida(
      widget.partida.id,
      novoStatus: precisaPenaltis ? _statusAguardandoPenaltis : 'finalizada',
    );

    if (precisaPenaltis) {
      _registrarEventoSistemico('PENALTI');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _abrirTelaPenaltis();
      });
      return;
    }

    _registrarEventoSistemico('FIM_PARTIDA');
  }

  void _finalizarSegundoTempo() {
    _timer?.cancel();
    _timerPausa?.cancel();

    setState(() {
      _rodando = false;
      _periodoAtual = PeriodoPartida.intervalo;
      _periodoAntesDoPausa = PeriodoPartida.segundoTempo;
      _estaNoAcrescimo = false;
      _tempoAcrescimo = 0;
      _temAcrescimo = false;
    });

    _partidaService.atualizarPartida(
      widget.partida.id,
      novoStatus: 'intervalo',
    );
    _registrarEventoSistemico('FIM_2_TEMPO');

    _registrarEventoSistemico('INTERVALO');
    _iniciarTimerIntervalo();
  }

  // Abre modal para selecionar tempo de prorrogação
  void _abrirModalProrrogacao() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Definir Prorrogação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite o tempo de prorrogação em minutos:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutos',
                border: OutlineInputBorder(),
                hintText: 'Ex: 5, 10, 15...',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final String input = controller.text.trim();
              final int? minutos = int.tryParse(input);

              if (minutos == null || minutos <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Por favor, digite um número válido de minutos!',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              _registrarEventoSistemico(
                'PRORROGACAO_DADA',
                descricao: 'Prorrogação de $minutos minutos definida!',
              );

              setState(() {
                _tempoProrrogacao = minutos * 60; // Converter para segundos
                _temProrrogacao = true;
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Prorrogação de $minutos minutos configurada com sucesso!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // Abre modal para selecionar tempo de prorrogação
  void _abrirModalAcrescimo() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Definir Acrescimo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite o tempo de acrescimo em minutos:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutos',
                border: OutlineInputBorder(),
                hintText: 'Ex: 5, 10, 15...',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final String input = controller.text.trim();
              final int? minutos = int.tryParse(input);

              if (minutos == null || minutos <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Por favor, digite um número válido de minutos!',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              _registrarEventoSistemico(
                'ACRESCIMO_DADO',
                descricao: 'Acrescimo de $minutos minutos definido!',
              );

              setState(() {
                _tempoAcrescimo = minutos * 60; // Converter para segundos
                _temAcrescimo = true;
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Acrescimo de $minutos minutos configurada com sucesso!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // Verifica se o time ainda pode usar pausa técnica no período atual
  bool _podeUsarPausaTecnica(bool isTimeA) {
    switch (_periodoAtual) {
      case PeriodoPartida.primeiroTempo:
      case PeriodoPartida.prorrogacao:
        return isTimeA
            ? _pausasTecnicasTimeAPrimeiroTempo < 1
            : _pausasTecnicasTimeBPrimeiroTempo < 1;
      case PeriodoPartida.segundoTempo:
        return isTimeA
            ? _pausasTecnicasTimeASegundoTempo < 1
            : _pausasTecnicasTimeBSegundoTempo < 1;
      default:
        return false;
    }
  }

  // Inicia pausa técnica para um time
  void _iniciarPausaTecnica(bool isTimeA) {
    // 1. Pegar nomes corretos das equipes de dentro do objeto partida
    final nomeTimeA = _nomeTimeA;
    final nomeTimeB = _nomeTimeB;

    // Verificações de segurança
    if (_emPausaTecnica) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Já há uma pausa técnica em andamento!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_podeUsarPausaTecnica(isTimeA)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${isTimeA ? nomeTimeA : nomeTimeB} já usou sua pausa técnica neste período!",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Pausar cronometro principal se estiver rodando
    if (_rodando) {
      _timer?.cancel();
      setState(() {
        _rodando = false;
      });
    }

    _periodoAntesDoPausa = _periodoAtual;

    // Iniciar pausa técnica
    setState(() {
      _periodoAtual = PeriodoPartida.pausada;
      _emPausaTecnica = true;
      _timeEmPausaTecnica = isTimeA ? nomeTimeA : nomeTimeB;
      _segundosPausaTecnica = 0;
    });

    // Incrementar contador do time no período atual
    switch (_periodoAtual) {
      case PeriodoPartida.primeiroTempo:
      case PeriodoPartida.prorrogacao:
        if (isTimeA) {
          _pausasTecnicasTimeAPrimeiroTempo++;
        } else {
          _pausasTecnicasTimeBPrimeiroTempo++;
        }
        break;
      case PeriodoPartida.segundoTempo:
        if (isTimeA) {
          _pausasTecnicasTimeASegundoTempo++;
        } else {
          _pausasTecnicasTimeBSegundoTempo++;
        }
        break;
      default:
        break;
    }

    final String equipeIdPausa = isTimeA
        ? widget.partida.equipeAId
        : widget.partida.equipeBId;
    _equipeIdEmPausaTecnica = equipeIdPausa;

    _registrarEventoComEquipe(
      'PAUSA_TECNICA',
      equipeId: equipeIdPausa,
      descricao:
          'Pausa técnica iniciada para os ${isTimeA ? nomeTimeA : nomeTimeB}!',
    );

    // Timer de 1 minuto (60 segundos) para pausa técnica
    _timerPausaTecnica = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _segundosPausaTecnica++); // só incrementa
        if (_segundosPausaTecnica >= 60) {
          _finalizarPausaTecnica(); // fora do setState
        }
      }
    });
  }

  // Finaliza pausa técnica manualmente ou automaticamente
  void _finalizarPausaTecnica() {
    _timerPausaTecnica?.cancel();

    setState(() {
      _emPausaTecnica = false;
    });

    _timeEmPausaTecnica = '';
    _segundosPausaTecnica = 0;

    debugPrint("PAUSA TECNICA FINALIZADA");

    unawaited(
      _partidaService.atualizarPartida(
        widget.partida.id,
        novoStatus: 'pausada',
        periodoAntesPausa: _periodoAntesDoPausa == null
            ? null
            : _converterPeriodoParaStatus(_periodoAntesDoPausa!),
      ),
    );

    _registrarEventoComEquipe(
      'FIM_PAUSA_TECNICA',
      equipeId: _equipeIdEmPausaTecnica,
    );
    _equipeIdEmPausaTecnica = null;
  }

  Future<void> _alternarCronometro() async {
    // DEFINI QUAL O PROXIMO ESTADO DO CRONOMETRO (RODANDO OU PARADO)
    final bool novoRodando = !_rodando;

    // DEFINI QUAL O EVENTO QUE SERA REGISTRADO NO BANCO
    String? eventoParaRegistrar;
    String? tempoEvento;

    // DEFINI QUAL O SERVIÇO QUE SERA EXECUTADO
    Future<void> Function()? atualizarServico;

    // VAI COMEÇAR A RODAR
    if (novoRodando) {
      switch (_periodoAtual) {
        case PeriodoPartida.naoIniciada:
          eventoParaRegistrar = 'INICIO_1_TEMPO';
          tempoEvento = '00:00';
          atualizarServico = () =>
              _partidaService.startPartida(widget.partida.id);
          break;
        case PeriodoPartida.pausada:
          // Retoma para o período anterior à pausa (ex.: 2° tempo)
          final statusRetomar = _periodoAntesDoPausa == null
              ? null
              : _converterPeriodoParaStatus(_periodoAntesDoPausa!);
          if (statusRetomar != null) {
            atualizarServico = () => _partidaService.atualizarPartida(
              widget.partida.id,
              novoStatus: statusRetomar,
            );
          }
          eventoParaRegistrar = 'PARTIDA_RETOMADA';
          tempoEvento = _formatarTempo(_segundos);
          break;
        case PeriodoPartida.intervalo:
          debugPrint('AA intervalo');
          if (_periodoAntesDoPausa == PeriodoPartida.primeiroTempo) {
            eventoParaRegistrar = 'INICIO_2_TEMPO';
            tempoEvento = _formatarTempo(
              _matchRules.duracaoPrimeiroTempoSegundos,
            );
            atualizarServico = () => _partidaService.atualizarPartida(
              widget.partida.id,
              novoStatus: '2° tempo',
            );
          } else if (_periodoAntesDoPausa == PeriodoPartida.segundoTempo) {
            _iniciarProrrogacao();
            eventoParaRegistrar = 'PRORROGACAO';
            tempoEvento = '00:00';
            atualizarServico = () => _partidaService.atualizarPartida(
              widget.partida.id,
              novoStatus: 'prorrogação',
            );
          }
          break;
        default:
          eventoParaRegistrar = 'PARTIDA_RETOMADA';
          tempoEvento = _formatarTempo(_segundos);
          break;
      }
      // VAI PARAR
    } else {
      if (_periodoAtual != PeriodoPartida.finalizada &&
          _periodoAtual != PeriodoPartida.fechada &&
          !_emPausaTecnica) {
        _periodoAntesDoPausa = _periodoAtual;

        atualizarServico = () => _partidaService.atualizarPartida(
          widget.partida.id,
          novoStatus: 'pausada',
          periodoAntesPausa: _periodoAntesDoPausa == null
              ? null
              : _converterPeriodoParaStatus(_periodoAntesDoPausa!),
        );

        eventoParaRegistrar = 'PARTIDA_PAUSADA';
        tempoEvento = _formatarTempo(_segundos);
      }
    }

    // APENAS mutações síncronas (sem async, sem timers, sem serviços)
    setState(() {
      _rodando = novoRodando;

      if (novoRodando) {
        switch (_periodoAtual) {
          case PeriodoPartida.naoIniciada:
            _periodoAtual = PeriodoPartida.primeiroTempo;
            _segundos = 0;

            break;
          case PeriodoPartida.pausada:
            if (_periodoAntesDoPausa != null) {
              _periodoAtual = _periodoAntesDoPausa!;
            }
            break;

          case PeriodoPartida.intervalo:
            if (_periodoAntesDoPausa == PeriodoPartida.primeiroTempo) {
              _periodoAtual = PeriodoPartida.segundoTempo;
              _segundos = _matchRules.duracaoPrimeiroTempoSegundos;
            }

            break;

          default:
            break;
        }
      } else {
        if (_periodoAtual != PeriodoPartida.finalizada &&
            _periodoAtual != PeriodoPartida.fechada) {
          _periodoAtual = PeriodoPartida.pausada;
        }
      }
    });

    // ✅ 3. Side effects FORA do setState
    if (novoRodando) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() => _segundos++); // só incrementa
          _verificarFimPeriodo(); // fora do setState
        }
      });
      _timerPausa?.cancel();
      _partidaJaIniciou = true;
    } else {
      _timer?.cancel();
      if (_periodoAtual != PeriodoPartida.finalizada &&
          _periodoAtual != PeriodoPartida.fechada &&
          !_emPausaTecnica) {
        _timerPausa = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) setState(() => _segundosPausa++);
        });
      }
    }

    // ✅ AWAIT no status ANTES de registrar o evento
    // Garante que o backend já tem o status atualizado quando o evento chegar
    if (atualizarServico != null) {
      await atualizarServico();
    }

    if (eventoParaRegistrar != null) {
      _registrarEventoSistemico(
        eventoParaRegistrar,
        tempoOverride: tempoEvento,
      );
    }
  }

  Future<void> _abrirTelaPenaltis() async {
    if (!mounted) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EliminatoriasPostMatchScreen(
          partida: widget.partida,
          timeA: _nomeTimeA,
          timeB: _nomeTimeB,
          golsA: _golsA,
          golsB: _golsB,
          jogadoresA: _todosJogadores(_jogadoresA, _reservasA),
          jogadoresB: _todosJogadores(_jogadoresB, _reservasB),
          partidaService: _partidaService,
        ),
      ),
    );
  }

  // Função para contar estatísticas do jogador em tempo real
  Map<String, int> _obterEstatisticasJogador(String nomeJogador) {
    int gols = 0;
    int faltas = 0;
    int cartoesAmarelos = 0;
    int cartoesVermelhos = 0;

    for (var evento in _eventosPartida) {
      if (evento.jogadorNome == nomeJogador) {
        final tipo = evento.tipo.toLowerCase();

        if (tipo.contains('gol')) gols++;
        if (tipo.contains('falta')) faltas++;
        if (tipo.contains('cartao amarelo')) cartoesAmarelos++;
        if (tipo.contains('cartao vermelho')) cartoesVermelhos++;
      }
    }

    return {
      'gols': gols,
      'faltas': faltas,
      'amarelos': cartoesAmarelos,
      'vermelhos': cartoesVermelhos,
    };
  }

  Future<void> _registrarEvento(TipoEventoEsporte tipoObjeto) async {
    // 1. Validações de Estado da Partida
    if (_periodoAtual == PeriodoPartida.naoIniciada) {
      _mostrarAviso("Inicie a partida primeiro!", Colors.orange);
      return;
    }

    if (_periodoAtual == PeriodoPartida.finalizada ||
        _periodoAtual == PeriodoPartida.fechada) {
      _mostrarAviso("Partida já encerrada!", Colors.red);
      return;
    }

    if (_periodoAtual == PeriodoPartida.intervalo) {
      _mostrarAviso("Não é possível registrar no intervalo!", Colors.blue);
      return;
    }

    if (!tipoObjeto.isEventoDePartida && _jogadorSelecionado == null) {
      _mostrarAviso("Selecione um jogador no campo primeiro!", Colors.red);
      return;
    }

    final String nomeEvento = tipoObjeto.nome.trim();
    final String tempoFormatado = _formatarTempo(_segundos);

    if (nomeEvento.toLowerCase() == "substituição") {
      _abrirModalSubstituicaoNovo();
      return;
    }

    final observacao = await _solicitarObservacaoEvento(
      tituloEvento: tipoObjeto.nomeFormatado,
      nomeJogador: _jogadorSelecionado?.nome,
    );

    if (!mounted) return;
    if (observacao == null) return;

    final jogador = _jogadorSelecionado;
    final isTimeA = jogador != null ? _jogadoresA.contains(jogador) : false;

    final novoEventoFeed = EventoPartida(
      tipo: tipoObjeto.nomeFormatado,
      corTime: jogador?.corTime ?? Colors.grey,
      jogadorNome: jogador?.nome,
      jogadorNumero: jogador?.numero,
      horario: tempoFormatado,
      observacao: observacao,
    );

    setState(() {
      if (tipoObjeto.impactaPlacar) {
        final pontosPro = tipoObjeto.pontosPro ?? 1;
        final pontosContra = tipoObjeto.pontosContra ?? 0;

        if (isTimeA) {
          _golsA += pontosPro;
          _golsB += pontosContra;
        } else if (jogador != null) {
          _golsB += pontosPro;
          _golsA += pontosContra;
        }
      }

      _eventosPartida.insert(0, novoEventoFeed);
      _jogadorSelecionado = null;
    });

    final String? equipeIdCorreta = jogador?.equipeId ??
        (jogador != null ? (isTimeA ? widget.partida.equipeAId : widget.partida.equipeBId) : null);

    await _partidaService.salvarEvento(
      partidaId: widget.partida.id,
      equipeId: equipeIdCorreta,
      tipoEventoId: tipoObjeto.id,
      tempoFormatado: tempoFormatado,
      atletaId: jogador?.atletaId,
      descricao: observacao,
    );

    final sufixoObservacao = observacao.trim().isEmpty
        ? ''
        : ' • Observação adicionada';

    final nomeExibicao = jogador?.nome != null ? "${jogador?.nome} (#${jogador?.numero})" : "Partida";
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${tipoObjeto.nomeFormatado} registrado: $nomeExibicao$sufixoObservacao",
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Helper simples para reduzir repetição de código nas validações
  void _mostrarAviso(String mensagem, Color cor) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem), backgroundColor: cor));
  }

  String _formatarTempo(int totalSegundos) {
    int min = totalSegundos ~/ 60;
    int seg = totalSegundos % 60;
    return '${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }

  Future<String?> _solicitarObservacaoEvento({
    required String tituloEvento,
    String? nomeJogador,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ObservacaoEventoModal(
        tituloEvento: tituloEvento,
        nomeJogador: nomeJogador,
      ),
    );
  }

  void _abrirDetalhesJogador(Atleta jogador) {
    // Obtém as estatísticas dinâmicas
    final stats = _obterEstatisticasJogador(jogador.nome);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(
        0xFF2D2D2D,
      ), // Fundo escuro para combinar com o app
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header com Avatar e Número
            CircleAvatar(
              radius: 45,
              backgroundColor: (jogador.corTime ?? Colors.grey).withValues(alpha: 0.2),
              child: Text(
                "#${jogador.numero}",
                style: TextStyle(
                  fontSize: 28,
                  color: jogador.corTime ?? Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              jogador.nome,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.circle, size: 10, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  "EM CAMPO",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: Colors.white10),
            ),

            // Grade de Estatísticas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoStat(
                  "Gols",
                  stats['gols'].toString(),
                  Icons.sports_soccer,
                  Colors.white,
                ),
                _infoStat(
                  "Faltas",
                  stats['faltas'].toString(),
                  Icons.warning_amber_rounded,
                  Colors.orange,
                ),
                _infoStat(
                  "C. Amarelo",
                  stats['amarelos'].toString(),
                  Icons.style,
                  Colors.yellow,
                ),
                _infoStat(
                  "C. Vermelho",
                  stats['vermelhos'].toString(),
                  Icons.style,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoStat(String label, String valor, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color.withValues(alpha: 0.8), size: 20),
        const SizedBox(height: 8),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
        ),
      ],
    );
  }

  // MOSTRA DIÁLOGO DE CONFIRMAÇÃO PARA SAIR DURANTE PARTIDA
  void _mostrarDialogoSaida() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 10),
              Text(
                'Partida em Andamento',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: const Text(
            'A partida está em andamento! Para sair, você deve pausar o cronômetro primeiro.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBotaoVoltar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Permite voltar da tela se a partida estiver finalizada ou não estiver rolando
          if (_periodoAtual == PeriodoPartida.finalizada ||
              _periodoAtual == PeriodoPartida.fechada ||
              !_rodando) {
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Não é possível sair com a partida em andamento!",
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D2D2D),
          padding: const EdgeInsets.all(16),
        ),
        child: Text(
          _periodoAtual == PeriodoPartida.finalizada ||
                  _periodoAtual == PeriodoPartida.fechada
              ? "Voltar"
              : _rodando
              ? "Pause para sair"
              : "Voltar",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _visualizarSumulaOficialAtual() async {
    if (widget.partida.id.isEmpty) {
      await _gerarPdfOficial();
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
      final bytes = await _partidaService.baixarSumulaOficialPdf(
        widget.partida.id,
      );
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Sumula_Oficial_${_nomeTimeA}_x_$_nomeTimeB.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível gerar a súmula oficial: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_rodando, // Só permite voltar se a partida não estiver rolando
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) {
        if (!didPop && _rodando) {
          _mostrarDialogoSaida();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 1. Fundo com Gradiente (Sempre visível)
            const GradientBackground(),

            // Se estiver carregando, mostra o Skeleton, senão mostra o jogo
            _carregandoDados
                ? _buildLoadingState()
                : // 2. Conteúdo Principal da UI
                  SafeArea(
                    child: Opacity(
                      // Se estiver carregando, a UI fica semi-transparente
                      opacity: _carregandoDados ? 0.3 : 1.0,
                      child: IgnorePointer(
                        // Se estiver carregando, bloqueia cliques em tudo
                        ignoring: _carregandoDados,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),

                              // Placar
                              GameScoreboard(
                                timeA: _nomeTimeA,
                                timeB: _nomeTimeB,
                                escudoA:
                                    widget.partida.equipeA?.atleticaEscudoUrl,
                                escudoB:
                                    widget.partida.equipeB?.atleticaEscudoUrl,
                                golsA: _golsA,
                                golsB: _golsB,
                                periodoAtual: _periodoAtual,
                                emPausaTecnica: _emPausaTecnica,
                                rodando: _rodando,
                                timeEmPausaTecnica: _timeEmPausaTecnica,
                                segundosPausaTecnica: _segundosPausaTecnica,
                                podeUsarPausaTecnica: _podeUsarPausaTecnica,
                                onPausaTecnicaIniciada: _iniciarPausaTecnica,
                                onPausaTecnicaFinalizada:
                                    _finalizarPausaTecnica,
                              ),

                              const SizedBox(height: 12),

                              // Feed de Eventos
                              GameEventsFeed(eventos: _eventosPartida),

                              const SizedBox(height: 12),

                              // Card do Cronómetro e Controles de Tempo
                              GameTimerCard(
                                segundos: _segundos,
                                rodando: _rodando,
                                partidaJaIniciou: _partidaJaIniciou,
                                periodoAtual: _periodoAtual,
                                emPausaTecnica: _emPausaTecnica,
                                timeEmPausaTecnica: _timeEmPausaTecnica,
                                segundosPausaTecnica: _segundosPausaTecnica,
                                segundosPausa: _segundosPausa,
                                tempoProrrogacao: _tempoProrrogacao,
                                temProrrogacao: _temProrrogacao,
                                temAcrescimo: _temAcrescimo,
                                tempoAcrescimo: _tempoAcrescimo,
                                onToggleCronometro: _alternarCronometro,
                                onFinalizarPrimeiroTempo:
                                    _finalizarPrimeiroTempo,
                                onFinalizarSegundoTempo: () {
                                  if (_temProrrogacao && !_estaNaProrrogacao) {
                                    _finalizarSegundoTempo();
                                  } else {
                                    _finalizarPartida();
                                  }
                                },
                                onAbrirModalProrrogacao: _abrirModalProrrogacao,
                                onAbrirModalAcrescimo: _abrirModalAcrescimo,
                                segundosIntervalo: _segundosIntervalo,
                              ),

                              const SizedBox(height: 16),

                              // Campo de Jogo com Jogadores
                              GameField(
                                jogadoresA: _jogadoresA,
                                jogadoresB: _jogadoresB,
                                jogadorSelecionado: _jogadorSelecionado,
                                onJogadorSelecionado: (jogador) {
                                  if (_periodoAtual ==
                                          PeriodoPartida.finalizada ||
                                      _periodoAtual == PeriodoPartida.fechada) {
                                    return;
                                  }
                                  setState(() => _jogadorSelecionado = jogador);
                                },
                                onJogadorDoubleTap: (j) {
                                  if (_periodoAtual ==
                                          PeriodoPartida.finalizada ||
                                      _periodoAtual == PeriodoPartida.fechada) {
                                    return;
                                  }
                                  _abrirDetalhesJogador(j);
                                },
                              ),

                              const SizedBox(height: 16),

                              // Painel de Ações (Gols, Cartões, etc)
                              GameActionsPanel(
                                jogadorSelecionado: _jogadorSelecionado,
                                periodoAtual: _periodoAtual,
                                onRegistrarEvento: _registrarEvento,
                                tiposDeEventos: _tiposDeEventosDisponiveis,
                              ),

                              const SizedBox(height: 20),

                              // Botão Gerar Súmula (Só aparece no fim)
                              if (_periodoAtual == PeriodoPartida.finalizada ||
                                  _periodoAtual == PeriodoPartida.fechada) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              MatchSummaryScreen(
                                                timeA: _nomeTimeA,
                                                timeB: _nomeTimeB,
                                                escudoA: widget
                                                    .partida
                                                    .equipeA
                                                    ?.atleticaEscudoUrl,
                                                escudoB: widget
                                                    .partida
                                                    .equipeB
                                                    ?.atleticaEscudoUrl,
                                                golsA: _golsA,
                                                golsB: _golsB,
                                                eventos: _eventosPartida,
                                                partidaId: widget.partida.id,
                                                partidaService: _partidaService,
                                              ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.analytics),
                                        SizedBox(width: 8),
                                        Text(
                                          'VER RESUMO DA PARTIDA',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // No Column do build, após o GameTimerCard:
                              const SizedBox(height: 12),

                              if (_partidaJaIniciou &&
                                  _periodoAtual != PeriodoPartida.finalizada &&
                                  _periodoAtual != PeriodoPartida.fechada)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: SizedBox(
                                    width: double
                                        .infinity, // Garante que o botão ocupe a largura total
                                    child: ElevatedButton.icon(
                                      onPressed: _visualizarSumulaOficialAtual,
                                      icon: const Icon(
                                        Icons.picture_as_pdf,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        "VISUALIZAR SÚMULA ATUAL",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF2D2D2D,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              if (_partidaJaIniciou &&
                                  _periodoAtual != PeriodoPartida.finalizada &&
                                  _periodoAtual != PeriodoPartida.fechada)
                                const SizedBox(height: 30),

                              // Botão Sair/Voltar dinâmico
                              _buildBotaoVoltar(),

                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // --- NOVO MODAL DE SUBSTITUIÇÃO REFINADO ---
  void _abrirModalSubstituicaoNovo() {
    final jogadorSaindo = _jogadorSelecionado!;
    final isTimeA = _jogadoresA.contains(jogadorSaindo);
    final reservas = isTimeA ? _reservasA : _reservasB;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Color(0xFF2D2D2D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Barra de arraste
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header do Modal
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SUBSTITUIÇÃO", // Nome do evento conforme events.txt
                        style: TextStyle(
                          color: Color(0xFF00FFC2),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        // Acessando o nome da equipe corretamente através do modelo da partida
                        isTimeA ? _nomeTimeA : _nomeTimeB,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
            ),

            // Jogador que está saindo (UI em destaque)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(15),
                // ignore: deprecated_member_use
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.logout, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Text(
                    "SAINDO:",
                    style: TextStyle(
                      // ignore: deprecated_member_use
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${jogadorSaindo.nome} (#${jogadorSaindo.numero})",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      softWrap: true, // Permite quebra de linha
                      maxLines:
                          2, // Permite até 2 linhas antes de qualquer outro tratamento
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(top: 24, bottom: 12),
              child: Text(
                "SELECIONE QUEM ENTRA",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Lista de Reservas Animada
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: reservas.length,
                itemBuilder: (context, index) {
                  final reserva = reservas[index];
                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: _buildReservaCard(reserva, jogadorSaindo),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservaCard(Atleta reserva, Atleta saindo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _confirmarSubstituicao(saindo, reserva);
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              // ignore: deprecated_member_use
              colors: [
                (reserva.corTime ?? Colors.grey).withValues(alpha: 0.2),
                Colors.white10,
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: reserva.corTime,
                radius: 18,
                child: Text(
                  "${reserva.numero}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Text(
                reserva.nome,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.login, color: Color(0xFF00FFC2), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placar fake
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FFC2)),
            ),
          ),
          const SizedBox(height: 20),
          // Texto de status
          Text(
            "PREPARANDO CAMPO...",
            style: TextStyle(
              color: const Color.fromARGB(255, 39, 39, 39).withValues(alpha: 0.5),
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarSubstituicao(Atleta saindo, Atleta entrando) async {
    final observacao = await _solicitarObservacaoEvento(
      tituloEvento: 'Substituição',
      nomeJogador: '${saindo.nome} ↔ ${entrando.nome}',
    );

    if (!mounted) return;
    if (observacao == null) return;

    final isA = _jogadoresA.contains(saindo);
    final listTitulares = isA ? _jogadoresA : _jogadoresB;
    final listReservas = isA ? _reservasA : _reservasB;
    final equipeIdCorreta = isA
        ? widget.partida.equipeAId
        : widget.partida.equipeBId;
    final tempoFormatado = _formatarTempo(_segundos);

    final tipoEvento = _tiposDeEventosDisponiveis.firstWhere(
      (e) => e.nome.toUpperCase() == 'SUBSTITUIÇÃO',
      orElse: () => TipoEventoEsporte(
        id: '',
        nome: 'SUBSTITUIÇÃO',
        modalidadeCatalogoId: '',
        idx: 0,
      ),
    );

    setState(() {
      int idx = listTitulares.indexOf(saindo);
      listTitulares[idx] = Atleta(
        id: entrando.id,
        atletaId: entrando.atletaId,
        equipeId: equipeIdCorreta,
        ativo: true,
        numero: entrando.numero,
        nome: entrando.nome,
        corTime: entrando.corTime ?? (isA ? Colors.orange : Colors.blue),
        posicao: saindo.posicao,
      );

      listReservas.remove(entrando);
      listReservas.add(
        Atleta(
          id: saindo.id,
          atletaId: saindo.atletaId,
          equipeId: equipeIdCorreta,
          ativo: false,
          numero: saindo.numero,
          nome: saindo.nome,
          corTime: saindo.corTime,
          posicao: Offset.zero,
        ),
      );

      _eventosPartida.insert(
        0,
        EventoPartida(
          tipo: 'Substituição',
          jogadorNome: '${saindo.nome} ↔ ${entrando.nome}',
          jogadorNumero: saindo.numero,
          corTime: saindo.corTime ?? Colors.grey,
          horario: tempoFormatado,
          observacao: observacao,
        ),
      );

      _jogadorSelecionado = null;
    });

    await _partidaService.salvarEvento(
      partidaId: widget.partida.id,
      tipoEventoId: tipoEvento.id,
      tempoFormatado: tempoFormatado,
      atletaId: entrando.atletaId,
      atletaSaiId: saindo.atletaId,
      equipeId: equipeIdCorreta,
      isSubstitution: true,
      descricao: observacao,
    );

    final sufixoObservacao = observacao.trim().isEmpty
        ? ''
        : ' • Observação adicionada';

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Substituição: ${saindo.nome} (#${saindo.numero}) ↔ ${entrando.nome} (#${entrando.numero})$sufixoObservacao",
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
