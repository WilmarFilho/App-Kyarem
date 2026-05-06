import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/modalidade_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final SupabaseClient _supabase = Supabase.instance.client;

final String campeonatoId = dotenv.get('CAMPEONATO_ID');

class ModalidadeService {
  static List<Modalidade>? _cachedModalidades;
  static DateTime? _lastCacheTime;

  Future<List<Modalidade>> getModalities({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedModalidades != null && _lastCacheTime != null) {
      if (DateTime.now().difference(_lastCacheTime!).inMinutes < 5) {
        return _cachedModalidades!;
      }
    }

    try {
      final res = await _supabase
          .from('modalidades_vitrine')
          .select('*')
          .eq('campeonato_id', campeonatoId)
          .eq('status', 'ativa');

      _cachedModalidades = (res as List)
          .map((e) => Modalidade.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      _lastCacheTime = DateTime.now();

      return _cachedModalidades!;
    } catch (e) {
      debugPrint('listarModalidadesPorCampeonato error: $e');
    }
    return [];
  }
}
