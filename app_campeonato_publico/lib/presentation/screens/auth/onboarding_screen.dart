import 'package:flutter/material.dart';
import 'package:balanced_text/balanced_text.dart';
import 'package:kyarem_eventos_publico/core/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/auth/auth_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _loading = false;

  Future<void> _continuar() async {
    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('public_onboarding_seen', true);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 393;

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            const GradientBackground(),
            Column(
              children: [
                AuthHeader(isSmall: isSmallScreen),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isSmallScreen ? 34 : 40,
                        isSmallScreen ? 50 : 160,
                        isSmallScreen ? 34 : 40,
                        20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Bem-vindo',
                            textAlign: TextAlign.center,
                            textWidthBasis: TextWidthBasis.longestLine,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: isSmallScreen ? 26 : 32,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 20 : 30),
                          BalancedText(
                            'Acompanhe todos os detalhes do campeonato em tempo real! Gols, estatísticas, eventos da partida e muito mais.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 40 : 60),
                          AuthButton(
                            text: 'Continuar',
                            onPressed: _continuar,
                            isLoading: _loading,
                            isSmall: isSmallScreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
