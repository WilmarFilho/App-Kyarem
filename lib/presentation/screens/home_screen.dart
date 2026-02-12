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

  String _abaSelecionada = 'Jogos';
  bool _verMeus = false; // false = Ver Tudo, true = Ver Meus

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
    bool isSelected = _abaSelecionada == label;

    return GestureDetector(
      onTap: () => setState(() => _abaSelecionada = label),
      child: AnimatedScale(
        scale: isSelected ? 1.1 : 1.0, // Aumenta levemente se selecionado
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFFF85C39)
                    : const Color.fromARGB(159, 248, 92, 57),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
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
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Título dinâmico conforme a aba selecionada
                Text(
                  _abaSelecionada,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Filtro clicável
                GestureDetector(
                  onTap: () => setState(() => _verMeus = !_verMeus),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    child: Text(
                      _verMeus ? 'Ver Tudo' : 'Ver Meus',
                      key: ValueKey<bool>(
                        _verMeus,
                      ), // Importante para o Switcher reconhecer a mudança
                      style: TextStyle(
                        color: _verMeus
                            ? const Color(0xFFF85C39)
                            : Colors.grey[600],
                        fontSize: 13,
                        fontWeight: _verMeus
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: ListView.builder(
                key: ValueKey<String>(
                  '$_abaSelecionada$_verMeus',
                ), // Chave para disparar a animação
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
                physics: const BouncingScrollPhysics(),
                itemCount: (_abaSelecionada == 'Jogos' && _partidas.isNotEmpty)
                    ? _partidas.length
                    : 10,
                // Dentro do ListView.builder
                itemBuilder: (context, index) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(
                      milliseconds: 200 + (index * 50),
                    ), // Efeito cascata
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: _abaSelecionada == 'Jogos'
                        ? _buildGameListItem(
                            partida: _partidas.isNotEmpty
                                ? _partidas[index]
                                : null,
                          )
                        : _buildMockListItem(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockListItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            _abaSelecionada == 'Árbitros'
                ? Icons.person
                : Icons.workspace_premium,
            size: 28,
          ),
          const SizedBox(width: 15),
          Text(
            'Item de $_abaSelecionada Mockado',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
