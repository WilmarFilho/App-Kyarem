/// Cache em memória para respostas de requisições GET.
///
/// Cada entrada armazena o corpo da resposta (String) e o instante em que
/// foi armazenada.  Entradas com mais de [defaultTtl] são consideradas
/// expiradas e o dado é buscado novamente na API.
class CacheManager {
  CacheManager._();
  static final CacheManager instance = CacheManager._();

  /// Tempo de vida padrão de cada entrada no cache.
  static const Duration defaultTtl = Duration(seconds: 30);

  final Map<String, _CacheEntry> _store = {};

  // ── Leitura ────────────────────────────────────────────────────────────────

  /// Retorna o valor em cache para [key] se ele ainda for válido; caso
  /// contrário retorna `null`.
  String? get(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _store.remove(key);
      return null;
    }
    return entry.body;
  }

  // ── Escrita ────────────────────────────────────────────────────────────────

  /// Armazena [body] para [key] com o TTL padrão.
  void set(String key, String body, {Duration? ttl}) {
    final duration = ttl ?? defaultTtl;
    _store[key] = _CacheEntry(
      body: body,
      expiresAt: DateTime.now().add(duration),
    );
  }

  // ── Invalidação ────────────────────────────────────────────────────────────

  /// Remove todas as entradas cujo prefixo de rota bate com [prefix].
  ///
  /// Exemplo: invalidar '/atleticas' remove '/atleticas', '/atleticas/123',
  /// '/atleticas/123/membros', etc.
  void invalidatePrefix(String prefix) {
    _store.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Remove a entrada exata de [key].
  void invalidate(String key) {
    _store.remove(key);
  }

  /// Limpa todo o cache (útil p/ logout ou troca de usuário).
  void clear() {
    _store.clear();
  }
}

class _CacheEntry {
  final String body;
  final DateTime expiresAt;

  const _CacheEntry({required this.body, required this.expiresAt});
}
