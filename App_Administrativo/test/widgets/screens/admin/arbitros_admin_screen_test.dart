import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyarem_eventos/models/arbitro_model.dart';
import 'package:kyarem_eventos/presentation/screens/admin/arbitros_screen.dart';
import '../../../fakes/fake_admin_api_service.dart';

Widget _buildTestApp({
  FakeAdminApiService? api,
  bool canEdit = true,
}) {
  return MaterialApp(
    home: ArbitrosAdminScreen(
      apiService: api ?? FakeAdminApiService(),
      canEdit: canEdit,
    ),
  );
}

void main() {
  group('ArbitrosAdminScreen —', () {
    testWidgets('renderiza AppBar com texto ÁRBITROS', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('ÁRBITROS'), findsOneWidget);
    });

    testWidgets('exibe campo de busca', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Buscar árbitro...'), findsOneWidget);
    });

    testWidgets('mostra estado vazio quando não há árbitros', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        api: FakeAdminApiService(arbitros: []),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum árbitro cadastrado'), findsOneWidget);
    });

    testWidgets('exibe badge Leitura quando canEdit é false', (tester) async {
      await tester.pumpWidget(_buildTestApp(canEdit: false));
      await tester.pumpAndSettle();

      expect(find.textContaining('Leitura'), findsOneWidget);
    });

    testWidgets('renderiza nome dos árbitros quando há dados', (tester) async {
      final api = FakeAdminApiService(
        arbitros: [
          Arbitro(id: '1', nome: 'João Silva', telefone: '11999999999'),
          Arbitro(id: '2', nome: 'Maria Souza'),
        ],
      );
      await tester.pumpWidget(_buildTestApp(api: api));
      await tester.pumpAndSettle();

      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('Maria Souza'), findsOneWidget);
    });
  });
}
