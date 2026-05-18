import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Handler de mensagens em background (top-level, fora de qualquer classe).
/// Obrigatorio pelo Firebase Messaging para funcionar com app fechado.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  debugPrint(
    '[FCM Background] Mensagem recebida: ${message.notification?.title}',
  );
  // Flutter Local Notifications nao precisa ser chamado aqui;
  // o FCM exibe automaticamente quando o app esta em background/terminated.
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _prefTodasPartidas = 'notif_todas_partidas';
  static const String _prefMinhasPartidas = 'notif_minhas_partidas';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080/api/v1',
      connectTimeout: const Duration(seconds: 10),
    ),
  );

  bool _initialized = false;

  Future<String?> _getToken() async {
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  // ============================================================
  // INICIALIZAÇÃO
  // ============================================================

  /// Inicializa o servico completo de notificacoes.
  /// Deve ser chamado apos o login do usuario.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _requestPermissions();
    await _initLocalNotifications();
    await _registerFcmToken();
    _setupMessageHandlers();
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permissao: ${settings.authorizationStatus}');
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    // Canal Android para partidas
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'partidas',
        'Partidas',
        description: 'Notificacoes sobre status e periodos de partidas.',
        importance: Importance.high,
        playSound: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _registerFcmToken() async {
    try {
      final fcmToken = await _messaging.getToken();
      if (fcmToken == null) return;

      debugPrint('[FCM] Token: $fcmToken');

      final token = await _getToken();
      if (token == null) return;

      await _dio.patch(
        '/profiles/me/notifications/token',
        data: {'fcmToken': fcmToken},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      // Atualizar token quando rotacionado pelo Firebase
      _messaging.onTokenRefresh.listen((newToken) async {
        final currentToken = await _getToken();
        if (currentToken != null) {
          await _dio.patch(
            '/profiles/me/notifications/token',
            data: {'fcmToken': newToken},
            options: Options(
              headers: {'Authorization': 'Bearer $currentToken'},
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('[FCM] Erro ao registrar token: $e');
    }
  }

  void _setupMessageHandlers() {
    // Handler para mensagens com app em FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM Foreground] ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Handler para quando o usuario toca na notificacao com app em background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM OpenedApp] ${message.notification?.title}');
      // Aqui pode-se navegar para a tela de partidas se necessario
    });
  }

  /// Exibe notificacao local (usada quando o app esta em foreground).
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'partidas',
      'Partidas',
      channelDescription: 'Notificacoes sobre status e periodos de partidas.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
    );
  }

  // ============================================================
  // PREFERÊNCIAS (carrega do Supabase + cache local)
  // ============================================================

  /// Carrega preferencias de notificacao do banco Supabase.
  /// Fallback para SharedPreferences se banco nao acessivel.
  Future<({bool todasPartidas, bool minhasPartidas})> loadPrefs() async {
    try {
      final token = await _getToken();
      if (token != null) {
        final response = await _dio.get(
          '/profiles/me/notifications/prefs',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );

        final data = response.data;
        final todas = data['notifTodasPartidas'] as bool? ?? true;
        final minhas = data['notifMinhasPartidas'] as bool? ?? true;

        // Cache local
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefTodasPartidas, todas);
        await prefs.setBool(_prefMinhasPartidas, minhas);

        return (todasPartidas: todas, minhasPartidas: minhas);
      }
    } catch (e) {
      debugPrint('[FCM] Erro ao carregar prefs: $e');
    }

    // Fallback local
    final prefs = await SharedPreferences.getInstance();
    return (
      todasPartidas: prefs.getBool(_prefTodasPartidas) ?? true,
      minhasPartidas: prefs.getBool(_prefMinhasPartidas) ?? true,
    );
  }

  /// Salva preferencias no Supabase e em SharedPreferences.
  Future<void> savePrefs({
    required bool todasPartidas,
    required bool minhasPartidas,
  }) async {
    try {
      final token = await _getToken();
      if (token != null) {
        await _dio.patch(
          '/profiles/me/notifications/prefs',
          data: {
            'notifTodasPartidas': todasPartidas,
            'notifMinhasPartidas': minhasPartidas,
          },
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (e) {
      debugPrint('[FCM] Erro ao salvar prefs: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefTodasPartidas, todasPartidas);
    await prefs.setBool(_prefMinhasPartidas, minhasPartidas);
  }

  /// Limpa o token FCM do banco ao fazer logout.
  Future<void> clearFcmToken() async {
    try {
      final token = await _getToken();
      if (token != null) {
        await _dio.patch(
          '/profiles/me/notifications/token',
          data: {'fcmToken': null},
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('[FCM] Erro ao limpar token: $e');
    }
  }
}
