import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/modalidade_model.dart';
import '../core/app_globals.dart';

final SupabaseClient _supabase = Supabase.instance.client;

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
      final campId = AppGlobals.campeonatoAtivo?.id;
      if (campId == null || campId.isEmpty) {
        return [];
      }

      final res = await _supabase
          .from('modalidades_vitrine')
          .select('*')
          .eq('campeonato_id', campId);

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
