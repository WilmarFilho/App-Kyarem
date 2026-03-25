import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthHeader extends StatelessWidget {
  final bool isSmall;

  const AuthHeader({super.key, this.isSmall = false});

  Future<Map<String, dynamic>> _fetchCampeonato() async {
    final campeonatoId = dotenv.get('CAMPEONATO_ID');

    try {
      final res = await Supabase.instance.client
          .from('campeonatos')
          .select('nome, escudo_url')
          .eq('id', campeonatoId)
          .single();

      return res;
    } catch (e) {
      debugPrint('Erro ao buscar campeonato: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isSmall ? 25 : 40),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchCampeonato(),
          builder: (context, snapshot) {
            // Exibe loading enquanto espera os dados
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            // Caso ocorra erro (ID inexistente ou falha de rede)
            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(
                child: Icon(Icons.error_outline, color: Colors.white),
              );
            }

            final data = snapshot.data!;
            final nomeCampeonato = data['nome'] as String;
            final escudoUrl = data['escudo_url'] as String;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
                  child: Image.network(
                    escudoUrl,
                    width: isSmall ? 60 : 80,
                    height: isSmall ? 60 : 80,
                    fit: BoxFit.cover,
                    // Caso a URL falhe ao carregar a imagem real
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultLogo(),
                  ),
                ),
                SizedBox(height: isSmall ? 10 : 16),
                Text(
                  nomeCampeonato.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontWeight: FontWeight.w400,
                    fontSize: isSmall ? 42 : 52,
                    color: Colors.white,
                    height: 1.0,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Área Pública',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isSmall ? 14 : 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefaultLogo() {
    return SvgPicture.asset(
      'assets/images/meteor.svg',
      width: isSmall ? 60 : 80,
      height: isSmall ? 60 : 80,
    );
  }
}
