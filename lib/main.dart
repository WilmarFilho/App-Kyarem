import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/reset_password_screen.dart';
import 'presentation/screens/perfil_screen.dart';
import 'presentation/screens/arbitros_screen.dart';
import 'presentation/screens/campeonatos_screen.dart';
import 'presentation/screens/configuracoes_screen.dart';

// Criamos uma chave global para conseguir navegar de qualquer lugar, 
// mesmo de dentro do listener do Supabase no main.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Supabase.initialize(
    url: 'https://hlgnackuzfhkhloemtey.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhsZ25hY2t1emZoa2hsb2VtdGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2MjUyNzIsImV4cCI6MjA4NjIwMTI3Mn0.8jq8Anq419bzO94DqCrCcNAJSOsiqGQ8UiFsEO6ibH4', // sua chave
  );

  // Escutando mudanças de autenticação
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;
    
    // Se o evento for de recuperação de senha, mandamos o usuário para a tela de reset
    if (event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/reset-password', (route) => false);
    }
  });

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
        '/home': (context) => const HomeScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/arbitros': (context) => const ArbitrosScreen(),
        '/campeonatos': (context) => const CampeonatosScreen(),
        '/configuracoes': (context) => const ConfiguracoesScreen(),
      },
    );
  }
}