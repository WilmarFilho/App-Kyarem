import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class RealtimeService {
  http.Client? _client;
  StreamController<dynamic>? _controller;

  /// Connects to the SSE endpoint for a specific match
  Stream<dynamic> listenToMatch(String matchId) {
    _controller = StreamController<dynamic>.broadcast();
    _client = http.Client();

    final baseUrl = dotenv.get('REALTIME_GATEWAY_URL', fallback: 'http://10.0.2.2:9000');
    final url = Uri.parse('$baseUrl/events/$matchId');

    final request = http.Request('GET', url)
      ..headers['Accept'] = 'text/event-stream'
      ..headers['Cache-Control'] = 'no-cache';

    _client!.send(request).then((response) {
      if (response.statusCode == 200) {
        response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (String line) {
            if (line.startsWith('data:')) {
              final dataStr = line.substring(5).trim();
              if (dataStr.isNotEmpty) {
                try {
                  final jsonData = jsonDecode(dataStr);
                  _controller?.add(jsonData);
                } catch (e) {
                  debugPrint('Erro ao parsear evento SSE: $e');
                }
              }
            }
          },
          onError: (error) {
            debugPrint('Erro na stream SSE: $error');
            _controller?.addError(error);
          },
          onDone: () {
            debugPrint('Conexão SSE encerrada');
            _controller?.close();
          },
        );
      } else {
        debugPrint('Erro ao conectar no SSE. Status: ${response.statusCode}');
        _controller?.addError('Status ${response.statusCode}');
      }
    }).catchError((e) {
      debugPrint('Erro no cliente SSE: $e');
      _controller?.addError(e);
    });

    return _controller!.stream;
  }

  void disconnect() {
    _client?.close();
    _controller?.close();
    _client = null;
    _controller = null;
  }
}
