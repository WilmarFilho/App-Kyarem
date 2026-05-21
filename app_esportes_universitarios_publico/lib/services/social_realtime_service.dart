import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class SocialRealtimeService {
  SocialRealtimeService._();

  static final SocialRealtimeService instance = SocialRealtimeService._();

  final StreamController<void> _controller = StreamController<void>.broadcast();
  HttpClient? _client;
  bool _started = false;
  bool _disposed = false;

  Stream<void> get updates => _controller.stream;

  String get _baseUrl {
    final explicit = dotenv.env['REALTIME_BASE_URL'];
    if (explicit != null && explicit.trim().isNotEmpty) {
      return explicit.trim();
    }

    final apiBase = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8080/api/v1';
    final uri = Uri.parse(apiBase);
    final derivedPort = uri.hasPort && uri.port == 8080 ? 9000 : uri.port;
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: derivedPort,
    ).toString();
  }

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _listenLoop();
  }

  Future<void> dispose() async {
    _disposed = true;
    _started = false;
    _client?.close(force: true);
    await _controller.close();
  }

  Future<void> _listenLoop() async {
    while (_started && !_disposed) {
      try {
        _client?.close(force: true);
        _client = HttpClient();
        final request = await _client!.getUrl(Uri.parse('$_baseUrl/events/social'));
        request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
        final response = await request.close();
        if (response.statusCode != 200) {
          await Future<void>.delayed(const Duration(seconds: 5));
          continue;
        }

        String currentEvent = '';
        await for (final line in response
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (line.startsWith('event:')) {
            currentEvent = line.substring(6).trim();
            continue;
          }

          if (line.startsWith('data:')) {
            final payload = line.substring(5).trim();
            if (currentEvent == 'social-update' && payload.isNotEmpty) {
              _controller.add(null);
            }
          }
        }
      } catch (_) {
        if (_disposed) return;
      }

      if (_started && !_disposed) {
        await Future<void>.delayed(const Duration(seconds: 4));
      }
    }
  }
}
