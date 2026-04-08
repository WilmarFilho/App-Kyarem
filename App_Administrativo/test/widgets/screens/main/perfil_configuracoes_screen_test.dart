import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyarem_eventos/presentation/screens/main/perfil_screen.dart';
import 'package:kyarem_eventos/presentation/screens/main/configuracoes_screen.dart';
import '../../../fakes/fake_auth_service.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(home: child);
}

void main() {
  group('PerfilScreen —', () {
    testWidgets('renderiza a tela sem erro', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PerfilScreen(authService: FakeAuthService()),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('exibe texto Perfil', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PerfilScreen(authService: FakeAuthService()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Perfil'), findsOneWidget);
    });
  });

  group('ConfiguracoesScreen —', () {
    testWidgets('renderiza a tela sem erro', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ConfiguracoesScreen(authService: FakeAuthService()),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('exibe texto Configurações', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ConfiguracoesScreen(authService: FakeAuthService()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Configurações'), findsOneWidget);
    });
  });
}
