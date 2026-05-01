import 'campeonato_model.dart';
import 'modalidade_model.dart';

class Atletica {
  final String id;
  final String nome;
  final String? sigla;
  final String? escudoUrl;
  final String? corPrincipal;
  final String? presidenteId;
  final String? status;

  Atletica({
    required this.id,
    required this.nome,
    this.sigla,
    this.escudoUrl,
    this.corPrincipal,
    this.presidenteId,
    this.status,
  });

  factory Atletica.fromMap(Map<String, dynamic> map) {
    return Atletica(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      sigla: map['sigla'],
      escudoUrl: map['escudo_url'] ?? map['escudoUrl'],
      corPrincipal: map['cor_principal'] ?? map['corPrincipal'],
      presidenteId: map['presidente_id'] ?? map['presidenteId'],
      status: map['status'],
    );
  }
}

class Equipe {
  final String id;
  final String nome;
  final String? atleticaEscudoUrl;
  final String atleticaId;
  final String? campeonatoId;
  final String? campeonatoModalidadeId;
  final String? categoria;
  final String? genero;
  final Atletica? atletica;
  final Modalidade? modalidade;
  final Campeonato? campeonato;

  Equipe({
    required this.id,
    required this.nome,
    this.atleticaEscudoUrl,
    required this.atleticaId,
    this.campeonatoId,
    this.campeonatoModalidadeId,
    this.categoria,
    this.genero,
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
    if (map['modalidadeId'] != null ||
        map['modalidadeNome'] != null ||
        map['modalidadeCatalogoId'] != null) {
      modObj = Modalidade(
        id: map['campeonatoModalidadeId']?.toString() ??
            map['modalidadeId']?.toString() ??
            '',
        campeonatoId: map['campeonatoId']?.toString() ?? '',
        modalidadeCatalogoId:
            map['modalidadeCatalogoId']?.toString() ??
            map['modalidadeId']?.toString() ??
            '',
        esporteId: map['esporteId']?.toString() ?? '',
        genero: map['genero']?.toString() ?? '',
        esporteNome: map['esporteNome']?.toString(),
        nomeExibicao: map['modalidadeNome']?.toString() ?? map['nome']?.toString(),
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
      campeonatoId: (map['campeonatoId'] ?? map['campeonato_id'])?.toString(),
      campeonatoModalidadeId:
          (map['campeonatoModalidadeId'] ?? map['campeonato_modalidade_id'])?.toString(),
      categoria: (map['categoria'])?.toString(),
      genero: (map['genero'])?.toString(),
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
