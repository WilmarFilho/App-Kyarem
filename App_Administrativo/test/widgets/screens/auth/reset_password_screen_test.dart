import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyarem_eventos/presentation/screens/auth/reset_password_screen.dart';
import '../../../fakes/fake_auth_service.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    home: child,
    routes: {
      '/login': (_) => const Scaffold(body: Text('Login')),
    },
  );
}

void main() {
  group('ResetPasswordScreen —', () {
    testWidgets('renderiza título NOVA SENHA', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ResetPasswordScreen(authService: FakeAuthService()),
      ));
      await tester.pump();

      expect(find.text('NOVA SENHA'), findsOneWidget);
    });

    testWidgets('renderiza dois campos de senha', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ResetPasswordScreen(authService: FakeAuthService()),
      ));
      await tester.pump();

      expect(
        find.byWidgetPredicate((w) => w is TextField && w.obscureText == true),
        findsNWidgets(2),
      );
    });

    testWidgets('mostra erro se senha tiver menos de 6 caracteres', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ResetPasswordScreen(authService: FakeAuthService()),
      ));
      await tester.pump();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, '123'); // menos de 6
      await tester.enterText(fields.last, '123');
      await tester.tap(find.text('SALVAR NOVA SENHA'));
      await tester.pump();

      expect(find.text('A senha deve ter pelo menos 6 caracteres'), findsOneWidget);
    });

    testWidgets('mostra erro se senhas não coincidem', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ResetPasswordScreen(authService: FakeAuthService()),
      ));
      await tester.pump();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'senha123');
      await tester.enterText(fields.last, 'senha456');
      await tester.tap(find.text('SALVAR NOVA SENHA'));
      await tester.pump();

      expect(find.text('As senhas não coincidem'), findsOneWidget);
    });
  });
}
