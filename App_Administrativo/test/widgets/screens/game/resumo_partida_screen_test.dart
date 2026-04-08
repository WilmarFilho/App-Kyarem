import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyarem_eventos/presentation/screens/game/resumo_partida_screen.dart';
import 'package:kyarem_eventos/presentation/widgets/game/summary_action_buttons.dart';
import 'package:kyarem_eventos/presentation/widgets/game/summary_score_card.dart';
import 'package:kyarem_eventos/models/helpers/evento_partida_model.dart';
import '../../../fakes/fake_partida_service.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    home: child,
    routes: {
       '/home': (_) => const Scaffold(body: Text('Home Screen')),
    },
  );
}

void main() {
  group('ResumoPartidaScreen —', () {
    testWidgets('renderiza SummaryScoreCard com os nomes dos times corretos', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        MatchSummaryScreen(
          timeA: 'Atlética Computação',
          timeB: 'Atlética Direito',
          golsA: 2,
          golsB: 1,
          partidaService: FakePartidaService(),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.byType(SummaryScoreCard), findsOneWidget);
      expect(find.text('Atlética Computação'), findsOneWidget);
      expect(find.text('Atlética Direito'), findsOneWidget);
    });

    testWidgets('renderiza o placar correto (gols)', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        MatchSummaryScreen(
          timeA: 'Time A',
          timeB: 'Time B',
          golsA: 5,
          golsB: 3,
          partidaService: FakePartidaService(),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('05'), findsOneWidget);
      expect(find.text('03'), findsOneWidget);
    });

    testWidgets('exibe mensagem quando não há eventos', (tester) async {
       await tester.pumpWidget(_buildTestApp(
        MatchSummaryScreen(
          timeA: 'Time A',
          timeB: 'Time B',
          golsA: 0,
          golsB: 0,
          eventos: const [],
          partidaService: FakePartidaService(),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Nenhum evento registrado.'), findsOneWidget);
    });

    testWidgets('renderiza listagem com os botões de ação corretos', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        MatchSummaryScreen(
          timeA: 'Time A',
          timeB: 'Time B',
          golsA: 0,
          golsB: 0,
          eventos: const [],
          partidaService: FakePartidaService(),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.byType(SummaryActionButtons), findsOneWidget);
      expect(find.text('VER PDF DA SÚMULA'), findsOneWidget);
      expect(find.text('VOLTAR PARA O INÍCIO'), findsOneWidget);
    });
  });
}
