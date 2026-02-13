import 'dart:convert';
import 'sumula_model.dart';

class Partida {
  final String id;
  final String nomeTimeA;
  final String nomeTimeB;
  final List<String> atletasTimeA;
  final List<String> atletasTimeB;
  final DateTime dataHora;
  final Sumula sumula;
  final int duracaoMinutos; // Adicionado corretamente

  Partida({
    required this.id,
    required this.nomeTimeA,
    required this.nomeTimeB,
    required this.atletasTimeA,
    required this.atletasTimeB,
    required this.dataHora,
    required this.sumula,
    this.duracaoMinutos = 1,
  });

  // Converte o objeto para salvar no SQLite (Estrutura de colunas)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomeTimeA': nomeTimeA,
      'nomeTimeB': nomeTimeB,
      'status': sumula.status.name,
      'dados_completos_json': jsonEncode(toJson()), 
    };
  }

  // Converte o objeto para o JSON completo que vai dentro da coluna text do banco
  Map<String, dynamic> toJson() => {
        'id': id,
        'nomeTimeA': nomeTimeA,
        'nomeTimeB': nomeTimeB,
        'atletasTimeA': atletasTimeA,
        'atletasTimeB': atletasTimeB,
        'dataHora': dataHora.toIso8601String(),
        'sumula': sumula.toJson(),
        'duracaoMinutos': duracaoMinutos, // IMPORTANTE: faltava incluir aqui
      };

  // Reconstrói o objeto a partir do que foi salvo no SQLite
  factory Partida.fromMap(Map<String, dynamic> map) {
    final Map<String, dynamic> fullData = jsonDecode(map['dados_completos_json']);
    
    return Partida(
      id: fullData['id'],
      nomeTimeA: fullData['nomeTimeA'],
      nomeTimeB: fullData['nomeTimeB'],
      atletasTimeA: List<String>.from(fullData['atletasTimeA']),
      atletasTimeB: List<String>.from(fullData['atletasTimeB']),
      dataHora: DateTime.parse(fullData['dataHora']),
      duracaoMinutos: fullData['duracaoMinutos'] ?? 40, // Recupera o tempo salvo
      // Melhor usar o factory da Sumula que já trata os enums e campos
      sumula: Sumula(
        id: fullData['sumula']['id'],
        placarTimeA: fullData['sumula']['placarTimeA'] ?? 0,
        placarTimeB: fullData['sumula']['placarTimeB'] ?? 0,
        status: StatusSumula.values.firstWhere(
          (e) => e.name == fullData['sumula']['status'],
          orElse: () => StatusSumula.pendente,
        ),
      ),
    );
  }
}