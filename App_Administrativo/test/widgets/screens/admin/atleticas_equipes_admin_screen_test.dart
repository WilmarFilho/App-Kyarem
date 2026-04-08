import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyarem_eventos/models/atletica_equipe_model.dart';
import 'package:kyarem_eventos/presentation/screens/admin/atleticas_admin_screen.dart';
import 'package:kyarem_eventos/presentation/screens/admin/equipes_admin_screen.dart';
import '../../../fakes/fake_admin_api_service.dart';

Widget _buildTestApp(Widget child) => MaterialApp(home: child);

void main() {
  // ============================
  // AtleticasAdminScreen
  // ============================
  group('AtleticasAdminScreen —', () {
    testWidgets('renderiza AppBar com texto ATLÉTICAS', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        AtleticasAdminScreen(apiService: FakeAdminApiService()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('ATLÉTICAS'), findsOneWidget);
    });

    testWidgets('mostra estado vazio', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        AtleticasAdminScreen(apiService: FakeAdminApiService(atleticas: [])),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma Atlética'), findsOneWidget);
    });

    testWidgets('renderiza lista com dados', (tester) async {
      final api = FakeAdminApiService(
        atleticas: [
          Atletica(id: 'a1', nome: 'Atlética Engenharia'),
          Atletica(id: 'a2', nome: 'Atlética Direito'),
        ],
      );
      await tester.pumpWidget(_buildTestApp(
        AtleticasAdminScreen(apiService: api),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Atlética Engenharia'), findsOneWidget);
      expect(find.text('Atlética Direito'), findsOneWidget);
    });
  });

  // ============================
  // EquipesAdminScreen
  // ============================
  group('EquipesAdminScreen —', () {
    testWidgets('renderiza AppBar com texto TIMES', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        EquipesAdminScreen(apiService: FakeAdminApiService()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('TIMES'), findsOneWidget);
    });

    testWidgets('mostra estado vazio', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        EquipesAdminScreen(apiService: FakeAdminApiService(equipes: [])),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum Time'), findsOneWidget);
    });

    testWidgets('exibe FAB Novo Time', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        EquipesAdminScreen(apiService: FakeAdminApiService()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Novo Time'), findsOneWidget);
    });
  });
}
