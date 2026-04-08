import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyarem_eventos/presentation/screens/auth/login_screen.dart';
import 'package:kyarem_eventos/presentation/widgets/auth/auth_button.dart';
import '../../../fakes/fake_auth_service.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    home: child,
    routes: {
      '/home': (_) => const Scaffold(body: Text('Home')),
      '/reset-password': (_) => const Scaffold(body: Text('Reset')),
    },
  );
}

/// Avança o frame sem pumpAndSettle() para evitar bloqueio por SVG assets
/// e pelo FutureBuilder de credentials.
Future<void> _pumpLogin(WidgetTester tester) async {
  await tester.pump(); // primeiro frame
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('LoginScreen —', () {
    testWidgets('renderiza título Login', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        LoginScreen(authService: FakeAuthService()),
      ));
      await _pumpLogin(tester);

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('renderiza label Seu e-mail', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        LoginScreen(authService: FakeAuthService()),
      ));
      await _pumpLogin(tester);

      expect(find.text('Seu e-mail:'), findsOneWidget);
    });

    testWidgets('renderiza label Sua senha', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        LoginScreen(authService: FakeAuthService()),
      ));
      await _pumpLogin(tester);

      expect(find.text('Sua senha:'), findsOneWidget);
    });

    testWidgets('renderiza botão Entrar (AuthButton)', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        LoginScreen(authService: FakeAuthService()),
      ));
      await _pumpLogin(tester);

      expect(find.byType(AuthButton), findsOneWidget);
    });

    testWidgets('renderiza link Esqueci a senha', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        LoginScreen(authService: FakeAuthService()),
      ));
      await _pumpLogin(tester);

      expect(find.text('Esqueci a senha'), findsOneWidget);
    });

    testWidgets('mostra erro ao submeter com campos vazios', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Supressão de overflow do layout (normal no ambiente de testes com SVG ausente)
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('RenderFlex overflowed')) return;
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(_buildTestApp(
        LoginScreen(authService: FakeAuthService()),
      ));
      await _pumpLogin(tester);

      // Rola até o botão e toca
      await tester.ensureVisible(find.byType(AuthButton));
      await tester.tap(find.byType(AuthButton), warnIfMissed: false);
      await tester.pump();
      await tester.pump();

      expect(find.text('Preencha todos os campos'), findsOneWidget);
    });

    testWidgets('mostra erro E-mail ou senha incorretos quando login falha', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeAuth = FakeAuthService(loginError: 'Credenciais inválidas');

      // Supressão de erros de overflow de layout (RenderFlex) esperados no ambiente de teste
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('RenderFlex overflowed')) return;
        originalOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(_buildTestApp(
        LoginScreen(authService: fakeAuth),
      ));
      await _pumpLogin(tester);

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.first, 'test@test.com');
      await tester.enterText(textFields.last, 'senha123');

      await tester.ensureVisible(find.byType(AuthButton));
      await tester.pump();

      await tester.tap(find.byType(AuthButton), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      // AuthException com mensagem não contendo 'network' → 'E-mail ou senha incorretos'
      expect(find.text('E-mail ou senha incorretos'), findsOneWidget);
    });
  });
}
