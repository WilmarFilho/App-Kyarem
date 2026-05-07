import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';
import '../../../services/evento_service.dart';
import '../../../services/firebase_messaging_service.dart';
import 'atletas_partida_screen.dart';
import 'resumo_estatistica_partida_screen.dart';
import '../modalidade/partidas_modalidade_screen.dart';
import '../../../models/modalidade_model.dart';
import '../../../services/modalidade_service.dart';
import '../../../services/realtime_service.dart';

class JogoDetalhesScreen extends StatefulWidget {
  final String partidaId;
  final DateTime? iniciadaEm;
  final String modalidadeId;
  final String timeA;
  final String timeB;
  final String? EscudoTimeA;
  final String? EscudoTimeB;
  final String placarA;
  final String placarB;
  final String status;
  final SupabaseClient? supabaseClient;
  final EventoService? eventoService;
  final bool enableFirebaseMessaging;

  const JogoDetalhesScreen({
    super.key,
    required this.partidaId,
    this.iniciadaEm,
    required this.modalidadeId,
    required this.timeA,
    required this.timeB,
    this.EscudoTimeA,
    this.EscudoTimeB,
    this.placarA = "0",
    this.placarB = "0",
    this.status = "AO VIVO",
    this.supabaseClient,
    this.eventoService,
    this.enableFirebaseMessaging = true,
  });

  @override
  State<JogoDetalhesScreen> createState() => _JogoDetalhesScreenState();
}

class _JogoDetalhesScreenState extends State<JogoDetalhesScreen> {
  // ← status atual da partida; começa vazio para indicar "ainda não chegou"
  String _statusAtual = '';

  // ── CRONÔMETRO PÚBLICO ──────────────────────────────────────────────
  Timer? _cronometroTicker;
  int _segundosExibidos = 0;
  bool _cronometroRodando = false;

  // Âncora do último evento confiável
  int _segundosAncora = 0;
  DateTime? _timestampAncora;
  // ────────────────────────────────────────────────────────────────────

  late final SupabaseClient supabase =
      widget.supabaseClient ?? Supabase.instance.client;
  late final EventoService _eventoService =
      widget.eventoService ?? EventoService();
  late final RealtimeService _realtimeService = RealtimeService();

  final _partidaController = StreamController<Map<String, dynamic>>.broadcast();
  final _eventosController = StreamController<List<Map<String, dynamic>>>.broadcast();

  Map<String, dynamic>? _partidaAtual;
  List<Map<String, dynamic>> _eventosAtuais = [];
  StreamSubscription? _sseSubscription;

  late Future<List<Map<String, dynamic>>> _futureTipos;
  Modalidade? _modalidadeObject;
  List<Map<String, dynamic>> _tiposEventosCache = [];

  final Map<String, String> _atletaNomeCache = {};

  // Statuses que significam que o relógio está correndo
  // 'pausada' está AUSENTE — garante que nunca liga o ticker nesse estado
  static const _statusRodando = {
    '1° tempo',
    '2° tempo',
    'acréscimo',
    'prorrogação',
  };

  @override
  void initState() {
    super.initState();

    _futureTipos = _eventoService
        .getEventTypesByModality(widget.modalidadeId)
        .then((tipos) {
          if (mounted) setState(() => _tiposEventosCache = tipos);
          return tipos;
        });

    if (widget.enableFirebaseMessaging) {
      FirebaseMessagingService().subscribeToPartidaTopic(widget.partidaId);
    }

    _loadModalidade();

    // 1. Carrega dados via HTTP (REST/Supabase)
    _carregarDadosIniciais();

    // 2. Conecta no SSE
    _sseSubscription = _realtimeService.listenToMatch(widget.partidaId).listen((evento) {
      if (!mounted) return;

      final payload = _normalizarEventoRealtime(evento);
      final aggregateType = payload['aggregateType']?.toString();
      if (aggregateType != 'Partida' && aggregateType != 'EventoPartida') {
        return;
      }

      unawaited(_carregarDadosIniciais());
    });

    // Escuta eventos e atualiza cronômetro localmente
    _eventosController.stream.listen((eventos) {
      if (!mounted) return;
      _eventosAtuais = eventos;
      _reconstruirEstadoCronometro();
    });

    _partidaController.stream.listen((dados) {
      if (!mounted) return;
      _partidaAtual = dados;
      _reconstruirEstadoCronometro();
    });
  }

