import 'package:flutter/material.dart';
import '../../data/models/partida_model.dart';
import '../../data/repositories/partida_repository.dart';
import '../widgets/partida_card_widget.dart';
import 'sumula_screen.dart';

class ListaPartidasScreen extends StatefulWidget {
  const ListaPartidasScreen({super.key});

  @override
  State<ListaPartidasScreen> createState() => _ListaPartidasScreenState();
}

class _ListaPartidasScreenState extends State<ListaPartidasScreen> {
  final PartidaRepository _repository = PartidaRepository();
  List<Partida> _partidas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    try {
      final partidasCarregadas = await _repository.buscarPartidasDoDia();
      setState(() {
        _partidas = partidasCarregadas;
        _carregando = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fundo Dark da identidade
      appBar: AppBar(
        title: const Text('Jogos do Dia', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent),
            onPressed: () {
              setState(() => _carregando = true);
              _carregarDadosIniciais();
            },
          )
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _partidas.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  itemCount: _partidas.length,
                  itemBuilder: (context, index) {
                    return PartidaCardWidget(
                      partida: _partidas[index],
                      onTap: () => _confirmarInicioPartida(context, _partidas[index]),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, color: Colors.white24, size: 60),
          SizedBox(height: 10),
          Text("Nenhuma partida para hoje.", style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  void _confirmarInicioPartida(BuildContext context, Partida partida) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.play_circle_fill, color: Colors.blueAccent),
              SizedBox(width: 10),
              Text('Iniciar Súmula?', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            'Deseja iniciar o cronômetro e o registro oficial para ${partida.nomeTimeA} x ${partida.nomeTimeB}?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await _repository.iniciarPartida(partida);
                if (!mounted) return;
                Navigator.of(context).pop();
                _navegarParaSumula(context, partida);
              },
              child: const Text('CONFIRMAR'),
            ),
          ],
        );
      },
    );
  }

  void _navegarParaSumula(BuildContext context, Partida partida) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SumulaScreen(partida: partida)),
    ).then((_) => _carregarDadosIniciais());
  }
}