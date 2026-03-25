import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeHeader extends StatelessWidget {
  final String userName;

  const HomeHeader({super.key, this.userName = 'Wilmar'});

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
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // FutureBuilder para carregar o nome do banco de dados
          FutureBuilder<String>(
            future: _fetchUserName(),
            builder: (context, snapshot) {
              // Enquanto carrega, podemos mostrar um placeholder ou o nome padrão
              final displayUserName = snapshot.data ?? '...';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá $displayUserName,',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    'SEJA BEM VINDO!',
                    style: GoogleFonts.teko(
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.0,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              );
            },
          ),
          Row(
            children: [
              // Botão de Logout
              GestureDetector(
                onTap: () => _logout(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF22F1D).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF22F1D).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Color(0xFFF22F1D),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botão de Perfil
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/perfil'),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF22F1D).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF22F1D).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Color(0xFFF22F1D),
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
