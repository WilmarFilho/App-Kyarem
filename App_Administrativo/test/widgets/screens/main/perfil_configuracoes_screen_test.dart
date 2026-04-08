import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyarem_eventos/presentation/screens/main/perfil_screen.dart';
import 'package:kyarem_eventos/presentation/screens/main/configuracoes_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../fakes/fake_auth_service.dart';
import '../../../fakes/fake_profile_service.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(home: child);
}

void main() {
  group('PerfilScreen —', () {
    testWidgets('renderiza a tela sem erro', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PerfilScreen(profileService: FakeProfileService()),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('exibe texto PERFIL', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PerfilScreen(profileService: FakeProfileService()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('PERFIL'), findsOneWidget);
    });
  });

  group('ConfiguracoesScreen —', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renderiza a tela sem erro', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ConfiguracoesScreen(authService: FakeAuthService()),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('exibe texto CONFIGURAÇÕES', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        ConfiguracoesScreen(authService: FakeAuthService()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('CONFIGURAÇÕES'), findsOneWidget);
    });
  });
}
