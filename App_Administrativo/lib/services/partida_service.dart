import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/partida_model.dart';
import '../models/arbitro_model.dart';
import '../models/campeonato_model.dart';
import '../models/tipo_evento_model.dart';

class PartidaService {
  final _supabase = Supabase.instance.client;

  Future<List<dynamic>> buscarDadosPorAba(String aba) async {
    try {
      if (aba == 'Jogos') {
        return await listarPartidasDoDia();
      } else if (aba == 'Árbitros') {
        final response = await _supabase
            .from('profiles')
            .select('*')
            .eq('role', 'arbitro')
            .order('nome_exibicao');
        return (response as List).map((m) => Arbitro.fromMap(m)).toList();
      } else {
        // Campeonatos
        final response = await _supabase
            .from('campeonatos')
            .select('*')
            .order('nome');
        return (response as List).map((m) => Campeonato.fromMap(m)).toList();
      }
    } catch (e) {
      return [];
    }
  }

  /// Busca as partidas diretamente do banco via Service
  Future<List<Partida>> listarPartidasDoDia() async {
    try {
      // Fazemos a query complexa aqui, incluindo os joins necessários
      final response = await _supabase
          .from('partidas')
          .select('''
            *,
            equipe_a:equipes!partidas_equipe_a_id_fkey(*, atleticas(*)),
            equipe_b:equipes!partidas_equipe_b_id_fkey(*, atleticas(*))
          ''')
          .order('iniciada_em', ascending: true);

      // Converte a lista de Maps em uma lista de objetos Partida
      final partidas = (response as List)
          .map((m) => Partida.fromMap(m))
          .toList();

      // Regra de negócio: Você pode filtrar apenas as que não foram encerradas, por exemplo
      return partidas;
    } catch (e) {
      return [];
    }
  }

  /// Salvar novo evento da partida
  Future<void> salvarEvento({
    required String partidaId,
    required String tipoEventoId,
    String? equipeId,
    String? atletaId, // UUID do atleta
    String? atletaSaiId, // UUID do atleta que sai (em caso de substituição)
    required int tempoFormatado, // Texto como "08:15"
    String? descricao,
    bool isSubstitution = false,
  }) async {
    try {
      await _supabase.from('eventos_partida').insert({
        'partida_id': partidaId,
        'tipo_evento_id': tipoEventoId,
        'equipe_id': equipeId,
        'atleta_id': atletaId,
        'atleta_sai_id': atletaSaiId,
        'tempo_cronometro': tempoFormatado,
        'descricao_detalhada': descricao,
        'is_substitution': isSubstitution,
        'criado_em': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Busca tipos de eventos do esporte da modalidade específica
  Future<List<TipoEventoEsporte>> buscarTiposDeEventoDaPartida(
    String modalidadeId,
  ) async {
    try {
      // 1. Busca a modalidade para obter o esporte_id vinculado
      final modalidadeData = await _supabase
          .from('modalidades')
          .select('esporte_id')
          .eq('id', modalidadeId)
          .single();

      final String? esporteId = modalidadeData['esporte_id'];

      if (esporteId == null) return [];

      // 2. Com o esporte_id, buscamos todos os tipos de eventos associados a esse esporte
      // Note: No seu banco a tabela chama-se 'tipos_eventos'
      final List<dynamic> eventosData = await _supabase
          .from('tipos_eventos')
          .select('*')
          .eq('esporte_id', esporteId);

      // 3. Converte para sua lista de modelos
      return eventosData.map((e) => TipoEventoEsporte.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Exemplo de lógica para "Ver Meus" (filtros locais)
  List<Partida> filtrarPorAtletica(List<Partida> lista, String atleticaId) {
    return lista
        .where(
          (p) =>
              p.equipeA?.atleticaId == atleticaId ||
              p.equipeB?.atleticaId == atleticaId,
        )
        .toList();
  }
}
