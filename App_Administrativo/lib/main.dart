import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'presentation/screens/main/main_screen.dart';

import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/reset_password_screen.dart';
import 'presentation/screens/main/perfil_screen.dart';
import 'presentation/screens/main/configuracoes_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carregar variáveis de ambiente
  await dotenv.load(fileName: ".env");

  // Inicializar Firebase (deve ser antes de tudo)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Registrar handler de background ANTES de qualquer outro setup
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

  // Mantém a tela ligada em todo o app
  WakelockPlus.enable();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Supabase.initialize(
    url: 'https://hlgnackuzfhkhloemtey.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhsZ25hY2t1emZoa2hsb2VtdGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2MjUyNzIsImV4cCI6MjA4NjIwMTI3Mn0.8jq8Anq419bzO94DqCrCcNAJSOsiqGQ8UiFsEO6ibH4', // sua chave
  );

  // DEBUG PRA VER TOKEN
  Future.delayed(const Duration(seconds: 2), () {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      debugPrint('---------------------------------');
      debugPrint('TOKEN_PARA_SWAGGER:');
      debugPrint(session.accessToken);
      debugPrint('---------------------------------');
    } else {
      debugPrint('NENHUMA SESSÃO ATIVA - FAÇA LOGIN NO APP');
    }
  });

  // Escutando mudanças de autenticação
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;

    // Se o evento for de recuperação de senha, mandamos o usuário para a tela de reset
    if (event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/reset-password',
        (route) => false,
      );
    }

    // Inicializar notificacoes quando usuario fizer login
    if (event == AuthChangeEvent.signedIn) {
      NotificationService().init();
    }

    // Limpar token FCM ao fazer logout
    if (event == AuthChangeEvent.signedOut) {
      NotificationService().clearFcmToken();
    }
  });

  // Se ja houver sessao ativa ao abrir o app, inicializar notificacoes
  if (Supabase.instance.client.auth.currentSession != null) {
    NotificationService().init();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'Kyarem Eventos',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      initialRoute: session != null ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainScreen(initialIndex: 0),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/configuracoes': (context) => const ConfiguracoesScreen(),
      },
    );
  }
}
