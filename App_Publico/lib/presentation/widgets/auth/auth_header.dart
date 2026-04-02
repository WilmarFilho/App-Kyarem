import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthHeader extends StatefulWidget {
  final bool isSmall;

  const AuthHeader({super.key, this.isSmall = false});

  @override
  State<AuthHeader> createState() => _AuthHeaderState();
}

class _AuthHeaderState extends State<AuthHeader> {
  // CACHE ESTÁTICO: Fica na memória durante toda a vida do App
  static Map<String, dynamic>? _cachedCampeonato;
  late Future<Map<String, dynamic>> _campeonatoFuture;

  @override
  void initState() {
    super.initState();
    // Se já tivermos o cache, retornamos ele imediatamente, senão fazemos o fetch
    _campeonatoFuture = _getCameponatoData();
  }

  Future<Map<String, dynamic>> _getCameponatoData() async {
    if (_cachedCampeonato != null) {
      return _cachedCampeonato!;
    }

    final campeonatoId = dotenv.get('CAMPEONATO_ID');
    try {
      final res = await Supabase.instance.client
          .from('campeonatos')
          .select('nome, escudo_url')
          .eq('id', campeonatoId)
          .single();

      _cachedCampeonato = res; // Salva no cache para a próxima vez
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
        padding: EdgeInsets.symmetric(vertical: widget.isSmall ? 25 : 40),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _campeonatoFuture, // Usa a variável inicializada no initState
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _cachedCampeonato == null) {
              return SizedBox(
                height: widget.isSmall ? 130 : 170,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return SizedBox(
                height: widget.isSmall ? 130 : 170,
                child: const Center(
                  child: Icon(Icons.error_outline, color: Colors.white),
                ),
              );
            }

            final data = snapshot.data!;
            final nomeCampeonato = data['nome'] as String;
            final escudoUrl = data['escudo_url'] as String;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(widget.isSmall ? 8 : 12),
                  child: Image.network(
                    escudoUrl,
                    width: widget.isSmall ? 60 : 80,
                    height: widget.isSmall ? 60 : 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultLogo(),
                  ),
                ),
                SizedBox(height: widget.isSmall ? 10 : 16),
                Text(
                  nomeCampeonato.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Bebas Neue',
                    fontWeight: FontWeight.w400,
                    fontSize: widget.isSmall ? 42 : 52,
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
                    fontSize: widget.isSmall ? 14 : 16,
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
      width: widget.isSmall ? 60 : 80,
      height: widget.isSmall ? 60 : 80,
    );
  }
}
