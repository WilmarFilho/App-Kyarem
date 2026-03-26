import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kyarem_eventos_publico/presentation/screens/game/atletas_partida_screen.dart';
import 'package:kyarem_eventos_publico/services/game_service.dart';

// ── Mocks ──────────────────────────────────────────────────────────────
class MockGameService extends Mock implements GameService {}

void main() {
  late MockGameService mockGameService;

  setUp(() {
    mockGameService = MockGameService();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: AtletasPartidaScreen(
        partidaId: '1',
        timeA: 'Time Alpha',
        timeB: 'Time Beta',
        gameService: mockGameService,
      ),
    );
  }

  group('Testes da Tela de Atletas da Partida (AtletasPartidaScreen)', () {
    testWidgets(
      'Exibe o título ATLETAS e os nomes dos times como tabs',
      (tester) async {
        // Stub: retorna equipes e listas vazias
        when(() => mockGameService.getPartidaEquipes(any()))
            .thenAnswer((_) async => {'equipe_a_id': 'ea1', 'equipe_b_id': 'eb1'});
        when(() => mockGameService.getAtletasInscritos(any()))
            .thenAnswer((_) async => []);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // AppBar
        expect(find.text('ATLETAS'), findsOneWidget);

        // Tabs com nomes maiúsculos
        expect(find.text('TIME ALPHA'), findsOneWidget);
        expect(find.text('TIME BETA'), findsOneWidget);
      },
    );

    testWidgets(
      'Exibe mensagem de empty state quando não há atletas inscritos',
      (tester) async {
        when(() => mockGameService.getPartidaEquipes(any()))
            .thenAnswer((_) async => {'equipe_a_id': 'ea1', 'equipe_b_id': 'eb1'});
        when(() => mockGameService.getAtletasInscritos(any()))
            .thenAnswer((_) async => []);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(
          find.text('Nenhum atleta inscrito nesta equipe.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Exibe lista de titulares e reservas corretamente',
      (tester) async {
        when(() => mockGameService.getPartidaEquipes(any()))
            .thenAnswer((_) async => {'equipe_a_id': 'ea1', 'equipe_b_id': 'eb1'});

        // Time A tem titulares e reservas
        when(() => mockGameService.getAtletasInscritos('ea1'))
            .thenAnswer((_) async => [
                  {
                    'ativo': true,
                    'numero_camisa': 10,
                    'atletas': {
                      'id': 'a1',
                      'atletica_id': 'atl1',
                      'nome': 'Jogador Titular',
                    },
                  },
                  {
                    'ativo': false,
                    'numero_camisa': 12,
                    'atletas': {
                      'id': 'a2',
                      'atletica_id': 'atl1',
                      'nome': 'Jogador Reserva',
                    },
                  },
                ]);

        // Time B vazio
        when(() => mockGameService.getAtletasInscritos('eb1'))
            .thenAnswer((_) async => []);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Seções
        expect(find.text('TITULARES'), findsOneWidget);
        expect(find.text('RESERVAS'), findsOneWidget);

        // Nomes dos atletas
        expect(find.text('Jogador Titular'), findsOneWidget);
        expect(find.text('Jogador Reserva'), findsOneWidget);
      },
    );

    // Nota: O teste de CircularProgressIndicator é omitido pois Future.delayed
    // gera timers pendentes que crasham o test binding do Flutter.
  });
}
