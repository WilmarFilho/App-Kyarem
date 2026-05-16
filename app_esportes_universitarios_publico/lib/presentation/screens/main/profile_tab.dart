import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../widgets/shared/page_header.dart';
import '../../widgets/shared/section_card.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final nome = metadata['nome_exibicao'] as String? ?? user?.email ?? 'Usuario';
    final cpf = metadata['cpf'] as String?;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        PageHeader(
          title: 'Perfil',
          subtitle:
              'Conta base do app geral. O cadastro sempre nasce com role USER e pode ganhar papeis contextuais depois.',
          action: IconButton(
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ),
        const SizedBox(height: 20),
        SectionCard(
          title: nome,
          description:
              'E-mail: ${user?.email ?? '-'}\nCPF: ${cpf ?? 'Nao informado no metadata'}',
          icon: Icons.badge_rounded,
          badge: 'USER',
        ),
        const SizedBox(height: 12),
        const SectionCard(
          title: 'Proximas integracoes',
          description:
              'Aqui entram edicao de perfil, foto, telefone, dados do atleta, papeis contextuais e permissao de gestao quando vierem do backend.',
          icon: Icons.account_tree_rounded,
        ),
      ],
    );
  }
}
