import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_globals.dart';
import '../../../services/campeonato_config_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    if (AppGlobals.campeonatoAtivo == null) {
      await CampeonatoConfigService.loadCampeonatoAtivo();
    }

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool('public_onboarding_seen') ?? false;
    final nextRoute = onboardingSeen ? '/home' : '/login';

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(nextRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF260404),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/splash.png', fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}
