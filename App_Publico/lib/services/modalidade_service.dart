import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/modalidade_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final SupabaseClient _supabase = Supabase.instance.client;

final String campeonatoId = dotenv.get('CAMPEONATO_ID');

class ModalidadeService {
  Future<List<Modalidade>> getModalities() async {
    try {
      final res = await _supabase
          .from('modalidades')
          .select('*')
          .eq('campeonato_id', campeonatoId);

      return (res as List)
          .map((e) => Modalidade.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('listarModalidadesPorCampeonato error: $e');
    }
    return [];
  }
}
