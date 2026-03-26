import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class AtletaService {
  Future<List<Map<String, dynamic>>> getTopAthletes(
    String nomeTipoEvento,
  ) async {
    try {
      // 1. Busca o ID do tipo de evento
      final tipoEventoRes = await _supabase
          .from('tipos_eventos')
          .select('id')
          .ilike('nome', '%$nomeTipoEvento%')
          .maybeSingle();

      if (tipoEventoRes == null) return [];
      final tipoId = tipoEventoRes['id'];

      // 2. Busca eventos com a Foreign Key EXPLÍCITA
      final List<dynamic> res = await _supabase
          .from('eventos_partida')
          .select('''
          atleta_id,
          atleta:atletas!eventos_partida_atleta_id_fkey (
            nome,
            foto_url,
            atleticas ( nome )
          )
        ''')
          .eq('tipo_evento_id', tipoId);

      if (res.isEmpty) return [];

      // 3. Agrupamento e Contagem
      Map<String, int> contagem = {};
      Map<String, dynamic> infoAtleta = {};

      for (var item in res) {
        final dadosDoAtleta = item['atleta'];
        if (dadosDoAtleta == null) continue;

        String id = item['atleta_id'].toString();
        contagem[id] = (contagem[id] ?? 0) + 1;
        infoAtleta[id] = dadosDoAtleta;
      }

      // 4. Ordenação (Do maior para o menor)
      var sortedKeys = contagem.keys.toList()
        ..sort((a, b) => contagem[b]!.compareTo(contagem[a]!));

      // 5. Retorno apenas do MELHOR (Top 1)
      if (sortedKeys.isEmpty) return [];

      final idLider = sortedKeys.first;
      final atleta = infoAtleta[idLider];

      String modalidadeNome = "Geral";
      if (atleta['atleticas'] != null) {
        modalidadeNome = atleta['atleticas']['nome'];
      }

      return [
        {
          'nome': atleta['nome'] ?? 'Atleta',
          'modalidade': modalidadeNome,
          'valor': contagem[idLider].toString(),
          'label': nomeTipoEvento.toUpperCase() == 'GOL' ? 'GOL' : 'PONTO',
          'foto': atleta['foto_url'],
        },
      ];
    } catch (e) {
      debugPrint('ERRO NO SERVICE: $e');
      return [];
    }
  }
}
