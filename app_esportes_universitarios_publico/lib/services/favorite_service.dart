import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/api_client.dart';
import '../models/atletica.dart';
import '../models/campeonato.dart';
import '../models/partida_feed_item.dart';

class FavoriteService {
  final ApiClient _api = ApiClient();

  String? get currentUserId =>
      Supabase.instance.client.auth.currentUser?.id;

  // ── Toggle ─────────────────────────────────────────────────────────────────

  /// Adiciona ou remove o favorito e retorna o novo estado (true = favoritado).
  Future<bool> toggleFavorite({
    String? partidaId,
    String? campeonatoId,
    String? atleticaId,
  }) async {
    if (currentUserId == null) {
      throw Exception('Usuário precisa estar logado para favoritar.');
    }

    final body = <String, dynamic>{};
    if (partidaId != null)    body['partidaId']    = partidaId;
    if (campeonatoId != null) body['campeonatoId'] = campeonatoId;
    if (atleticaId != null)   body['atleticaId']   = atleticaId;

    final response = await _api.post('/favorites/toggle', body);

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return json['favorited'] as bool? ?? false;
    }
    throw Exception('Erro ao alternar favorito: ${response.statusCode}');
  }

  // ── Check ──────────────────────────────────────────────────────────────────

  Future<bool> isFavorite({
    String? partidaId,
    String? campeonatoId,
    String? atleticaId,
  }) async {
    if (currentUserId == null) return false;

    final params = <String>[];
    if (partidaId != null)    params.add('partidaId=$partidaId');
    if (campeonatoId != null) params.add('campeonatoId=$campeonatoId');
    if (atleticaId != null)   params.add('atleticaId=$atleticaId');

    final qs = params.join('&');
    final response = await _api.get('/favorites/check?$qs', useCache: false);

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return json['favorited'] as bool? ?? false;
    }
    return false;
  }

  // ── List ───────────────────────────────────────────────────────────────────

  Future<Map<String, List<dynamic>>> getFavorites() async {
    if (currentUserId == null) {
      return {'partidas': [], 'campeonatos': [], 'atleticas': []};
    }

    final response = await _api.get('/favorites', useCache: false);

    if (response.statusCode != 200) {
      return {'partidas': [], 'campeonatos': [], 'atleticas': []};
    }

    final List<dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;

    final partidas    = <PartidaFeedItem>[];
    final campeonatos = <Campeonato>[];
    final atleticas   = <Atletica>[];

    for (final row in data) {
      if (row['partidaId'] != null) {
        partidas.add(PartidaFeedItem.fromFavoriteJson(row));
      } else if (row['campeonatoId'] != null) {
        campeonatos.add(Campeonato.fromFavoriteJson(row));
      } else if (row['atleticaId'] != null) {
        atleticas.add(Atletica.fromFavoriteJson(row));
      }
    }

    return {
      'partidas':    partidas,
      'campeonatos': campeonatos,
      'atleticas':   atleticas,
    };
  }
}
