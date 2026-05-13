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
  /// [modalidadeId] é o campeonato_modalidade_id.
  Future<List<EstatisticaAtleta>> getEstatisticsByModality(
    String modalidadeId,
  ) async {
    try {
      // 1. Buscar todas as partidas da modalidade nas duas tabelas públicas
      final pAoVivo = await _supabase
          .from('partidas_ao_vivo')
          .select('partida_id')
          .eq('campeonato_modalidade_id', modalidadeId);

      final pHist = await _supabase
          .from('partidas_historico')
          .select('partida_id')
          .eq('campeonato_modalidade_id', modalidadeId);

      final List<String> partidasIds = [];
      partidasIds.addAll(
        (pAoVivo as List).map((p) => p['partida_id'].toString()),
      );
      partidasIds.addAll(
        (pHist as List).map((p) => p['partida_id'].toString()),
      );

      if (partidasIds.isEmpty) return [];

      // 2. Buscar os eventos dessas partidas que tenham atleta vinculado no schema public
      final eventosResponse = await _supabase
          .from('eventos_partida_publicos')
          .select('*')
          .inFilter('partida_id', partidasIds)
          .not('atleta_id', 'is', null);

      Map<String, EstatisticaAtleta> mapEstatisticas = {};

      for (var evento in (eventosResponse as List)) {
        final atletaId = evento['atleta_id']?.toString();
        if (atletaId == null) continue;

        final nomeAtleta =
            evento['atleta_nome_exibicao'] ?? 'Desconhecido';
        final fotoUrl = evento['atleta_foto_url'];
        final nomeEquipe = evento['equipe_nome'] ?? 'Time Desconhecido';
        // equipe_cor foi removido na revisão 12.5 — não usa mais
        const String? equipeEscudoUrl = null;

        // Usa tipo_evento_codigo (campo correto) ou tipo_evento_nome como fallback
        final tipoEventoCodigo =
            (evento['tipo_evento_codigo']?.toString() ??
                    evento['tipo_evento_nome']?.toString() ??
                    '')
                .toUpperCase();

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

        // Contabiliza gols e cartões usando o código do evento
        if (tipoEventoCodigo.contains('GOL') ||
            tipoEventoCodigo.contains('CESTA') ||
            tipoEventoCodigo.contains('PONTO')) {
          est.gols += 1;
        } else if (tipoEventoCodigo.contains('AMARELO')) {
          est.cartoesAmarelos += 1;
        } else if (tipoEventoCodigo.contains('VERMELHO')) {
          est.cartoesVermelhos += 1;
        } else if (tipoEventoCodigo.contains('FALTA')) {
          est.faltas += 1;
        } else if (tipoEventoCodigo.contains('PENALTI')) {
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
