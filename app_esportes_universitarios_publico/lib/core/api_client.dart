import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'cache_manager.dart';

class ApiClient {
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080/api/v1';

  final CacheManager _cache = CacheManager.instance;

  Future<Map<String, String>> _getHeaders() async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── GET com cache ──────────────────────────────────────────────────────────

  Future<http.Response> get(
    String endpoint, {
    bool useCache = true,
    Duration? cacheTtl,
  }) async {
    if (useCache) {
      final cached = _cache.get(endpoint);
      if (cached != null) {
        // Retorna uma Response sintética com o corpo cacheado.
        // O header charset=utf-8 é essencial: sem ele o http package
        // codifica o body em latin-1, quebrando utf8.decode(response.bodyBytes)
        // que alguns services utilizam.
        return http.Response(
          cached,
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }
    }

    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (useCache && response.statusCode == 200) {
      _cache.set(endpoint, response.body, ttl: cacheTtl);
    }

    return response;
  }

  // ── Métodos de escrita – invalidam cache relacionado ──────────────────────

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    _invalidateRelated(endpoint);
    return response;
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    _invalidateRelated(endpoint);
    return response;
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    _invalidateRelated(endpoint);
    return response;
  }

  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    _invalidateRelated(endpoint);
    return response;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Invalida o cache de rotas relacionadas ao [endpoint] modificado.
  ///
  /// Estratégia: extrai o primeiro segmento de recurso do endpoint e invalida
  /// todo o prefixo correspondente.
  /// Ex.: '/atleticas/123/membros' → invalida tudo que começa com '/atleticas'
  void _invalidateRelated(String endpoint) {
    // Remove query-string para pegar só o path.
    final path = endpoint.split('?').first;
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty) {
      _cache.invalidatePrefix('/${segments.first}');
    }
  }
}
