import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../models/campeonato_model.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import 'home_screen.dart';
import 'modalidades_screen.dart';
import 'configuracoes_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

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
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
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
              const HomeScreen(isMainScreenChild: true),
              ModalidadesScreen(
                isMainScreenChild: true,
                campeonato: Campeonato(
                  id: dotenv.get('CAMPEONATO_ID'),
                  nome: dotenv.get('CAMPEONATO_NOME', fallback: 'Campeonato'),
                ),
              ),
              const ConfiguracoesScreen(isMainScreenChild: true),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: BottomNavigationWidget(
              currentIndex: _currentIndex,
              onTabSelected: _onTabSelected,
            ),
          ),
        ],
      ),
    );
  }
}
