import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  /// Busca o nome e o cargo do usuário via backend REST (/profiles/me/access).
  /// Usa o mesmo AuthService do restante do app — sem queries diretas ao Supabase.
  Future<_UserInfo> _fetchUserInfo() async {
    try {
      final profile = await AuthService().getUserProfile();

      final nome = profile['nomeExibicao']?.toString() ?? '';
      final role = profile['role']?.toString().toLowerCase() ?? '';
      final isAdmin = profile['isAdmin'] == true || role == 'admin';

      String cargo;
      if (isAdmin) {
        cargo = 'Administrador';
      } else if (role == 'presidente_atletica') {
        cargo = 'Presidente';
      } else {
        cargo = 'Árbitro';
      }

      return _UserInfo(nome: nome.isNotEmpty ? nome : cargo, cargo: cargo);
    } catch (e) {
      debugPrint('Erro ao buscar perfil do usuário: $e');
      return const _UserInfo(nome: 'Usuário', cargo: '');
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: FutureBuilder<_UserInfo>(
              future: _fetchUserInfo(),
              builder: (context, snapshot) {
                final info = snapshot.data;
                final nome = info?.nome ?? '...';
                final cargo = info?.cargo ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá $nome,',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        color: Color(0xFF1B1B1B),
                      ),
                    ),
                    if (cargo.isNotEmpty)
                      Text(
                        cargo,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF85C39),
                        ),
                      )
                    else
                      const Text(
                        'Seja bem vindo!',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B1B1B),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Row(
            children: [
              // Botão de Logout
              GestureDetector(
                onTap: () => _logout(context),
                child: const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFF555555),
                  child: Icon(Icons.logout, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              // Botão de Perfil
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/perfil'),
                child: const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0xFF555555),
                  child: Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserInfo {
  final String nome;
  final String cargo;
  const _UserInfo({required this.nome, required this.cargo});
}