  Future<void> _carregarDadosIniciais() async {
    Map<String, dynamic>? partida;
    List<Map<String, dynamic>> eventos = [];

    try {
      final resP = await supabase
          .schema('operational')
          .from('partidas')
          .select(
            'id, status, placar_a, placar_b, iniciada_em, periodo_atual, periodo_antes_pausa, atualizado_em',
          )
          .eq('id', widget.partidaId)
          .maybeSingle();

      if (resP != null) {
        partida = Map<String, dynamic>.from(resP);
      }
    } catch (e) {
      debugPrint("Erro carregar partida HTTP: $e");
    }

    try {
      final resE = await supabase
          .schema('operational')
          .from('eventos_partida')
          .select('*, tipo_evento:tipo_evento_id(id, nome, codigo)')
          .eq('partida_id', widget.partidaId)
          .order('criado_em', ascending: false);

      if (resE.isNotEmpty) {
        eventos = List<Map<String, dynamic>>.from(resE);
      }
    } catch (e) {
      debugPrint("Erro carregar eventos HTTP: $e");
    }

    if (!mounted) return;

    if (partida != null) {
      _partidaAtual = partida;
      _partidaController.add(partida);
    }
    _eventosAtuais = eventos;
    _eventosController.add(eventos);
    _reconstruirEstadoCronometro();
  }

  Map<String, dynamic> _normalizarEventoRealtime(dynamic evento) {
    if (evento is! Map) return const {};

    final base = Map<String, dynamic>.from(evento);
    final nested = base['payloadJson'];
    if (nested is Map) {
      return {
        ...Map<String, dynamic>.from(nested),
        if (nested['aggregateType'] == null && base['aggregateType'] != null)
          'aggregateType': base['aggregateType'],
      };
    }

    return base;
  }

