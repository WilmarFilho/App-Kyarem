import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyarem_eventos/presentation/screens/main/home_screen.dart';
import '../../../fakes/fake_auth_service.dart';
import '../../../fakes/fake_admin_api_service.dart';
import '../../../fakes/fake_partida_service.dart';

Widget _buildTestApp({
  String role = 'aluno',
  FakePartidaService? partidaService,
}) {
  return MaterialApp(
    home: HomeScreen(
      authService: FakeAuthService(role: role),
      adminApiService: FakeAdminApiService(),
      partidaService: partidaService ?? FakePartidaService(),
    ),
    routes: {
      '/login': (_) => const Scaffold(body: Text('Login')),
      '/perfil': (_) => const Scaffold(body: Text('Perfil')),
    },
  );
}

/// Avança frames sem pumpAndSettle() para evitar timeout do FutureBuilder
/// do HomeHeader que tenta acessar Supabase.instance durante os testes.
Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pump(); // 1° frame
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  group('HomeScreen —', () {
    testWidgets('renderiza aba Partidas', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await _pumpHome(tester);

      expect(find.text('Partidas'), findsAtLeastNWidgets(1));
    });

    testWidgets('renderiza aba Árbitros', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await _pumpHome(tester);

      expect(find.text('Árbitros'), findsAtLeastNWidgets(1));
    });

    testWidgets('renderiza aba Campeonatos', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await _pumpHome(tester);

      expect(find.text('Campeonatos'), findsAtLeastNWidgets(1));
    });

    testWidgets('mostra "Nenhuma partida em destaque" quando lista vazia', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        partidaService: FakePartidaService(partidas: []),
      ));
      await _pumpHome(tester);

      expect(find.text('Nenhuma partida em destaque'), findsOneWidget);
    });

    testWidgets('NÃO mostra atalhos admin para role aluno', (tester) async {
      await tester.pumpWidget(_buildTestApp(role: 'aluno'));
      await _pumpHome(tester);

      // 'CAMPEONATOS' em maiúsculas → apenas nos atalhos administrativos
      expect(find.text('CAMPEONATOS'), findsNothing);
    });
  });
}
