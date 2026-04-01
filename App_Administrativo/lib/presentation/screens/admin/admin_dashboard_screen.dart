import 'package:flutter/material.dart';
import '../../widgets/layout/bottom_navigation_widget.dart';
import '../../widgets/layout/gradient_background.dart';

import 'campeonatos_admin_screen.dart';
import 'atleticas_admin_screen.dart';
import 'equipes_admin_screen.dart';
import 'partidas_admin_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PAINEL\nADMINISTRATIVO',
                      style: TextStyle(
                        fontFamily: 'Bebas Neue',
                        fontSize: 40,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22.0),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        children: [
                          _buildAdminCard(
                            context,
                            'Campeonatos',
                            Icons.emoji_events,
                            Colors.amber.shade700,
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CampeonatosAdminScreen())),
                          ),
                          _buildAdminCard(
                            context,
                            'Partidas',
                            Icons.sports_soccer,
                            Colors.green.shade600,
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartidasAdminScreen())),
                          ),
                          _buildAdminCard(
                            context,
                            'Atléticas',
                            Icons.shield,
                            Colors.blue.shade600,
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AtleticasAdminScreen())),
                          ),
                          _buildAdminCard(
                            context,
                            'Times e Atletas',
                            Icons.groups,
                            Colors.purple.shade600,
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EquipesAdminScreen())),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const BottomNavigationWidget(currentRoute: '/admin'), // Ajustar ou adicionar rota admin no bottom nav
        ],
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 35, color: color),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
