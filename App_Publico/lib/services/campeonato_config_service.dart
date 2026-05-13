import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_globals.dart';
import '../models/campeonato_model.dart';

class CampeonatoConfigService {
  static Future<Campeonato?> loadCampeonatoAtivo() async {
    try {
      final campeonatoId = dotenv.get('CAMPEONATO_ID');
      final res = await Supabase.instance.client
          .from('campeonatos_vitrine')
          .select('*')
          .eq('campeonato_id', campeonatoId)
          .limit(1)
          .maybeSingle();

      if (res == null) return null;

      final campeonato = Campeonato.fromMap(res);
      AppGlobals.campeonatoAtivo = campeonato;
      return campeonato;
    } catch (e, st) {
      debugPrint('Erro ao buscar campeonato ativo: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }
}
