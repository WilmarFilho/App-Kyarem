import 'package:supabase_flutter/supabase_flutter.dart';

class EventoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Mapeamento de nomes crus do banco → nomes amigáveis para exibição
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

  Future<List<Map<String, dynamic>>> getEventTypesByModality(
    String modalidadeId,
  ) async {
    try {
      // Busca o esporte_id vinculado à modalidade da partida
      final modalidadeData = await _supabase
          .from('modalidades')
          .select('esporte_id')
          .eq('id', modalidadeId)
          .single();

      final String esporteId = modalidadeData['esporte_id'];

      // Busca os nomes dos eventos configurados para aquele esporte
      final response = await _supabase
          .from('tipos_eventos')
          .select('id, nome')
          .eq('esporte_id', esporteId)
          .order('nome', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Busca o nome de um atleta pelo ID. Retorna null se não encontrado.
  Future<String?> getAthleteNameById(String atletaId) async {
    try {
      final data = await _supabase
          .from('atletas')
          .select('nome')
          .eq('id', atletaId)
          .single();
      return data['nome'] as String?;
    } catch (e) {
      return null;
    }
  }
}
