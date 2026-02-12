import 'package:flutter/material.dart';
import '../../data/models/partida_model.dart';
import '../../data/repositories/partida_repository.dart';
import 'confirma_partida_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fundo com Gradiente (Atrás de tudo)
          Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.7, -0.6),
                radius: 1.5,
                colors: [
                  Color(0xFFD1FFDA),
                  Color(0xFFB7FFEB),
                  Color(0xFFCBFFFB),
                ],
              ),
            ),
          ),

          // 2. Estrutura Principal Fixa
          SafeArea(
            child: Column(
              children: [
                // AJUSTE AQUI: Aumentar o padding top da tela
                const SizedBox(height: 30),

                // Seção de Cabeçalho e Cards (Estáticos/Não scrollam verticalmente)
                _buildHeaderSection(),
                _buildCardsSection(),
                const SizedBox(height: 20),
                _buildWhatDoYouWantSection(),

                // 3. Container Branco SCROLLÁVEL
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(
                      0,
                      10,
                    ), // Ajuste de posição para cima/baixo
                    child: _buildMainGamesSection(),
                  ),
                ),
              ],
            ),
          ),

          // 4. Barra de Navegação Fixa
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá {Nome},',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 20),
              ),
              Text(
                'Seja bem vindo!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF555555),
            child: Icon(Icons.person_outline, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsSection() {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        physics: const BouncingScrollPhysics(),
        itemCount: _partidas.isEmpty ? 3 : _partidas.length,
        itemBuilder: (context, index) {
          final partida = _partidas.isNotEmpty ? _partidas[index] : null;
          return GestureDetector(
            onTap: partida != null
                ? () => _confirmarInicioPartida(context, partida)
                : null,
            child: Container(
              width: 260,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3A68F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Futsal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'ID: ${partida?.id ?? '13123142'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const Text(
                          'Data: 21/10/2026',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        const Text(
                          'Hora: 14:00',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'SEU JOGO',
                        style: TextStyle(
                          color: Color(0xFFF3A68F),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWhatDoYouWantSection() {
    return Column(
      children: [
        const Text(
          'OQUE VOCÊ QUER VER?',
          style: TextStyle(fontFamily: 'Bebas Neue', fontSize: 28),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildOptionButton(Icons.sports_soccer, 'Jogos'),
            _buildOptionButton(Icons.gavel, 'Árbitros'),
            _buildOptionButton(Icons.emoji_events, 'Campeonatos'),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildOptionButton(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFFF85C39),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildMainGamesSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        // Alterado para Column para separar o cabeçalho
        children: [
          // ESTE BLOCO FICA FIXO
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jogos',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Ver Todos / Ver Meus',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),

          // ESTE BLOCO É O ÚNICO QUE SCROLLA
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                22,
                0,
                22,
                120,
              ), // Padding inferior para a Navbar
              physics: const BouncingScrollPhysics(),
              itemCount: _partidas.isNotEmpty ? _partidas.length : 10,
              itemBuilder: (context, index) {
                final partida = _partidas.isNotEmpty ? _partidas[index] : null;
                return _buildGameListItem(partida: partida);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameListItem({Partida? partida}) {
    return GestureDetector(
      onTap: partida != null
          ? () => _confirmarInicioPartida(context, partida)
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.sports_basketball, size: 28),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Futsal',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    partida != null
                        ? '${partida.nomeTimeA} x ${partida.nomeTimeB}'
                        : 'Computaria Masculina',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF555555),
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              '14/10/2026 14:00',
              style: TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Icon(Icons.home_filled, color: Colors.white, size: 28),
            const Icon(Icons.search, color: Colors.white, size: 28),
            Transform.translate(
              offset: const Offset(0, -5),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 32),
              ),
            ),
            const Icon(Icons.person, color: Colors.white, size: 28),
            const Icon(Icons.settings, color: Colors.white, size: 28),
          ],
        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
              child: const Text(
                'CANCELAR',
                style: TextStyle(color: Colors.white38),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
      MaterialPageRoute(
        builder: (_) => ConfirmaPartidaScreen(partida: partida),
      ),
    ).then((_) => _carregarDadosIniciais());
  }
}
