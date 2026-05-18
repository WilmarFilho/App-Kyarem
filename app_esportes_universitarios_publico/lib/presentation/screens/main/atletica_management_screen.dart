import 'package:flutter/material.dart';

import '../../../../core/app_colors.dart';
import '../../../../models/atletica.dart';
import 'atletica_edit_screen.dart';
import 'atletica_roster_screen.dart';
import 'atletica_enrollment_screen.dart';

class AtleticaManagementScreen extends StatelessWidget {
  final MinhaAtletica minhaAtletica;

  const AtleticaManagementScreen({super.key, required this.minhaAtletica});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Gestão: ${minhaAtletica.atleticaNome ?? "Atlética"}',
          style: const TextStyle(
            color: AppColors.primary,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildManagementCard(
            context,
            title: 'Informações da Atlética',
            description:
                'Edite o nome, sigla, logo e cor principal da atlética.',
            icon: Icons.edit_document,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AtleticaEditScreen(minhaAtletica: minhaAtletica),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildManagementCard(
            context,
            title: 'Participação em Campeonatos',
            description:
                'Gerencie equipes, inscreva times e controle o elenco em campeonatos ativos.',
            icon: Icons.emoji_events_outlined,
            color: const Color(0xFF7C3AED),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AtleticaEnrollmentScreen(
                      minhaAtletica: minhaAtletica),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildManagementCard(
            context,
            title: 'Elenco de Atletas',
            description:
                'Convoque alunos do app para o quadro de atletas da atlética.',
            icon: Icons.person_add,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AtleticaRosterScreen(minhaAtletica: minhaAtletica),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? AppColors.secondary;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EDF5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
