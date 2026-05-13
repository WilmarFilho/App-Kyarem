import 'package:supabase_flutter/supabase_flutter.dart';

class EventoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Mapeamento de códigos/nomes crus do banco → nomes amigáveis para exibição
  static const Map<String, String> friendlyNames = {
    'INICIO_1_TEMPO': 'Início do 1° Tempo',
    'FIM_1_TEMPO': 'Fim do 1° Tempo',
    'FIM_2_TEMPO': 'Fim do 2° Tempo',
    'INICIO_2_TEMPO': 'Início do 2° Tempo',
    'FIM_PARTIDA': 'Fim da Partida',
    'GOL': 'Gol',
    'FALTA': 'Falta',
    'CARTAO_AMARELO': 'Cartão Amarelo',
    'CARTAO_VERMELHO': 'Cartão Vermelho',
    'SUBSTITUICAO': 'Substituição',
    'PENALTI_MARCADO': 'Pênalti Marcado',
    'PENALTI': 'Pênalti',
    'PENALTI_PERDIDO': 'Pênalti Perdido',
    'TIRO_LIVRE_DIRETO': 'Tiro Livre Direto',
    'TIRO_DE_CANTO': 'Tiro de Canto',
    'TIRO_DE_SAIDA': 'Tiro de Saída',
    'TIRO_LATERAL': 'Tiro Lateral',
    'TIRO_LIVRE_INDIRETO': 'Tiro Livre Indireto',
    'ARREMESO_DE_META': 'Arremesso de Meta',
    'INTERVALO': 'Partida no Intervalo',
    'PRORROGACAO': 'Prorrogação Iniciada',
    'PRORROGACAO_DADA': 'Prorrogação Definida',
    'ACRESCIMO': 'Acréscimo',
    'ACRESCIMO_DADO': 'Acréscimo Definido',
    'PAUSA_TECNICA': 'Pausa Técnica',
    'FIM_PAUSA_TECNICA': 'Fim da Pausa Técnica',
    'PARTIDA_RETOMADA': 'Partida Retomada',
    'PARTIDA_PAUSADA': 'Partida Pausada',
  };

  static String friendly(String? rawName) {
    if (rawName == null || rawName.isEmpty) return 'Evento';
    return friendlyNames[rawName.trim().toUpperCase()] ?? rawName;
  }

  /// Busca tipos de eventos únicos de uma modalidade a partir de eventos_partida_publicos.
  /// [modalidadeId] é o campeonato_modalidade_id.
  Future<List<Map<String, dynamic>>> getEventTypesByModality(
    String modalidadeId,
  ) async {
    try {
      // Busca partidas da modalidade em ambas as tabelas públicas
      final partAoVivo = await _supabase
          .from('partidas_ao_vivo')
          .select('partida_id')
          .eq('campeonato_modalidade_id', modalidadeId);

      final partHist = await _supabase
          .from('partidas_historico')
          .select('partida_id')
          .eq('campeonato_modalidade_id', modalidadeId);

      final ids = [
        ...(partAoVivo as List).map((p) => p['partida_id'].toString()),
        ...(partHist as List).map((p) => p['partida_id'].toString()),
      ];

      if (ids.isEmpty) return [];

      final res = await _supabase
          .from('eventos_partida_publicos')
          .select('tipo_evento_codigo, tipo_evento_nome')
          .inFilter('partida_id', ids);

      // Deduplicar por código
      final seen = <String>{};
      final result = <Map<String, dynamic>>[];
      for (final e in (res as List)) {
        final codigo = e['tipo_evento_codigo']?.toString() ?? '';
        if (seen.add(codigo)) {
          result.add({
            'id': codigo, // código como identificador para lookups
            'nome': e['tipo_evento_nome'] ?? codigo,
            'codigo': codigo,
          });
        }
      }
      return result;
    } catch (e) {
      return [];
    }
  }

  /// Busca o nome de um atleta pelo ID via perfis_atletas.
  Future<String?> getAthleteNameById(String atletaId) async {
    try {
      final data = await _supabase
          .from('perfis_atletas')
          .select('nome_exibicao')
          .eq('atleta_id', atletaId)
          .maybeSingle();
      return data?['nome_exibicao'] as String?;
    } catch (e) {
      return null;
    }
  }
}
