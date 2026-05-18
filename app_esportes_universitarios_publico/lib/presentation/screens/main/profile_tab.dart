import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../models/user_profile.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../widgets/shared/page_header.dart';
import '../../widgets/shared/section_card.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final ProfileService _profileService = ProfileService();
  Future<UserProfile?>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileService.getMyProfile();
  }

  Future<void> _handleLogout() async {
    try {
      await widget.authService.signOut();
    } catch (_) {}
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: const Text(
          'Perfil',
          style: TextStyle(color: AppColors.primary),
        ),
      ),
      body: FutureBuilder<UserProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = widget.authService.currentUser;
          final profile = snapshot.data;

          final nome = profile?.nomeExibicao ?? user?.userMetadata?['nome_exibicao'] ?? user?.email ?? 'Usuário';
          final email = user?.email ?? '-';
          final cpf = user?.userMetadata?['cpf'];
          final role = profile?.role ?? 'USER';

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              PageHeader(
                title: 'Minha Conta',
                subtitle:
                    'Conta base do app geral. O cadastro sempre nasce com role USER e pode ganhar papéis contextuais depois.',
                action: IconButton(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                  tooltip: 'Sair da conta',
                ),
              ),
              const SizedBox(height: 20),
              SectionCard(
                title: nome,
                description: 'E-mail: $email\nCPF: ${cpf ?? 'Não informado'}\nPapel: $role',
                icon: Icons.badge_rounded,
                badge: role,
              ),
              const SizedBox(height: 12),
              const SectionCard(
                title: 'Próximas integrações',
                description:
                    'Aqui entram edição de perfil, foto, telefone, dados do atleta, papéis contextuais e permissão de gestão quando vierem do backend.',
                icon: Icons.account_tree_rounded,
              ),
            ],
          );
        },
      ),
    );
  }
}
