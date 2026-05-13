import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/campeonato_model.dart';
import '../../../core/app_globals.dart';
import '../../../services/partida_service.dart';
import '../../../services/modalidade_service.dart';
import '../../../services/atleta_service.dart';
import '../../../services/atletica_public_service.dart';

import '../../widgets/layout/bottom_navigation_widget.dart';
import 'atleticas_screen.dart';
import 'home_screen.dart';
import 'modalidades_screen.dart';
import 'configuracoes_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  final SupabaseClient? supabaseClient;
  final PartidaService? partidaService;
  final ModalidadeService? modalidadeService;
  final AtletaService? atletaService;
  final AtleticaPublicService? atleticaPublicService;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
    this.supabaseClient,
    this.partidaService,
    this.modalidadeService,
    this.atletaService,
    this.atleticaPublicService,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isNavigatingFromTab = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    _isNavigatingFromTab = true;
    _pageController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
        .then((_) {
          if (mounted) {
            _isNavigatingFromTab = false;
          }
        });
  }

  void _onPageChanged(int index) {
    if (!_isNavigatingFromTab) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF260404),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: [
              HomeScreen(
                isMainScreenChild: true,
                onNavigateToTab: _onTabSelected,
                supabaseClient: widget.supabaseClient,
                partidaService: widget.partidaService,
                modalidadeService: widget.modalidadeService,
                atletaService: widget.atletaService,
              ),
              ModalidadesScreen(
                isMainScreenChild: true,
                campeonato:
                    AppGlobals.campeonatoAtivo ??
                    Campeonato(id: '', nome: 'Campeonato'),
                modalidadeService: widget.modalidadeService,
              ),
              AtleticasScreen(
                isMainScreenChild: true,
                atleticaService: widget.atleticaPublicService,
              ),
              const ConfiguracoesScreen(
                isMainScreenChild: true,
              ),
            ],
          ),
          BottomNavigationWidget(
            currentIndex: _currentIndex,
            onTabSelected: _onTabSelected,
          ),
        ],
      ),
    );
  }
}
