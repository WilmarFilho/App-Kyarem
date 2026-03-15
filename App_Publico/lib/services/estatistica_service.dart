import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EstatisticaAtleta {
  final String atletaId;
  final String nomeAtleta;
  final String equipeNome;
  final String? equipeEscudoUrl;
  final String? fotoUrl;

  int gols;
  int cartoesAmarelos;
  int cartoesVermelhos;
  int faltas;
  int penaltis;

  EstatisticaAtleta({
    required this.atletaId,
    required this.nomeAtleta,
    required this.equipeNome,
    this.equipeEscudoUrl,
    this.fotoUrl,
    this.gols = 0,
    this.cartoesAmarelos = 0,
    this.cartoesVermelhos = 0,
    this.faltas = 0,
    this.penaltis = 0,
  });
}

class EstatisticaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Busca as estatísticas dos atletas em uma modalidade agrupando as ocorrências dos eventos.
  Future<List<EstatisticaAtleta>> buscarEstatisticasPorModalidade(
    String modalidadeId,
  ) async {
    try {
      // 1. Buscar todas as partidas da modalidade
      final partidasResponse = await _supabase
          .from('partidas')
          .select('id')
          .eq('modalidade_id', modalidadeId);

      if (partidasResponse.isEmpty) return [];

      final List<String> partidasIds = (partidasResponse as List)
          .map((p) => p['id'].toString())
          .toList();

      // 2. Buscar os eventos dessas partidas que tenham atleta vinculado e tipo de evento
      // Trazendo as relações de atleta, equipe e tipo de evento
      final eventosResponse = await _supabase
          .from('eventos_partida')
          .select('''
            *,
            atletas!eventos_partida_atleta_id_fkey(nome, atletica_id, foto_url),
            equipes!eventos_partida_equipe_id_fkey(nome_equipe, atleticas(escudo_url)),
            tipo_evento:tipo_evento_id(nome)
          ''')
          .inFilter('partida_id', partidasIds)
          .not('atleta_id', 'is', null);

      Map<String, EstatisticaAtleta> mapEstatisticas = {};

      for (var evento in (eventosResponse as List)) {
        final atletaId = evento['atleta_id']?.toString();
        if (atletaId == null) continue;

        // Extrai informações do atleta
        final atletaInfo = evento['atletas'];
        final nomeAtleta = atletaInfo?['nome'] ?? 'Desconhecido';
        final fotoUrl = atletaInfo?['foto_url'];

        // Extrai informações da equipe
        final equipeInfo = evento['equipes'];
        final nomeEquipe = equipeInfo?['nome_equipe'] ?? 'Time Desconhecido';
        final equipeEscudoUrl = equipeInfo?['atleticas']?['escudo_url'];

        // Extrai o tipo do evento para identificar gols, cartões, etc..
        final tipoEventoNome =
            evento['tipo_evento']?['nome']?.toString().toUpperCase() ?? '';

        if (!mapEstatisticas.containsKey(atletaId)) {
          mapEstatisticas[atletaId] = EstatisticaAtleta(
            atletaId: atletaId,
            nomeAtleta: nomeAtleta,
            equipeNome: nomeEquipe,
            equipeEscudoUrl: equipeEscudoUrl,
            fotoUrl: fotoUrl,
          );
        }

        final est = mapEstatisticas[atletaId]!;

        // Contabiliza gols e cartões
        if (tipoEventoNome.contains('GOL')) {
          est.gols += 1;
        } else if (tipoEventoNome.contains('AMARELO')) {
          est.cartoesAmarelos += 1;
        } else if (tipoEventoNome.contains('VERMELHO')) {
          est.cartoesVermelhos += 1;
        } else if (tipoEventoNome.contains('FALTA')) {
          est.faltas += 1;
        } else if (tipoEventoNome.contains('PENALTI')) {
          est.penaltis += 1;
        }
      }

      final estatisticasLista = mapEstatisticas.values.toList();

      // Ordena por gols (decrescente) como padrão
      estatisticasLista.sort((a, b) => b.gols.compareTo(a.gols));

      return estatisticasLista;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar estatísticas: $e');
      }
      return [];
    }
  }
}
