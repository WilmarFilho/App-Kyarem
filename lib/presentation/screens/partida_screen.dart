import 'package:flutter/material.dart';
import '../../data/models/partida_model.dart';
import '../../data/models/evento_model.dart';
import '../../data/repositories/partida_repository.dart';
import '../../services/pdf_service.dart';
import '../widgets/placar_final_widget.dart';
import '../widgets/evento_timeline_tile.dart';

class PartidaScreen extends StatefulWidget {
  final Partida partida;
  const PartidaScreen({super.key, required this.partida});

  @override
  State<PartidaScreen> createState() => _PartidaScreenState();
}

class _PartidaScreenState extends State<PartidaScreen> {
  final PartidaRepository _repository = PartidaRepository();
  List<Evento> _eventos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  Future<void> _carregarResumo() async {
    try {
      final eventos = await _repository.buscarEventosDaSumula(widget.partida.sumula.id);
      setState(() {
        _eventos = eventos;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao carregar lances: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Resumo da Partida", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  PlacarFinalWidget(
                    nomeTimeA: widget.partida.nomeTimeA,
                    nomeTimeB: widget.partida.nomeTimeB,
                    placarA: widget.partida.sumula.placarTimeA,
                    placarB: widget.partida.sumula.placarTimeB,
                  ),
                  const SizedBox(height: 30),
                  const _SecaoLabel(label: "CRONOLOGIA DA PARTIDA"),
                  const SizedBox(height: 15),
                  Expanded(
                    child: _eventos.isEmpty
                        ? const Center(child: Text("Nenhum lance registrado", style: TextStyle(color: Colors.white38)))
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _eventos.length,
                            itemBuilder: (context, index) => EventoTimelineTile(evento: _eventos[index]),
                          ),
                  ),
                  _BotaoPdf(
                    onPressed: () => PdfService.gerarSumulaPdf(widget.partida, _eventos),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class _SecaoLabel extends StatelessWidget {
  final String label;
  const _SecaoLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const Expanded(child: Divider(indent: 20, color: Colors.white10)),
      ],
    );
  }
}

class _BotaoPdf extends StatelessWidget {
  final VoidCallback onPressed;
  const _BotaoPdf({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("GERAR SÚMULA OFICIAL", style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}