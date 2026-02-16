import 'package:flutter/material.dart';

class MatchSummaryScreen extends StatelessWidget {
  final String timeA;
  final String timeB;
  final int golsA;
  final int golsB;
  // Aqui passamos a lista de eventos capturados na tela anterior
  final List<dynamic> eventos;

  const MatchSummaryScreen({
    super.key,
    required this.timeA,
    required this.timeB,
    required this.golsA,
    required this.golsB,
    required this.eventos,
  });

  @override
  Widget build(BuildContext context) {
    // Bloqueia o gesto de voltar do Android/iOS
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0FFF4),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildScoreCard(),
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
              Expanded(child: _buildEventList()),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  // Header com título centralizado
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: Text(
          "PARTIDA FINALIZADA",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ),
    );
  }

  // Placar final seguindo o estilo da tela de jogo
  Widget _buildScoreCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _timeColumn(timeA, golsA, Colors.orange),
          const Text(
            "VS",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          _timeColumn(timeB, golsB, Colors.blue),
        ],
      ),
    );
  }

  Widget _timeColumn(String nome, int gols, Color cor) {
    return Column(
      children: [
        Text(
          nome,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          gols.toString().padLeft(2, '0'),
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ],
    );
  }

  // Lista de eventos (Mockada ou Real)
  Widget _buildEventList() {
    // Se a lista estiver vazia, mostra um placeholder
    if (eventos.isEmpty) {
      return const Center(child: Text("Nenhum evento registrado."));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: eventos.length,
      itemBuilder: (context, index) {
        final ev = eventos[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading: _getIconForEvent(ev.tipo),
            title: Text(
              ev.descricao,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text("Tempo: ${ev.horario}"),
            trailing: CircleAvatar(radius: 4, backgroundColor: ev.corTime),
          ),
        );
      },
    );
  }

  // Helper para ícones dos eventos
  Widget _getIconForEvent(String tipo) {
    switch (tipo) {
      case 'Gol':
        return const Icon(Icons.sports_soccer, color: Colors.green);
      case 'Cartão Amarelo':
        return const Icon(Icons.style, color: Colors.amber);
      case 'Cartão Vermelho':
        return const Icon(Icons.style, color: Colors.red);
      default:
        return const Icon(Icons.info_outline, color: Colors.grey);
    }
  }

  // Botões inferiores
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Lógica para abrir PDF futuramente
              },
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text(
                "VER PDF DA SÚMULA",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Volta para a tela inicial (home) limpando a pilha de navegação
                Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D2D2D),
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                "VOLTAR PARA O INÍCIO",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