  Future<void> _loadModalidade() async {
    try {
      final mods = await ModalidadeService().getModalities();
      if (mounted) {
        setState(() {
          _modalidadeObject = mods.firstWhere(
            (m) => m.id == widget.modalidadeId,
          );
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar modalidade: $e");
    }
  }

  @override
  void dispose() {
    _cronometroTicker?.cancel();
    _sseSubscription?.cancel();
    _realtimeService.disconnect();
    _partidaController.close();
    _eventosController.close();
    super.dispose();
  }

  String _formatarHoraMinuto(String? timestamp) {
    if (timestamp == null) return '';

    final dt = DateTime.tryParse(timestamp);
    if (dt == null) return '';

    final hora = dt.toLocal().hour.toString().padLeft(2, '0');
    final minuto = dt.toLocal().minute.toString().padLeft(2, '0');

    return "$hora:$minuto";
  }

  String _friendlyEventName(Map<String, dynamic> ev) {
    final rawName = _eventTypeCode(ev);
    return EventoService.friendly(rawName.isEmpty ? 'Evento' : rawName);
  }

  void _reconstruirEstadoCronometro() {
    final status = (_partidaAtual?['status']?.toString() ?? '').toLowerCase();
    _statusAtual = status;

    final eventosAsc = [..._eventosAtuais]
      ..sort((a, b) {
        final aTs = DateTime.tryParse(a['criado_em']?.toString() ?? '');
        final bTs = DateTime.tryParse(b['criado_em']?.toString() ?? '');
        if (aTs == null && bTs == null) return 0;
        if (aTs == null) return -1;
        if (bTs == null) return 1;
        return aTs.compareTo(bTs);
      });

    int segundosBase = 0;
    DateTime? timestampBase;
    bool emExecucao = false;

    for (final evento in eventosAsc) {
      final timestamp = DateTime.tryParse(evento['criado_em']?.toString() ?? '');
      if (timestamp == null) continue;

      final code = _eventTypeCode(evento);
      final tempoRaw = evento['tempo_cronometro']?.toString();
      final tempoEvento = (tempoRaw != null && tempoRaw.isNotEmpty)
          ? _parseTempoCronometro(tempoRaw)
          : null;

      final segundosNoMomento = tempoEvento ??
          (emExecucao && timestampBase != null
              ? segundosBase +
                    timestamp.toUtc().difference(timestampBase.toUtc()).inSeconds
              : segundosBase);

      if (code == 'PARTIDA_PAUSADA' ||
          code == 'PAUSA_TECNICA' ||
          code == 'INTERVALO' ||
          code.startsWith('FIM_')) {
        segundosBase = segundosNoMomento;
        timestampBase = timestamp;
        emExecucao = false;
        continue;
      }

      if (code == 'PARTIDA_RETOMADA' ||
          code.startsWith('INICIO_') ||
          code == 'ACRESCIMO' ||
          code == 'PRORROGACAO') {
        segundosBase = segundosNoMomento;
        timestampBase = timestamp;
        emExecucao = true;
        continue;
      }

      if (tempoEvento != null) {
        segundosBase = tempoEvento;
        timestampBase = timestamp;
      }
    }

    final deveRodar = _statusRodando.contains(status);
    final segundosExibidos = (deveRodar && timestampBase != null)
        ? segundosBase +
            DateTime.now().toUtc().difference(timestampBase.toUtc()).inSeconds
        : segundosBase;

    _cronometroTicker?.cancel();

    setState(() {
      _segundosAncora = segundosBase;
      _timestampAncora = timestampBase;
      _segundosExibidos = segundosExibidos.clamp(0, 99 * 60 + 59);
      _cronometroRodando = deveRodar;
    });

    if (deveRodar && timestampBase != null) {
      _cronometroTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _timestampAncora == null) return;
        setState(() {
          _segundosExibidos =
              _segundosAncora +
              DateTime.now()
                  .toUtc()
                  .difference(_timestampAncora!.toUtc())
                  .inSeconds;
        });
      });
    }
  }

  String _eventTypeCode(Map<String, dynamic> ev) {
    final joined = ev['tipo_evento'];
    if (joined is Map) {
      final code = joined['codigo']?.toString();
      final name = joined['nome']?.toString();
      return (code ?? name ?? '').trim().toUpperCase();
    }

    final tipoData = _tiposEventosCache.firstWhere(
      (t) => t['id'] == ev['tipo_evento_id'],
      orElse: () => const <String, dynamic>{},
    );
    final code = tipoData['codigo']?.toString();
    final name = tipoData['nome']?.toString();
    return (code ?? name ?? '').trim().toUpperCase();
  }

  /// Converte "MM:SS" → total em segundos
  int _parseTempoCronometro(String tempo) {
    final partes = tempo.split(':');
    if (partes.length != 2) return 0;
    final min = int.tryParse(partes[0]) ?? 0;
    final seg = int.tryParse(partes[1]) ?? 0;
    return min * 60 + seg;
  }

  /// Converte segundos → "MM:SS" para exibição
  String _formatarCronometroPublico(int totalSegundos) {
    final s = totalSegundos.clamp(0, 99 * 60 + 59);
    final min = s ~/ 60;
    final seg = s % 60;
    return "${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}";
  }

