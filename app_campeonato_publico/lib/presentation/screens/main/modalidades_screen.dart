import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';

import '../../../models/campeonato_model.dart';
import '../../../models/modalidade_model.dart';
import 'package:kyarem_eventos_publico/services/estatistica_service.dart';
import 'package:kyarem_eventos_publico/services/modalidade_service.dart';
import 'package:kyarem_eventos_publico/services/partida_service.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';
import '../modalidade/partidas_modalidade_screen.dart';
import 'main_screen.dart';

IconData _getModalidadeIcon(String nome) {
  final n = nome.toLowerCase();
  if (n.contains('futsal') || n.contains('futebol') || n.contains('campo')) {
    return Icons.sports_soccer_rounded;
  } else if (n.contains('basquete')) {
    return Icons.sports_basketball_rounded;
  } else if (n.contains('volei') || n.contains('vôlei')) {
    return Icons.sports_volleyball_rounded;
  } else if (n.contains('handebol')) {
    return Icons.sports_handball_rounded;
  } else if (n.contains('tenis') || n.contains('tênis')) {
    return Icons.sports_tennis_rounded;
  } else if (n.contains('e-sports') || n.contains('game')) {
    return Icons.sports_esports_rounded;
  }
  return Icons.sports_rounded; // Ícone padrão
}

class ModalidadesScreen extends StatefulWidget {
  final Campeonato campeonato;
  final bool isMainScreenChild;
  final ModalidadeService? modalidadeService;
  final PartidaService? partidaService;
  final EstatisticaService? estatisticaService;

  const ModalidadesScreen({
    super.key,
    required this.campeonato,
    this.isMainScreenChild = false,
    this.modalidadeService,
    this.partidaService,
    this.estatisticaService,
  });

  @override
  State<ModalidadesScreen> createState() => _ModalidadesScreenState();
}

class _ModalidadesScreenState extends State<ModalidadesScreen> {
  late final ModalidadeService _service =
      widget.modalidadeService ?? ModalidadeService();
  late Future<List<Modalidade>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getModalities();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.getModalities();
    });
  }

  void _onBottomTabSelected(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainScreen(initialIndex: index)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = AppColors.primary;
    const Color accentColor = AppColors.orange;

    return Scaffold(
      backgroundColor: const Color(0xFF110101), // Fundo bem escuro
      body: Stack(
        children: [
          const GradientBackground(),

          CustomScrollView(
            slivers: [
              // === HEADER PREMIUM COM GRADIENTE ===
              SliverAppBar(
                expandedHeight: 100.0,
                floating: false,
                pinned: true,
                automaticallyImplyLeading:
                    false, // Remove a seta e o espaço dela
                elevation: 0,
                backgroundColor:
                    Colors.transparent, // Deixa o gradiente brilhar
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets
                      .zero, // Remove o padding que joga o texto para baixo
                  title: Container(
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 22, top: 32),
                    child: Text(
                      'MODALIDADES',
                      textAlign: TextAlign.left,
                      style: GoogleFonts.oswald(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentColor, primaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),
              // === LISTA DE MODALIDADES ===
              FutureBuilder<List<Modalidade>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    );
                  }

                  final modalidades = snap.data ?? [];

                  if (modalidades.isEmpty) {
                    return SliverFillRemaining(child: _buildEmptyState());
                  }

                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      24,
                      18,
                      widget.isMainScreenChild ? 100 : 120,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, i) {
                        final m = modalidades[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildModalidadeCard(m),
                        );
                      }, childCount: modalidades.length),
                    ),
                  );
                },
              ),
            ],
          ),

          if (!widget.isMainScreenChild)
            BottomNavigationWidget(
              currentIndex: 1,
              onTabSelected: _onBottomTabSelected,
            ),
        ],
      ),
    );
  }

  Widget _buildModalidadeCard(Modalidade m) {
    final titulo = (m.nome ?? 'Modalidade').toUpperCase();
    final subtitulo = (m.esporteNome ?? '').trim();
    final iconData = _getModalidadeIcon(m.nome ?? '');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4), // Respiro entre cards
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        // Sutil sombra para dar profundidade sobre o fundo escuro
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PartidasModalidadeScreen(
                    modalidade: m,
                    partidaService: widget.partidaService,
                    estatisticaService: widget.estatisticaService,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // ÍCONE DINÂMICO COM GRADIENTE
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFF2561D).withValues(alpha: 0.15),
                          const Color(0xFFF22F1D).withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFF22F1D).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      iconData,
                      color: const Color(0xFFF22F1D),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // TEXTOS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          titulo,
                          style: GoogleFonts.oswald(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitulo.isNotEmpty ? subtitulo : "Ver competições",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // INDICADOR DE AÇÃO
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Nenhuma modalidade encontrada.',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: _reload,
            child: const Text(
              'Tentar novamente',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
