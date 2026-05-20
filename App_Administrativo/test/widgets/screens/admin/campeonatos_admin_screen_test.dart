import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyarem_eventos/models/campeonato_model.dart';
import 'package:kyarem_eventos/presentation/screens/admin/campeonatos_admin_screen.dart';
import '../../../fakes/fake_admin_api_service.dart';

Widget _buildTestApp({FakeAdminApiService? api}) {
  return MaterialApp(
    home: CampeonatosAdminScreen(apiService: api ?? FakeAdminApiService()),
  );
}

void main() {
  group('CampeonatosAdminScreen —', () {
    testWidgets('renderiza AppBar com texto CAMPEONATOS', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('CAMPEONATOS'), findsOneWidget);
    });

    testWidgets('mostra estado vazio quando não há campeonatos', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        api: FakeAdminApiService(campeonatos: []),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum campeonato'), findsOneWidget);
    });

    testWidgets('exibe FAB Novo', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Novo Campeonato'), findsOneWidget);
    });

    testWidgets('renderiza nome dos campeonatos quando há dados', (tester) async {
      final api = FakeAdminApiService(
        campeonatos: [
          Campeonato(id: '1', nome: 'Copa Universitária', nivel: 'A'),
          Campeonato(id: '2', nome: 'Torneio Interno', nivel: 'B'),
        ],
      );

      await tester.pumpWidget(_buildTestApp(api: api));
      await tester.pumpAndSettle();

      expect(find.text('Copa Universitária'), findsOneWidget);
      expect(find.text('Torneio Interno'), findsOneWidget);
    });

    testWidgets('exige digitar o nome do campeonato para confirmar exclusão', (
      tester,
    ) async {
      final api = FakeAdminApiService(
        campeonatos: [
          Campeonato(id: '1', nome: 'Copa Universitária', nivel: 'A'),
        ],
      );

      await tester.pumpWidget(_buildTestApp(api: api));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Excluir Copa Universitária'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Para confirmar, digite exatamente o nome do campeonato:',
        ),
        findsOneWidget,
      );

      final excluirButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Excluir'),
      );
      expect(excluirButton.onPressed, isNull);

      await tester.enterText(
        find.byType(TextField),
        'Copa Universitária',
      );
      await tester.pumpAndSettle();

      final excluirHabilitado = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Excluir'),
      );
      expect(excluirHabilitado.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Excluir'));
      await tester.pumpAndSettle();

      expect(api.campeonatosExcluidos, ['1']);
    });
  });
}
