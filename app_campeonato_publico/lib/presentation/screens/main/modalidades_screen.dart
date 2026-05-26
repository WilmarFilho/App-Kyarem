import 'dart:ui';
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

  // MAPA PARA CONFIGURAR IMAGEM E DESCRIÇÃO POR MODALIDADE
  // As chaves devem estar em letras minúsculas (ex: 'futsal', 'basquete', 'vôlei')
  // Se o nome da modalidade vinda da API contiver essa palavra, usará as info do map.
  static const Map<String, Map<String, String>> _modalidadeInfo = {
    'futsal': {
      'imagem':
          'https://hlgnackuzfhkhloemtey.supabase.co/storage/v1/object/public/social-posts/dc6cee27-804e-4057-939d-9ea964139857/img2.png',
      'descricao': 'A emoção nas quadras',
    },
    'futebol': {
      'imagem':
          'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?q=80&w=600&auto=format&fit=crop',
      'descricao': 'A paixão nacional',
    },
    'basquete': {
      'imagem':
          'https://hlgnackuzfhkhloemtey.supabase.co/storage/v1/object/public/social-posts/dc6cee27-804e-4057-939d-9ea964139857/img1.png',
      'descricao': 'Cestas e enterradas',
    },
    'vôlei': {
      'imagem':
          'https://images.unsplash.com/photo-1592656094267-764a45160876?q=80&w=600&auto=format&fit=crop',
      'descricao': 'Saques e cortadas perfeitas',
    },
    'volei': {
      'imagem':
          'https://images.unsplash.com/photo-1592656094267-764a45160876?q=80&w=600&auto=format&fit=crop',
      'descricao': 'Saques e cortadas perfeitas',
    },
    'handebol': {
      'imagem':
          'https://images.unsplash.com/photo-1589828139335-51d279183427?q=80&w=600&auto=format&fit=crop',
      'descricao': 'Força e agilidade em quadra',
    },
    'tênis': {
      'imagem':
          'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?q=80&w=600&auto=format&fit=crop',
      'descricao': 'Disputas acirradas',
    },
    'tenis': {
      'imagem':
          'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?q=80&w=600&auto=format&fit=crop',
      'descricao': 'Disputas acirradas',
    },
    'e-sports': {
      'imagem':
          'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=600&auto=format&fit=crop',
      'descricao': 'Batalhas virtuais épicas',
    },
    'game': {
      'imagem':
          'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=600&auto=format&fit=crop',
      'descricao': 'Batalhas virtuais épicas',
    },
  };

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
                pinned: true,
                automaticallyImplyLeading: false,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.zero,
                  title: Container(
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
              SliverFillRemaining(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _reload,
                  child: FutureBuilder<List<Modalidade>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }

                      final modalidades = snap.data ?? [];

                      if (modalidades.isEmpty) {
                        return ListView(
                          padding: EdgeInsets.only(
                            top: 120,
                            bottom: widget.isMainScreenChild ? 100 : 120,
                          ),
                          children: [_buildEmptyState()],
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          18,
                          24,
                          18,
                          widget.isMainScreenChild ? 100 : 120,
                        ),
                        itemCount: modalidades.length,
                        itemBuilder: (context, i) {
                          final m = modalidades[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: _buildModalidadeCard(m),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
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

    // Busca informações no mapa criado acima
    final nomeLower = (m.nome ?? '').toLowerCase();
    String? matchedKey;
    for (final key in _modalidadeInfo.keys) {
      if (nomeLower.contains(key)) {
        matchedKey = key;
        break;
      }
    }
    final info = matchedKey != null ? _modalidadeInfo[matchedKey] : null;

    final imageUrl =
        info?['imagem'] ??
        'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?q=80&w=600&auto=format&fit=crop';
    final descricao =
        info?['descricao'] ??
        (subtitulo.isNotEmpty ? subtitulo : "Ver competições");

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade900,
                  child: const Icon(
                    Icons.sports,
                    color: Colors.white54,
                    size: 50,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          titulo,
                          style: GoogleFonts.oswald(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          descricao,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
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
                ),
              ),
            ),
          ],
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
