import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/firebase_messaging_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'models/campeonato_model.dart';
import 'presentation/screens/main/main_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/reset_password_screen.dart';
import 'presentation/screens/main/perfil_screen.dart';
import 'presentation/screens/main/modalidades_screen.dart';
import 'presentation/screens/main/configuracoes_screen.dart';
import 'presentation/screens/auth/register_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // 1. Garante a inicialização dos bindings do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Carrega variáveis do .env (ex: CAMPEONATO_ID)
  await dotenv.load(fileName: '.env');

  // Inicializa o Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa serviço de mensagens do Firebase
  await FirebaseMessagingService().initNotifications();

  // 3. Inicializa o Supabase ANTES de qualquer outra coisa
  await Supabase.initialize(
    url: 'https://hlgnackuzfhkhloemtey.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhsZ25hY2t1emZoa2hsb2VtdGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2MjUyNzIsImV4cCI6MjA4NjIwMTI3Mn0.8jq8Anq419bzO94DqCrCcNAJSOsiqGQ8UiFsEO6ibH4',
  );

  // 4. Inicializa a localização para datas (pt_BR)
  await initializeDateFormatting('pt_BR', null);

  // 5. Escuta mudanças de autenticação (Recuperação de senha)
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/reset-password',
        (route) => false,
      );
    }
  });

  // 6. Roda o app apenas UMA vez
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Verifica se existe uma sessão ativa para decidir a tela inicial
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'Kyarem Eventos Público',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF260404),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFFF22F1D),
          surface: const Color(0xFF260404),
          primary: const Color(0xFFF22F1D),
          secondary: const Color(0xFFF2561D),
          tertiary: const Color(0xFFF26B1D),
        ),
        fontFamily: 'Poppins', // Define Poppins como padrão para o app
      ),
      initialRoute: session != null ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const MainScreen(initialIndex: 0),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/modalidades': (context) => ModalidadesScreen(
          campeonato: Campeonato(
            id: dotenv.get('CAMPEONATO_ID'),
            nome: dotenv.get('CAMPEONATO_NOME', fallback: 'Campeonato'),
          ),
        ),
        '/configuracoes': (context) => const ConfiguracoesScreen(),
      },
    );
  }
}
