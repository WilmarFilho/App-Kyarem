import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/firebase_messaging_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'models/campeonato_model.dart';
import 'core/app_globals.dart';
import 'presentation/screens/main/main_screen.dart';
import 'presentation/screens/auth/onboarding_screen.dart';
import 'presentation/screens/main/modalidades_screen.dart';
import 'presentation/screens/main/configuracoes_screen.dart';
import 'presentation/screens/main/splash_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMessagingService().initNotifications();
  await Supabase.initialize(
    url: 'https://hlgnackuzfhkhloemtey.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhsZ25hY2t1emZoa2hsb2VtdGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2MjUyNzIsImV4cCI6MjA4NjIwMTI3Mn0.8jq8Anq419bzO94DqCrCcNAJSOsiqGQ8UiFsEO6ibH4',
  );
  await initializeDateFormatting('pt_BR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    FlutterNativeSplash.remove();

    return MaterialApp(
      title: 'Intermeds',
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
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const OnboardingScreen(),
        '/home': (context) => const MainScreen(initialIndex: 0),
        '/modalidades': (context) => ModalidadesScreen(
          campeonato: AppGlobals.campeonatoAtivo ?? Campeonato(id: '', nome: 'Campeonato'),
        ),
        '/configuracoes': (context) => const ConfiguracoesScreen(),
      },
    );
  }
}
