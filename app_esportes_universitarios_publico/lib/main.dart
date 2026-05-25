import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
import 'presentation/screens/auth/forgot_password_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/auth/reset_password_screen.dart';
import 'presentation/screens/main/main_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final navigatorKey = GlobalKey<NavigatorState>();

const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://hlgnackuzfhkhloemtey.supabase.co',
);

const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhsZ25hY2t1emZoa2hsb2VtdGV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA2MjUyNzIsImV4cCI6MjA4NjIwMTI3Mn0.8jq8Anq419bzO94DqCrCcNAJSOsiqGQ8UiFsEO6ibH4',
);

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Captura erros do framework Flutter (build, layout, paint)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('FLUTTER ERROR: ${details.exception}');
      debugPrint('${details.stack}');
    };

    // Captura erros assíncronos não tratados (Zone / PlatformDispatcher)
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('PLATFORM ERROR: $error');
      debugPrint('$stack');
      return true; // true = erro tratado, não propaga para o sistema
    };

    await dotenv.load(fileName: ".env");
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

    Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/reset-password',
          (route) => false,
        );
      }
    });

    runApp(const KyaremPublicSportsApp());
  } catch (e, stackTrace) {
    debugPrint('FATAL ERROR: $e');
    debugPrint('$stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              child: Text(
                'Failed to start app:\n$e\n$stackTrace',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KyaremPublicSportsApp extends StatelessWidget {
  const KyaremPublicSportsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'Kyarem Esportes',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: buildAppTheme(),
      initialRoute: session != null ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/home': (context) => const MainScreen(),
      },
    );
  }
}
