import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyarem_eventos/presentation/screens/admin/partidas_admin_screen.dart';
import '../../../fakes/fake_admin_api_service.dart';
import '../../../fakes/fake_partida_service.dart';

Widget _buildTestApp({
  bool canEdit = true,
  String? atleticaId,
  FakePartidaService? partidaService,
}) {
  return MaterialApp(
    home: PartidasAdminScreen(
      canEdit: canEdit,
      atleticaId: atleticaId,
      partidaService: partidaService ?? FakePartidaService(),
      adminApiService: FakeAdminApiService(),
    ),
  );
}

void main() {
  group('PartidasAdminScreen —', () {
    testWidgets('renderiza AppBar com texto PARTIDAS', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('PARTIDAS'), findsOneWidget);
    });

    testWidgets('mostra estado vazio quando não há partidas', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        partidaService: FakePartidaService(partidas: []),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma Partida'), findsOneWidget);
    });

    testWidgets('exibe FAB Nova Partida quando canEdit é true', (tester) async {
      await tester.pumpWidget(_buildTestApp(canEdit: true));
      await tester.pumpAndSettle();

      expect(find.text('Nova Partida'), findsOneWidget);
    });

    testWidgets('NÃO exibe FAB Nova Partida quando canEdit é false', (tester) async {
      await tester.pumpWidget(_buildTestApp(canEdit: false));
      await tester.pumpAndSettle();

      expect(find.text('Nova Partida'), findsNothing);
    });

    testWidgets('exibe badge Leitura quando canEdit é false', (tester) async {
      await tester.pumpWidget(_buildTestApp(canEdit: false));
      await tester.pumpAndSettle();

      expect(find.textContaining('Leitura'), findsOneWidget);
    });
  });
}
