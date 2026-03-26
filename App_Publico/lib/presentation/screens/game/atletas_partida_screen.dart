import 'package:flutter/material.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';
import '../../../../models/atleta_model.dart';
import '../../../../services/game_service.dart';
import 'estatistica_atleta_screen.dart';

class AtletasPartidaScreen extends StatefulWidget {
  final String partidaId;
  final String timeA;
  final String timeB;
  final String? escudoA;
  final String? escudoB;
  final GameService? gameService;

  const AtletasPartidaScreen({
    super.key,
    required this.partidaId,
    required this.timeA,
    required this.timeB,
    this.escudoA,
    this.escudoB,
    this.gameService,
  });

  @override
  State<AtletasPartidaScreen> createState() => _AtletasPartidaScreenState();
}

class _AtletasPartidaScreenState extends State<AtletasPartidaScreen>
    with SingleTickerProviderStateMixin {
  late final GameService _gameService = widget.gameService ?? GameService();
  late TabController _tabController;

  String? _equipeIdA;
  String? _equipeIdB;

  List<Atleta> _titularesA = [];
  List<Atleta> _reservasA = [];
  List<Atleta> _titularesB = [];
  List<Atleta> _reservasB = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final partidaData = await _gameService.getPartidaEquipes(widget.partidaId);

      _equipeIdA = partidaData['equipe_a_id']?.toString();
      _equipeIdB = partidaData['equipe_b_id']?.toString();

      final futures = <Future>[];
      if (_equipeIdA != null) {
        futures.add(
          _gameService.getAtletasInscritos(_equipeIdA!).then((inscritos) {
            for (var inscrito in inscritos) {
              final ativo = inscrito['ativo'] == true;
              final atletaMap = inscrito['atletas'];
              if (atletaMap != null) {
                final atleta = Atleta.fromMap(atletaMap);
                if (ativo) {
                  _titularesA.add(atleta);
                } else {
                  _reservasA.add(atleta);
                }
              }
            }
            _titularesA.sort((a, b) => a.nome.compareTo(b.nome));
            _reservasA.sort((a, b) => a.nome.compareTo(b.nome));
          }),
        );
      }

      if (_equipeIdB != null) {
        futures.add(
          _gameService.getAtletasInscritos(_equipeIdB!).then((inscritos) {
            for (var inscrito in inscritos) {
              final ativo = inscrito['ativo'] == true;
              final atletaMap = inscrito['atletas'];
              if (atletaMap != null) {
                final atleta = Atleta.fromMap(atletaMap);
                if (ativo) {
                  _titularesB.add(atleta);
                } else {
                  _reservasB.add(atleta);
                }
              }
            }
            _titularesB.sort((a, b) => a.nome.compareTo(b.nome));
            _reservasB.sort((a, b) => a.nome.compareTo(b.nome));
          }),
        );
      }

      await Future.wait(futures);
    } catch (e) {
      debugPrint("Erro ao carregar atletas: \$e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ATLETAS",
          style: TextStyle(fontFamily: 'Bebas Neue', fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: widget.timeA.toUpperCase()),
            Tab(text: widget.timeB.toUpperCase()),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListaTime(
                  _titularesA,
                  _reservasA,
                  widget.timeA,
                  widget.escudoA,
                ),
                _buildListaTime(
                  _titularesB,
                  _reservasB,
                  widget.timeB,
                  widget.escudoB,
                ),
              ],
            ),
    );
  }

  Widget _buildListaTime(
    List<Atleta> titulares,
    List<Atleta> reservas,
    String timeNome,
    String? escudoUrl,
  ) {
    if (titulares.isEmpty && reservas.isEmpty) {
      return const Center(child: Text('Nenhum atleta inscrito nesta equipe.'));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      children: [
        if (titulares.isNotEmpty) ...[
          _buildSectionHeader("TITULARES", AppColors.primary),
          ...titulares.map((a) => _buildAtletaCard(a, timeNome, escudoUrl)),
          const SizedBox(height: 20),
        ],
        if (reservas.isNotEmpty) ...[
          _buildSectionHeader("RESERVAS", Colors.grey.shade700),
          ...reservas.map((a) => _buildAtletaCard(a, timeNome, escudoUrl)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Bebas Neue',
          fontSize: 20,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildAtletaCard(Atleta atleta, String timeNome, String? escudoUrl) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFF5F5F5),
          backgroundImage: atleta.fotoUrl != null
              ? NetworkImage(atleta.fotoUrl!)
              : null,
          child: atleta.fotoUrl == null
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
        ),
        title: Text(
          atleta.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EstatisticaAtletaScreen(
                partidaId: widget.partidaId,
                atleta: atleta,
                timeNome: timeNome,
                escudoUrl: escudoUrl,
              ),
            ),
          );
        },
      ),
    );
  }
}
