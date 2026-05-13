import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_globals.dart';
import '../models/campeonato_atletica_publica_model.dart';
import '../models/campeonato_time_publico_model.dart';

class AtleticaPublicService {
  final SupabaseClient _supabase;

  AtleticaPublicService({SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? Supabase.instance.client;

  Future<List<CampeonatoAtleticaPublica>> getAthletics() async {
    final campeonatoId = AppGlobals.campeonatoAtivo?.id;
    if (campeonatoId == null || campeonatoId.isEmpty) return [];

    final res = await _supabase
        .from('campeonato_atleticas_publicos')
        .select('*')
        .eq('campeonato_id', campeonatoId)
        .order('atletica_nome', ascending: true);

    return (res as List)
        .map(
          (item) => CampeonatoAtleticaPublica.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<AtleticaStatsResumo> getStatsForAthletics(String atleticaId) async {
    final campeonatoId = AppGlobals.campeonatoAtivo?.id;
    if (campeonatoId == null || campeonatoId.isEmpty) {
      return const AtleticaStatsResumo();
    }

    final res = await _supabase
        .from('partidas_historico')
        .select(
          'time_a_atletica_id, time_b_atletica_id, placar_a, placar_b, resultado',
        )
        .eq('campeonato_id', campeonatoId)
        .or('time_a_atletica_id.eq.$atleticaId,time_b_atletica_id.eq.$atleticaId');

    int jogos = 0;
    int vitorias = 0;
    int empates = 0;
    int derrotas = 0;
    int golsPro = 0;
    int golsContra = 0;

    for (final item in (res as List)) {
      final row = Map<String, dynamic>.from(item);
      final isA = row['time_a_atletica_id']?.toString() == atleticaId;
      final isB = row['time_b_atletica_id']?.toString() == atleticaId;
      if (!isA && !isB) continue;

      final placarA = (row['placar_a'] as num?)?.toInt() ?? 0;
      final placarB = (row['placar_b'] as num?)?.toInt() ?? 0;

      jogos++;
      golsPro += isA ? placarA : placarB;
      golsContra += isA ? placarB : placarA;

      if (placarA == placarB) {
        empates++;
      } else if ((isA && placarA > placarB) || (isB && placarB > placarA)) {
        vitorias++;
      } else {
        derrotas++;
      }
    }

    return AtleticaStatsResumo(
      jogos: jogos,
      vitorias: vitorias,
      empates: empates,
      derrotas: derrotas,
      golsPro: golsPro,
      golsContra: golsContra,
    );
  }

  Future<List<CampeonatoTimePublico>> getTeamsForAthletics(
    String campeonatoAtleticaId,
  ) async {
    final res = await _supabase
        .from('campeonato_times_publicos')
        .select('*')
        .eq('campeonato_atletica_id', campeonatoAtleticaId)
        .order('modalidade_nome', ascending: true);

    return (res as List)
        .map(
          (item) => CampeonatoTimePublico.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}
