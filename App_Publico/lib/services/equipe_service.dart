import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/atletica_equipe_model.dart';

class EquipeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Equipe?> getTeamById(String id) async {
    try {
      final res = await _supabase
          .from('equipes')
          .select('*, atleticas(nome, logo_url)')
          .eq('id', id)
          .maybeSingle();

      if (res != null) {
        return Equipe.fromMap(Map<String, dynamic>.from(res));
      }
    } catch (e) {
      debugPrint('getTeamById error: $e');
    }
    return null;
  }
}
