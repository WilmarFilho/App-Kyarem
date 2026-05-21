import 'dart:convert';

import '../core/api_client.dart';
import '../models/campeonato.dart';
import '../models/partida_feed_item.dart';
import 'campeonato_service.dart';

class PartidaService {
  final ApiClient _apiClient = ApiClient();
  final CampeonatoService _campeonatoService = CampeonatoService();

  Future<List<PartidaFeedItem>> getPartidasFeed() async {
    final response = await _apiClient.get('/partidas');
    if (response.statusCode != 200) {
      throw Exception('Falha ao carregar partidas');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    final rawPartidas = data.cast<Map<String, dynamic>>();
    final campeonatos = await _campeonatoService.getCampeonatos();
    final campeonatoById = {for (final c in campeonatos) c.id: c};

    final modalidadeIds = rawPartidas
        .map((json) => json['modalidadeId']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    final Map<String, CampeonatoModalidade> modalidadeById = {};
    for (final modalidadeId in modalidadeIds) {
      try {
        modalidadeById[modalidadeId] = await _campeonatoService.getModalidadeById(
          modalidadeId,
        );
      } catch (_) {}
    }

    final partidas = rawPartidas.map((json) {
      final modalidadeId = json['modalidadeId']?.toString() ?? '';
      final modalidade = modalidadeById[modalidadeId];
      final campeonato = modalidade != null
          ? campeonatoById[modalidade.campeonatoId]
          : null;

      final equipeA = (json['equipeA'] as Map<String, dynamic>?) ?? const {};
      final equipeB = (json['equipeB'] as Map<String, dynamic>?) ?? const {};

      return PartidaFeedItem(
        id: json['id'].toString(),
        modalidadeId: modalidadeId,
        modalidadeNome:
            modalidade?.nomeExibicao?.trim().isNotEmpty == true
                ? modalidade!.nomeExibicao!
                : modalidade?.modalidadeNome ?? json['modalidadeNome'] ?? 'Modalidade',
        esporteNome: modalidade?.esporteNome ?? 'Esporte',
        campeonatoId: modalidade?.campeonatoId ?? '',
        campeonatoNome: modalidade?.campeonatoNome ?? 'Campeonato',
        campeonatoEscudoUrl: campeonato?.escudoUrl,
        timeA: equipeA['nome']?.toString() ?? 'Time A',
        timeB: equipeB['nome']?.toString() ?? 'Time B',
        atleticaNomeA: equipeA['atleticaNome']?.toString(),
        atleticaNomeB: equipeB['atleticaNome']?.toString(),
        atleticaEscudoUrlA: equipeA['atleticaEscudoUrl']?.toString(),
        atleticaEscudoUrlB: equipeB['atleticaEscudoUrl']?.toString(),
        status: json['status'] ?? '',
        agendadoPara: _parseDate(json['agendadoPara']),
        iniciadaEm: _parseDate(json['iniciadaEm']),
        encerradaEm: _parseDate(json['encerradaEm']),
        local: json['local'],
        categoria: json['categoria'],
        fase: json['fase'],
        placarA: json['placarA'] ?? 0,
        placarB: json['placarB'] ?? 0,
      );
    }).toList();

    partidas.sort((a, b) {
      final dateA = a.agendadoPara ?? a.iniciadaEm ?? DateTime.now();
      final dateB = b.agendadoPara ?? b.iniciadaEm ?? DateTime.now();
      return dateA.compareTo(dateB);
    });

    return partidas;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}
