import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_widget.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo com Gradiente
          Container(
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.7, -0.6),
                radius: 1.5,
                colors: [
                  Color(0xFFD1FFDA),
                  Color(0xFFB7FFEB),
                  Color(0xFFCBFFFB),
                ],
              ),
            ),
          ),

          // Conteúdo Principal
          const SafeArea(
            child: Center(
              child: Text(
                'Configurações',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
          ),

          // Barra de Navegação
          const BottomNavigationWidget(currentRoute: '/configuracoes'),
        ],
      ),
    );
  }
}