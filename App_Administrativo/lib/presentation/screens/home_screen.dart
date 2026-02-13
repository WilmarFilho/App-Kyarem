import 'package:flutter/material.dart';
import '../../data/models/partida_model.dart';
import '../../data/repositories/partida_repository.dart';
import 'confirma_partida_screen.dart';
import '../widgets/bottom_navigation_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final PartidaRepository _repository = PartidaRepository();
  List<Partida> _partidas = [];
  bool _carregandoDados = false;
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  String _abaSelecionada = 'Jogos';
  bool _verMeus = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _initializeAnimations();
    _carregarDadosIniciais();
  }

  void _initializeAnimations() {
    _fadeAnimations = List.generate(3, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.2,
          (index * 0.2) + 0.8,
          curve: Curves.easeOutCubic,
        ),
      ));
    });

    _slideAnimations = List.generate(3, (index) {
      return Tween<Offset>(
        begin: const Offset(0.0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.2,
          (index * 0.2) + 0.8,
          curve: Curves.easeOutCubic,
        ),
      ));
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosIniciais() async {
    if (_carregandoDados) return; // Evita múltiplas chamadas
    
    setState(() => _carregandoDados = true);
    
    try {
      final partidasCarregadas = await _repository.buscarPartidasDoDia();
      setState(() {
        _partidas = partidasCarregadas;
        _carregandoDados = false;
      });
      
      // Inicia a animação após carregar os dados
      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
      setState(() => _carregandoDados = false);
      // Anima mesmo com erro para mostrar cards mockados
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Fundo com Gradiente
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

          // 2. Estrutura Principal
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                _buildHeaderSection(),
                _buildCardsSection(),
                const SizedBox(height: 20),
                _buildWhatDoYouWantSection(),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, 10),
                    child: _buildMainGamesSection(),
                  ),
                ),
              ],
            ),
          ),

          // 3. Barra de Navegação
          const BottomNavigationWidget(currentRoute: '/home'),
        ],
      ),
    );
  }

  // (Os outros métodos _build permanecem conforme sua lógica original de design)

  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Olá {Nome},', style: TextStyle(fontFamily: 'Poppins', fontSize: 20)),
              Text('Seja bem vindo!', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/perfil'),
            child: const CircleAvatar(
              radius: 25,
              backgroundColor: Color(0xFF555555),
              child: Icon(Icons.person_outline, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsSection() {
    return SizedBox(
      height: 130,
      child: _carregandoDados 
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF85C39)),
            ),
          )
        : ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            physics: const BouncingScrollPhysics(),
            itemCount: _partidas.isEmpty ? 3 : _partidas.length,
            itemBuilder: (context, index) {
              final partida = _partidas.isNotEmpty ? _partidas[index] : null;
              final animationIndex = index.clamp(0, 2); // Limita a 3 animações
              
              return SlideTransition(
                position: _slideAnimations[animationIndex],
                child: FadeTransition(
                  opacity: _fadeAnimations[animationIndex],
                  child: GestureDetector(
                    onTap: partida != null ? () => _confirmarInicioPartida(context, partida) : null,
                    child: Container(
                      width: 260,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3A68F),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Futsal', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            Text('ID: ${partida?.id ?? '13123142'}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
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
        const Text('OQUE VOCÊ QUER VER?', style: TextStyle(fontFamily: 'Bebas Neue', fontSize: 28)),
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
        scale: isSelected ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFFF85C39) : const Color.fromARGB(159, 248, 92, 57),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
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
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_abaSelecionada, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => setState(() => _verMeus = !_verMeus),
                  child: Text(_verMeus ? 'Ver Tudo' : 'Ver Meus', style: TextStyle(color: _verMeus ? const Color(0xFFF85C39) : Colors.grey[600], fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
              itemCount: 10,
              itemBuilder: (context, index) => _buildMockListItem(),
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
      decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Icon(_abaSelecionada == 'Árbitros' ? Icons.person : Icons.workspace_premium, size: 28),
          const SizedBox(width: 15),
          Text('Item de $_abaSelecionada Mockado', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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