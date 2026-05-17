import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../widgets/layout/app_bottom_navigation.dart';
import 'athletics_tab.dart';
import 'championships_tab.dart';
import 'feed_tab.dart';
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
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _isNavigatingFromTab = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    _isNavigatingFromTab = true;
    _pageController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
        .then((_) {
          if (mounted) _isNavigatingFromTab = false;
        });
  }

  void _onPageChanged(int index) {
    if (!_isNavigatingFromTab) {
      setState(() => _currentIndex = index);
    }
  }

  void _goToProfileTab() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileTab(authService: _authService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              children: [
                HomeTab(onProfileTap: _goToProfileTab),
                const ChampionshipsTab(),
                const AthleticsTab(),
                const FeedTab(),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
