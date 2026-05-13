import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';

import '../../../models/campeonato_atletica_publica_model.dart';
import '../../../services/atletica_public_service.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';
import '../atletica/atletica_detalhe_screen.dart';

class AtleticasScreen extends StatefulWidget {
  final bool isMainScreenChild;
  final AtleticaPublicService? atleticaService;

  const AtleticasScreen({
    super.key,
    this.isMainScreenChild = false,
    this.atleticaService,
  });

  @override
  State<AtleticasScreen> createState() => _AtleticasScreenState();
}

class _AtleticasScreenState extends State<AtleticasScreen> {
  late final AtleticaPublicService _service =
      widget.atleticaService ?? AtleticaPublicService();
  late Future<List<CampeonatoAtleticaPublica>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getAthletics();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.getAthletics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          const GradientBackground(),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 100,
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
                      'ATLÉTICAS',
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
                        colors: [AppColors.orange, AppColors.primary],
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
              SliverFillRemaining(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  color: AppColors.primary,
                  child: FutureBuilder<List<CampeonatoAtleticaPublica>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }

                      final atleticas = snapshot.data ?? [];
                      if (atleticas.isEmpty) {
                        return ListView(
                          padding: EdgeInsets.only(
                            top: 120,
                            bottom: widget.isMainScreenChild ? 100 : 120,
                          ),
                          children: const [
                            Center(
                              child: Text(
                                'Nenhuma atlética inscrita encontrada.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          18,
                          20,
                          18,
                          widget.isMainScreenChild ? 100 : 120,
                        ),
                        itemCount: atleticas.length,
                        itemBuilder: (context, index) =>
                            _buildAtleticaCard(atleticas[index]),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          if (!widget.isMainScreenChild)
            const BottomNavigationWidget(currentIndex: 2),
        ],
      ),
    );
  }

  Widget _buildAtleticaCard(CampeonatoAtleticaPublica atletica) {
    final hasLogo = atletica.escudoUrl != null && atletica.escudoUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AtleticaDetalheScreen(
                  atletica: atletica,
                  atleticaService: _service,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  backgroundImage: hasLogo
                      ? NetworkImage(atletica.escudoUrl!)
                      : null,
                  child: !hasLogo
                      ? Text(
                          (atletica.sigla ?? atletica.nome)
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        atletica.nome.toUpperCase(),
                        style: GoogleFonts.oswald(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if ((atletica.sigla ?? '').isNotEmpty)
                        Text(
                          atletica.sigla!,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white30,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
