import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/partida_model.dart';
import '../../data/repositories/partida_repository.dart';

// --- TELA PRINCIPAL DA SÚMULA (JOGO EM ANDAMENTO) ---
class ConfirmaPartidaScreen extends StatefulWidget {
  final Partida partida;

  const ConfirmaPartidaScreen({super.key, required this.partida});

  @override
  State<ConfirmaPartidaScreen> createState() => _ConfirmaPartidaScreenState();
}

class _ConfirmaPartidaScreenState extends State<ConfirmaPartidaScreen> {
  final PartidaRepository _repository = PartidaRepository();
  late int placarA;
  late int placarB;
  String? _atletaSelecionado;
  String? _timeDoAtletaSelecionado;
  Timer? _timer;
  late int _segundosRestantes;
  bool _estaPausado = true;

  @override
  void initState() {
    super.initState();
    // Força Landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    placarA = widget.partida.sumula.placarTimeA;
    placarB = widget.partida.sumula.placarTimeB;
    _segundosRestantes = widget.partida.duracaoMinutos * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _alternarCronometro() {
    if (_estaPausado) {
      setState(() => _estaPausado = false);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_segundosRestantes > 0) {
          setState(() => _segundosRestantes--);
        } else {
          _encerrarPartidaAutomaticamente();
        }
      });
    } else {
      setState(() {
        _estaPausado = true;
        _timer?.cancel();
      });
    }
  }

  void _registrarAcaoRapida(String tipo) async {
    if (_atletaSelecionado == null) return;

    final nomeAtleta = _atletaSelecionado!;
    final timeAtleta = _timeDoAtletaSelecionado!;

    setState(() {
      if (tipo == 'GOL') {
        if (timeAtleta == 'A') placarA++; else placarB++;
      }
      _atletaSelecionado = null; // Limpa seleção após registro
    });

    await _repository.registrarEvento(
      sumulaId: widget.partida.sumula.id,
      atletaNome: nomeAtleta,
      tipo: tipo,
      time: timeAtleta,
    );
  }

  void _encerrarPartidaAutomaticamente() async {
    _timer?.cancel();
    await _repository.encerrarPartida(widget.partida.id);
    
    if (!mounted) return;

    // Navega para o Resumo
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmaPartidaScreen(partida: widget.partida),
      ),
    );
  }

  String _formatarTempo() {
    int min = _segundosRestantes ~/ 60;
    int seg = _segundosRestantes % 60;
    return '${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double larguraTotal = constraints.maxWidth;
            return Row(
              children: [
                _buildColunaTime(
                  larguraTotal * 0.4,
                  widget.partida.nomeTimeA,
                  widget.partida.atletasTimeA,
                  'A',
                  [Colors.blue.withOpacity(0.2), Colors.transparent],
                ),
                Container(
                  width: larguraTotal * 0.2,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    border: Border.symmetric(vertical: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                  child: _buildControleCentral(),
                ),
                _buildColunaTime(
                  larguraTotal * 0.4,
                  widget.partida.nomeTimeB,
                  widget.partida.atletasTimeB,
                  'B',
                  [Colors.red.withOpacity(0.2), Colors.transparent],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildColunaTime(double largura, String nome, List<String> atletas, String time, List<Color> degrade) {
    return Container(
      width: largura,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: degrade),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(nome.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 12, runSpacing: 12,
                alignment: WrapAlignment.center,
                children: atletas.map((a) => _buildCardAtletaGlass(a, time)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardAtletaGlass(String nome, String time) {
    bool selecionado = _atletaSelecionado == nome;
    return GestureDetector(
      onTap: () => setState(() { _atletaSelecionado = nome; _timeDoAtletaSelecionado = time; }),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 100, height: 85,
            decoration: BoxDecoration(
              color: selecionado ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: selecionado ? Colors.blueAccent : Colors.white.withOpacity(0.1), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, color: selecionado ? Colors.blueAccent : Colors.white60, size: 28),
                const SizedBox(height: 6),
                Text(nome, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControleCentral() {
    bool ativo = _atletaSelecionado != null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCronometroDisplay(),
        Text("$placarA - $placarB", style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _botaoAcaoCircular(Icons.sports_soccer, "GOL", Colors.greenAccent, ativo),
              const SizedBox(height: 12),
              _botaoAcaoCircular(Icons.style, "AMARELO", Colors.amberAccent, ativo),
              const SizedBox(height: 12),
              _botaoAcaoCircular(Icons.style, "VERMELHO", Colors.redAccent, ativo),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCronometroDisplay() {
    return GestureDetector(
      onTap: _alternarCronometro,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: _estaPausado ? Colors.amber.withOpacity(0.1) : Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _estaPausado ? Colors.amber.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(_formatarTempo(), style: TextStyle(color: _estaPausado ? Colors.amberAccent : Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            Icon(_estaPausado ? Icons.play_arrow : Icons.pause, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _botaoAcaoCircular(IconData icone, String label, Color cor, bool ativo) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ativo ? cor.withOpacity(0.2) : Colors.white10,
          foregroundColor: ativo ? cor : Colors.white24,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
        ),
        onPressed: ativo ? () => _registrarAcaoRapida(label) : null,
        child: Icon(icone, size: 24),
      ),
    );
  }
}