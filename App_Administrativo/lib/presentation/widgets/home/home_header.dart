import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  // Função para buscar o nome na tabela 'profiles'
  Future<String> _fetchUserName() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return 'Usuário';

      final data = await Supabase.instance.client
          .from('profiles')
          .select('nome_exibicao')
          .eq('id', user.id)
          .single();

      return data['nome_exibicao'] ?? 'Árbitro';
    } catch (e) {
      debugPrint('Erro ao buscar nome do perfil: $e');
      return 'Árbitro';
    }
  }

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
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
            child: FutureBuilder<String>(
              future: _fetchUserName(),
              builder: (context, snapshot) {
                final displayUserName = snapshot.data ?? '...';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá $displayUserName,',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        color: Color(0xFF1B1B1B),
                      ),
                    ),
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