  Future<String?> _resolveAtletaNome(String? atletaId) async {
    if (atletaId == null || atletaId.isEmpty) return null;

    if (_atletaNomeCache.containsKey(atletaId)) {
      return _atletaNomeCache[atletaId];
    }

    final nome = await _eventoService.getAthleteNameById(atletaId);
    if (nome != null) {
      _atletaNomeCache[atletaId] = nome;
    }
    return nome;
  }

  Future<String> _buildEventDescription(Map<String, dynamic> ev) async {
    final friendlyName = _friendlyEventName(ev);
    final atletaId = ev['atleta_id']?.toString();
    final atletaSaiId = ev['atleta_sai_id']?.toString();
    final isSubstitution = ev['is_substitution'] == true;
    final descricao = (ev['descricao_detalhada']?.toString() ?? '').trim();

    final parts = <String>[friendlyName];

    if (isSubstitution && atletaId != null && atletaSaiId != null) {
      final nomeEntra = await _resolveAtletaNome(atletaId);
      final nomeSai = await _resolveAtletaNome(atletaSaiId);
      if (nomeEntra != null && nomeSai != null) {
        parts.add('Entra: $nomeEntra, Sai: $nomeSai');
      }
    } else if (atletaId != null) {
      final nome = await _resolveAtletaNome(atletaId);
      if (nome != null) parts.add(nome);
    }

    if (descricao.isNotEmpty) parts.add(descricao);

    return parts.join(' — ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          "DETALHES DO JOGO",
          style: GoogleFonts.oswald(
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.orange, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          StreamBuilder<Map<String, dynamic>>(
            stream: _partidaController.stream,
            builder: (context, snapshot) {
              final dados = snapshot.data;
              return _buildScoreHeader(
                placarA: dados?['placar_a']?.toString() ?? widget.placarA,
                placarB: dados?['placar_b']?.toString() ?? widget.placarB,
                status: dados?['status'] ?? widget.status,
              );
            },
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: FutureBuilder(
                future: _futureTipos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }
                  return _buildTimelineStream();
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ), // Espaçamento nas laterais da tela
        child: Row(
          children: [
            // BOTÃO 1: ATLETAS
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: "btn_atletas",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AtletasPartidaScreen(
                        partidaId: widget.partidaId,
                        timeA: widget.timeA,
                        timeB: widget.timeB,
                        escudoA: widget.EscudoTimeA,
                        escudoB: widget.EscudoTimeB,
                      ),
                    ),
                  );
                },
                backgroundColor: const Color(0xFFF2561D), // Laranja padronizado
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.group_outlined, size: 20),
                label: const Text(
                  'Atletas',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // BOTÃO 2: RESUMO
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: "btn_estatisticas",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResumoEstatisticaPartidaScreen(
                        partidaId: widget.partidaId,
                        timeA: widget.timeA,
                        timeB: widget.timeB,
                        escudoA: widget.EscudoTimeA,
                        escudoB: widget.EscudoTimeB,
                      ),
                    ),
                  );
                },
                backgroundColor: const Color(0xFFF2561D),
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.analytics_outlined, size: 20),
                label: const Text(
                  'Resumo',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // BOTÃO 3: MAIS PARTIDAS
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: "btn_mais_partidas",
                onPressed: () {
                  if (_modalidadeObject != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PartidasModalidadeScreen(
                          modalidade: _modalidadeObject!,
                        ),
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                  }
                },
                backgroundColor: const Color(0xFFF2561D),
                foregroundColor: Colors.white,
                elevation: 4,
                icon: const Icon(Icons.sports_soccer, size: 20),
                label: const Text(
                  '+ Jogos',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader({
    required String placarA,
    required String placarB,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.orange, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTeamBadge(widget.timeA, widget.EscudoTimeA),
          Column(
            children: [
              Text(
                "$placarA - $placarB",
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatarCronometroPublico(_segundosExibidos),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _cronometroRodando ? Colors.white : Colors.white54,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: 2,
                ),
              ),
              if (_cronometroRodando) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "AO VIVO",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          _buildTeamBadge(widget.timeB, widget.EscudoTimeB),
        ],
      ),
    );
  }

  Widget _buildTeamBadge(String nome, String? escudo) {
    return Column(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          backgroundImage: escudo != null ? NetworkImage(escudo) : null,
          child: escudo == null
              ? Text(
                  nome.isNotEmpty ? nome[0] : "?",
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 100,
          child: Text(
            nome,
            textAlign: TextAlign.center,
            maxLines: 3,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _eventosController.stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Erro ao carregar lances"));
        }

        final eventos = snapshot.data ?? [];
        if (eventos.isEmpty) {
          return const Center(
            child: Text(
              "Aguardando lances da partida...",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(25, 25, 25, 10),
              child: Text(
                "LINHA DO TEMPO AO VIVO",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: eventos.length,
                itemBuilder: (context, index) => _buildAnimatedTimelineItem(
                  eventos[index],
                  index,
                  eventos.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedTimelineItem(
    Map<String, dynamic> ev,
    int index,
    int total,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: _buildTimelineItem(ev, index, total),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> ev, int index, int total) {
    final friendlyName = _friendlyEventName(ev);

    final horaEvento = _formatarHoraMinuto(ev['criado_em']?.toString());

    final String rawNome = _eventTypeCode(ev);

    IconData iconData = Icons.info_outline;
    Color iconColor = Colors.grey;

    if (rawNome.contains('GOL') || rawNome.contains('PENALTI_CONVERTIDO')) {
      iconData = Icons.sports_soccer;
      iconColor = Colors.green;
    } else if (rawNome.contains('AMARELO')) {
      iconData = Icons.style;
      iconColor = Colors.amber;
    } else if (rawNome.contains('VERMELHO')) {
      iconData = Icons.style;
      iconColor = Colors.red;
    } else if (rawNome.contains('SUBSTITUICAO')) {
      iconData = Icons.swap_horiz;
      iconColor = Colors.blue;
    } else if (rawNome.contains('FALTA')) {
      iconData = Icons.front_hand;
      iconColor = Colors.orange;
    } else if (rawNome.contains('PENALTI')) {
      iconData = Icons.sports_soccer;
      iconColor = Colors.deepOrange;
    } else if (rawNome.contains('INICIO') ||
        rawNome.contains('ACRESCIMO') ||
        rawNome.contains('PRORROGACAO')) {
      iconData = Icons.timer;
      iconColor = Colors.green;
    } else if (rawNome.contains('PAUSADA') || rawNome.contains('RETOMADA')) {
      iconData = Icons.pause_circle_outline;
      iconColor = const Color(0xFFF85C39);
    } else if (rawNome.contains('FIM')) {
      iconData = Icons.timer;
      iconColor = const Color(0xFFF85C39);
    }

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 2,
                height: 20,
                color: index == 0 ? Colors.transparent : Colors.grey[300],
              ),
              AnimatedScale(
                duration: const Duration(milliseconds: 800),
                scale: 1.0,
                child: Icon(iconData, size: 22, color: iconColor),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: index == total - 1
                      ? Colors.transparent
                      : Colors.grey[300],
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ev['tempo_cronometro'] != null) ...[
                        Text(
                          "${ev['tempo_cronometro'] ?? "00:00"}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        horaEvento,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friendlyName,
                          style: TextStyle(
                            fontSize: 10,
                            color: iconColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        FutureBuilder<String>(
                          future: _buildEventDescription(ev),
                          builder: (context, snap) {
                            final desc = snap.data ?? '';
                            final cleanDesc = desc.startsWith(friendlyName)
                                ? desc
                                      .substring(friendlyName.length)
                                      .replaceFirst(RegExp(r'^\s*—\s*'), '')
                                : desc;
                            if (cleanDesc.isEmpty)
                              return const SizedBox.shrink();
                            return Text(
                              cleanDesc,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
