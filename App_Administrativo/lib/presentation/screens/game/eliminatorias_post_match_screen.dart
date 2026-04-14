import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/atleta_model.dart';
import 'package:kyarem_eventos/models/partida_model.dart';
import 'package:kyarem_eventos/presentation/screens/game/resumo_partida_screen.dart';
import 'package:kyarem_eventos/services/partida_service.dart';

class EliminatoriasPostMatchScreen extends StatefulWidget {
  final Partida partida;
  final String timeA;
  final String timeB;
  final int golsA;
  final int golsB;
  final List<Atleta> jogadoresA;
  final List<Atleta> jogadoresB;
  final PartidaService partidaService;

  const EliminatoriasPostMatchScreen({
    super.key,
    required this.partida,
    required this.timeA,
    required this.timeB,
    required this.golsA,
    required this.golsB,
    required this.jogadoresA,
    required this.jogadoresB,
    required this.partidaService,
  });

  @override
  State<EliminatoriasPostMatchScreen> createState() =>
      _EliminatoriasPostMatchScreenState();
}

class _EliminatoriasPostMatchScreenState
    extends State<EliminatoriasPostMatchScreen> {
  int _penaltisA = 0;
  int _penaltisB = 0;

  bool _escolhendoPrimeiro = true;
  bool _timeABateAgora = true;
  bool _salvando = false;

  Atleta? _batedorSelecionado;
  Atleta? _goleiroSelecionado;

  List<dynamic> _tiposEventos = [];
  final List<Map<String, dynamic>> _historicoCobrancas = [];

  @override
  void initState() {
    super.initState();
    _carregarTiposEventos();
  }

  Future<void> _carregarTiposEventos() async {
    _tiposEventos = await widget.partidaService.buscarTiposDeEventoDaPartida(
      widget.partida.modalidadeId,
    );
    if (mounted) {
      setState(() {});
    }
  }

  String _normalizar(String valor) {
    return valor
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

  dynamic _buscarTipoEvento(String nome) {
    final alvo = _normalizar(nome);
    for (final tipo in _tiposEventos) {
      if (_normalizar(tipo.nome.toString()) == alvo) return tipo;
    }
    return null;
  }

  void _definirQuemComeca(bool timeA) {
    setState(() {
      _timeABateAgora = timeA;
      _escolhendoPrimeiro = false;
    });
  }

  Future<void> _registrarCobranca(bool foiGol) async {
    if (_batedorSelecionado == null || _goleiroSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecione o batedor e o goleiro!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final descricao = foiGol
        ? "Gol de pênalti - ${_batedorSelecionado!.nome} marcou contra ${_goleiroSelecionado!.nome}."
        : "Pênalti perdido - ${_batedorSelecionado!.nome} bateu e ${_goleiroSelecionado!.nome} defendeu/foi fora.";
    final batedor = _batedorSelecionado!;
    final equipeId = _timeABateAgora
        ? widget.partida.equipeAId
        : widget.partida.equipeBId;
    final tipoEvento = _buscarTipoEvento(
      foiGol ? 'PENALTI_MARCADO' : 'PENALTI_PERDIDO',
    );

    try {
      setState(() {
        if (foiGol) {
          if (_timeABateAgora) {
            _penaltisA++;
          } else {
            _penaltisB++;
          }
        }

        _historicoCobrancas.add({
          'timeA': _timeABateAgora,
          'foiGol': foiGol,
          'batedor': _batedorSelecionado,
          'goleiro': _goleiroSelecionado,
          'descricao': descricao,
        });

        // Trocar turno
        _timeABateAgora = !_timeABateAgora;
        _batedorSelecionado = null;
        _goleiroSelecionado = null;
      });

      if (tipoEvento != null) {
        await widget.partidaService.salvarEvento(
          partidaId: widget.partida.id,
          equipeId: equipeId,
          atletaId: batedor.atletaId,
          tipoEventoId: tipoEvento.id.toString(),
          tempoFormatado: '00:00',
          descricao: descricao,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            foiGol
                ? "Gol de pênalti registrado!"
                : "Cobrança perdida registrada!",
          ),
          backgroundColor: foiGol ? Colors.green : Colors.red,
          duration: const Duration(milliseconds: 1500),
        ),
      );
    } catch (e) {
      debugPrint("Erro ao registrar cobrança: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _finalizarDisputa() async {
    if (_penaltisA == _penaltisB) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A disputa ainda está empatada. Registre mais cobranças.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      await widget.partidaService.atualizarPartida(
        widget.partida.id,
        novoStatus: 'finalizada',
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MatchSummaryScreen(
            timeA: widget.timeA,
            timeB: widget.timeB,
            escudoA: widget.partida.equipeA?.atleticaEscudoUrl,
            escudoB: widget.partida.equipeB?.atleticaEscudoUrl,
            golsA: widget.golsA,
            golsB: widget.golsB,
            partidaId: widget.partida.id,
            partidaService: widget.partidaService,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1E8),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD1B3), Color(0x00FFD1B3)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 18),

                // Placares
                _buildScoreboards(),
                const SizedBox(height: 22),

                // Card Principal
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(40),
                      ),
                    ),
                    child: _escolhendoPrimeiro
                        ? _buildSelecaoInicial()
                        : _buildInterfaceCobranca(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboards() {
    return Column(
      children: [
        // --- TEMPO NORMAL (Mantido com a correção de alinhamento) ---
        const Text(
          "TEMPO NORMAL",
          style: TextStyle(
            color: Color(0xFF6B625C),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(width: 8),
                  Text(
                    "${widget.golsA}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "v",
                style: TextStyle(color: Color(0xFF8B827C), fontSize: 14),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "${widget.golsB}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // --- PÊNALTIS ---
        const Text(
          "PÊNALTIS",
          style: TextStyle(
            color: Color(0xFFF85C39),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            // Time A
            Expanded(
              child: _buildTimePenaltyColumn(
                widget.timeA,
                widget.partida.equipeA?.atleticaEscudoUrl,
                CrossAxisAlignment.end,
                TextAlign.right,
              ),
            ),

            const SizedBox(width: 22),

            // Placar Central
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    "$_penaltisA",
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      "-",
                      style: TextStyle(color: Color(0xFF8B827C), fontSize: 30),
                    ),
                  ),
                  Text(
                    "$_penaltisB",
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 22),

            // Time B
            Expanded(
              child: _buildTimePenaltyColumn(
                widget.timeB,
                widget.partida.equipeB?.atleticaEscudoUrl,
                CrossAxisAlignment.start,
                TextAlign.left,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimePenaltyColumn(
    String nome,
    String? escudoUrl,
    CrossAxisAlignment alignment,
    TextAlign textAlignment,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: [
        // Container com largura limitada para forçar a quebra de linha
        SizedBox(
          width: 250, // Ajuste esse valor conforme necessário para o layout
          child: Text(
            nome,
            textAlign: textAlignment,
            maxLines: 2,
            softWrap: true, // Garante que o texto quebre
            style: const TextStyle(
              color: Color(0xFF1F1F1F),
              fontSize: 18, // Aumentado conforme solicitado
              height: 1.1,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildEscudo(escudoUrl),
      ],
    );
  }

  Widget _buildEscudo(String? url) {
    final Widget image = (url != null && url.trim().isNotEmpty)
        ? Image.network(
            url.trim(),
            width: 58,
            height: 58,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildEscudoFallback(),
          )
        : _buildEscudoFallback();

    return ClipOval(child: image);
  }

  Widget _buildEscudoFallback() {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xFFF3E2D5),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.shield_outlined,
        color: Color(0xFFF85C39),
        size: 20,
      ),
    );
  }

  Widget _buildSelecaoInicial() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.sports_soccer, size: 60, color: Color(0xFFB7AEA7)),
        const SizedBox(height: 24),
        const Text(
          "Quem vai cobrar primeiro?",
          style: TextStyle(
            color: Color(0xFF1F1F1F),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: _botaoTimeInicial(true, widget.timeA, Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _botaoTimeInicial(false, widget.timeB, Colors.blue),
            ),
          ],
        ),
      ],
    );
  }

  Widget _botaoTimeInicial(bool isTimeA, String nome, Color cor) {
    return ElevatedButton(
      onPressed: () => _definirQuemComeca(isTimeA),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cor.withOpacity(0.5), width: 2),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: cor.withOpacity(0.2),
            child: Icon(Icons.shield, color: cor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            nome,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1F1F1F),
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInterfaceCobranca() {
    final nomeAtacante = _timeABateAgora ? widget.timeA : widget.timeB;
    final corAtacante = _timeABateAgora ? Colors.orange : Colors.blue;
    final jogadoresBatedores = _timeABateAgora
        ? widget.jogadoresA
        : widget.jogadoresB;

    final corDefensor = _timeABateAgora ? Colors.blue : Colors.orange;
    final jogadoresGoleiros = _timeABateAgora
        ? widget.jogadoresB
        : widget.jogadoresA;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: corAtacante.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: corAtacante),
            ),
            child: Text(
              "COBRANÇA: $nomeAtacante",
              style: TextStyle(
                color: corAtacante,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),

        const Text(
          "Selecione o Batedor:",
          style: TextStyle(color: Color(0xFF6B625C), fontSize: 14),
        ),
        const SizedBox(height: 8),
        _buildPlayerPicker(
          jogadores: jogadoresBatedores,
          selecionado: _batedorSelecionado,
          tituloModal: "Escolha o batedor",
          hint: "Toque para escolher o jogador",
          iconContent: Icons.sports_martial_arts,
          iconColor: corAtacante,
          onChanged: (val) {
            setState(() {
              _batedorSelecionado = val;
            });
          },
        ),

        const SizedBox(height: 24),

        const Text(
          "Selecione o Goleiro Rival:",
          style: TextStyle(color: Color(0xFF6B625C), fontSize: 14),
        ),
        const SizedBox(height: 8),
        _buildPlayerPicker(
          jogadores: jogadoresGoleiros,
          selecionado: _goleiroSelecionado,
          tituloModal: "Escolha o goleiro rival",
          hint: "Toque para escolher o goleiro",
          iconContent: Icons.back_hand,
          iconColor: corDefensor,
          onChanged: (val) {
            setState(() {
              _goleiroSelecionado = val;
            });
          },
        ),

        const Spacer(),

        // BOTÕES GOL / PERDIDO
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _registrarCobranca(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.08),
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.35)),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.close, size: 28),
                    SizedBox(height: 4),
                    Text(
                      "PERDIDO",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _registrarCobranca(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.08),
                  foregroundColor: Colors.green,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.green.withOpacity(0.35)),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.sports_soccer, size: 28),
                    SizedBox(height: 4),
                    Text("GOL", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _salvando ? null : _finalizarDisputa,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              _salvando ? "FINALIZANDO..." : "FINALIZAR DISPUTA DE PÊNALTIS",
              style: const TextStyle(
                color: Color(0xFF6B625C),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerPicker({
    required List<Atleta> jogadores,
    required Atleta? selecionado,
    required String tituloModal,
    required String hint,
    required IconData iconContent,
    required Color iconColor,
    required ValueChanged<Atleta?> onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final atleta = await _abrirSeletorAtletas(
          titulo: tituloModal,
          jogadores: jogadores,
          iconContent: iconContent,
          iconColor: iconColor,
        );
        if (atleta != null) {
          onChanged(atleta);
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4F0),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selecionado == null
                ? const Color(0xFFE4D8D0)
                : iconColor.withOpacity(0.5),
            width: selecionado == null ? 1.2 : 1.6,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.16),
              radius: 20,
              child: Icon(iconContent, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selecionado == null
                        ? hint
                        : '#${selecionado.numero} - ${selecionado.nome}',
                    style: TextStyle(
                      color: const Color(0xFF1F1F1F),
                      fontWeight: selecionado == null
                          ? FontWeight.w500
                          : FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    selecionado == null
                        ? 'Nenhum atleta selecionado'
                        : 'Toque para trocar a seleção',
                    style: const TextStyle(
                      color: Color(0xFF8B827C),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8B827C)),
          ],
        ),
      ),
    );
  }

  Future<Atleta?> _abrirSeletorAtletas({
    required String titulo,
    required List<Atleta> jogadores,
    required IconData iconContent,
    required Color iconColor,
  }) {
    return showModalBottomSheet<Atleta>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.62,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8CCC3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: iconColor.withOpacity(0.14),
                      child: Icon(iconContent, color: iconColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        titulo,
                        style: const TextStyle(
                          color: Color(0xFF1F1F1F),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF0E5DD)),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: jogadores.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final atleta = jogadores[index];
                    return InkWell(
                      onTap: () => Navigator.pop(context, atleta),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F4F0),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE7DCD4)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: iconColor.withOpacity(0.16),
                              radius: 20,
                              child: Text(
                                '${atleta.numero ?? '-'}',
                                style: TextStyle(
                                  color: iconColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                atleta.nome,
                                style: const TextStyle(
                                  color: Color(0xFF1F1F1F),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Color(0xFF8B827C),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
