import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kyarem_eventos_publico/models/campeonato_model.dart';
import 'package:kyarem_eventos_publico/core/app_globals.dart';

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
    // Pequeno delay para garantir que a imagem seja renderizada
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    try {
      final campeonatoId = dotenv.get('CAMPEONATO_ID');
      final res = await Supabase.instance.client
          .from('campeonatos_vitrine')
          .select('*')
          .eq('campeonato_id', campeonatoId)
          .limit(1)
          .maybeSingle();

      if (res != null) {
        AppGlobals.campeonatoAtivo = Campeonato.fromMap(res);
      }
    } catch (e) {
      debugPrint('Erro ao buscar campeonato ativo: $e');
    }

    if (!mounted) return;

    // Decide para onde ir baseado na sessão
    final session = Supabase.instance.client.auth.currentSession;
    final nextRoute = session != null ? '/home' : '/login';

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
