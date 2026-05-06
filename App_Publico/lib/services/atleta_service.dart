import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class AtletaService {
  static final Map<String, List<Map<String, dynamic>>> _cachedTopAthletes = {};
  static final Map<String, DateTime> _lastCacheTime = {};

  Future<List<Map<String, dynamic>>> getTopAthletes(
    String nomeTipoEvento, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedTopAthletes.containsKey(nomeTipoEvento) &&
        _lastCacheTime.containsKey(nomeTipoEvento)) {
      if (DateTime.now().difference(_lastCacheTime[nomeTipoEvento]!).inMinutes <
          5) {
        return _cachedTopAthletes[nomeTipoEvento]!;
      }
    }

    try {
      // Busca o melhor jogador (com mais pontos/gols)
      final res = await _supabase
          .from('artilharia')
          .select('*')
          // Se tiver modalidade, seria bom filtrar, mas aqui estamos fazendo geral.
          .order('pontuacoes', ascending: false)
          .limit(1);

      if (res.isEmpty) return [];

      final item = res.first;

      final result = [
        {
          'atleta_id': item['atleta_id'],
          'nome': item['nome_exibicao'] ?? 'Atleta',
          'modalidade': item['atletica_nome'] ?? 'Geral',
          'time_escudo': item['atletica_escudo_url'],
          'valor': item['pontuacoes']?.toString() ?? '0',
          'label': nomeTipoEvento.toUpperCase() == 'GOL' ? 'GOL' : 'PONTO',
          'foto': item['foto_url'],
        },
      ];

      _cachedTopAthletes[nomeTipoEvento] = result;
      _lastCacheTime[nomeTipoEvento] = DateTime.now();

      return result;
    } catch (e) {
      debugPrint('ERRO NO SERVICE: $e');
      return [];
    }
  }
}
