import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../widgets/layout/app_bottom_navigation.dart';
import 'athletics_tab.dart';
import 'championships_tab.dart';
import 'home_tab.dart';
import 'profile_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final AuthService _authService = widget.authService ?? AuthService();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeTab(),
      const ChampionshipsTab(),
      const AthleticsTab(),
      ProfileTab(authService: _authService),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
