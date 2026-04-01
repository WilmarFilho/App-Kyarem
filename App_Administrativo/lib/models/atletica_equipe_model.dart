import 'campeonato_model.dart';
import 'modalidade_model.dart';

class Atletica {
  final String id;
  final String nome;
  final String? sigla;
  final String? escudoUrl;
  final String? corPrincipal;
  final String? presidenteId;

  Atletica({
    required this.id,
    required this.nome,
    this.sigla,
    this.escudoUrl,
    this.corPrincipal,
    this.presidenteId,
  });

  factory Atletica.fromMap(Map<String, dynamic> map) {
    return Atletica(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      sigla: map['sigla'],
      escudoUrl: map['escudo_url'] ?? map['escudoUrl'],
      corPrincipal: map['cor_principal'] ?? map['corPrincipal'],
      presidenteId: map['presidente_id'] ?? map['presidenteId'],
    );
  }
}

class Equipe {
  final String id;
  final String nome;
  final String? atleticaEscudoUrl;
  final String atleticaId;
  final Atletica? atletica;
  final Modalidade? modalidade;
  final Campeonato? campeonato;

  Equipe({
    required this.id,
    required this.nome,
    this.atleticaEscudoUrl,
    required this.atleticaId,
    this.atletica,
    this.modalidade,
    this.campeonato,
  });

  factory Equipe.fromMap(Map<String, dynamic> map) {
    final nestedAtletica = map['atletica'];
    final nestedAtleticaMap =
        nestedAtletica is Map<String, dynamic> ? nestedAtletica : null;

    final atleticaId =
        (map['atleticaId'] ??
                map['atletica_id'] ??
                nestedAtleticaMap?['id'] ??
                nestedAtleticaMap?['atleticaId'] ??
                nestedAtleticaMap?['atletica_id'])
            ?.toString() ??
        '';

    final atleticaNome =
        (map['atleticaNome'] ??
                map['atletica_nome'] ??
                nestedAtleticaMap?['nome'] ??
                nestedAtleticaMap?['atleticaNome'])
            ?.toString();

    final escudo = (map['atleticaEscudoUrl'] ??
            map['atletica_escudo_url'] ??
            map['escudo_url'] ??
            nestedAtleticaMap?['escudoUrl'] ??
            nestedAtleticaMap?['escudo_url'])
        ?.toString();

    Modalidade? modObj;
    if (map['modalidadeId'] != null || map['modalidadeNome'] != null) {
      modObj = Modalidade(
        id: map['modalidadeId']?.toString() ?? '',
        campeonatoId: map['campeonatoId']?.toString() ?? '',
        esporteId: '',
        genero: '',
        esporteNome: map['modalidadeNome']?.toString(),
      );
    }

    Campeonato? campObj;
    if (map['campeonatoId'] != null || map['campeonatoNome'] != null) {
      campObj = Campeonato(
        id: map['campeonatoId']?.toString() ?? '',
        nome: map['campeonatoNome']?.toString() ?? '',
      );
    }

    return Equipe(
      id: map['id'] ?? '',
      nome: (map['nomeEquipe'] ?? map['nome'] ?? map['nome_equipe'])?.toString() ??
          'Time Desconhecido',
      atleticaEscudoUrl: escudo,
      atleticaId: atleticaId,
      atletica: atleticaId.isEmpty &&
              (atleticaNome == null || atleticaNome.isEmpty) &&
              escudo == null
          ? null
          : Atletica(
              id: atleticaId,
              nome: atleticaNome ?? '',
              escudoUrl: escudo,
            ),
      modalidade: modObj,
      campeonato: campObj,
    );
  }
}
