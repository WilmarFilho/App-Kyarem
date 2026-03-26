import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kyarem_eventos_publico/presentation/screens/game/resumo_estatistica_partida_screen.dart';
import 'package:kyarem_eventos_publico/services/game_service.dart';

// ── Mocks ──────────────────────────────────────────────────────────────
class MockGameService extends Mock implements GameService {}

void main() {
  late MockGameService mockGameService;

  setUp(() {
    mockGameService = MockGameService();

    // Stubs padrão: partida sem eventos (stats all zero, no MVP)
    when(() => mockGameService.getPartidaComEquipes(any()))
        .thenAnswer((_) async => {
              'modalidade_id': 'm1',
              'equipe_a': {'atletica_id': 'atl1'},
              'equipe_b': {'atletica_id': 'atl2'},
            });

    when(() => mockGameService.getModalidadeInfo(any()))
        .thenAnswer((_) async => {'esporte_id': 'e1'});

    when(() => mockGameService.getTiposEventos(any()))
        .thenAnswer((_) async => <Map<String, dynamic>>[]);

    when(() => mockGameService.getEventosPartida(any()))
        .thenAnswer((_) async => <Map<String, dynamic>>[]);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ResumoEstatisticaPartidaScreen(
        partidaId: '1',
        timeA: 'Time Alpha',
        timeB: 'Time Beta',
        gameService: mockGameService,
      ),
    );
  }

  group('Testes da Tela de Resumo da Partida (ResumoEstatisticaPartidaScreen)', () {
    testWidgets(
      'Exibe o título RESUMO DA PARTIDA no AppBar',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('RESUMO DA PARTIDA'), findsOneWidget);
      },
    );

    // Nota: O teste de CircularProgressIndicator é omitido pois Future.delayed
    // gera timers pendentes que crasham o test binding do Flutter.

    testWidgets(
      'Exibe tabela de comparação com nomes dos times e estatísticas zeradas',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Título de seção
        expect(find.text('COMPARAÇÃO DE EQUIPES'), findsOneWidget);

        // Nomes dos times
        expect(find.text('Time Alpha'), findsOneWidget);
        expect(find.text('Time Beta'), findsOneWidget);

        // Linhas de estatísticas
        expect(find.text('GOLS / PONTOS'), findsOneWidget);
        expect(find.text('FALTAS'), findsOneWidget);
        expect(find.text('CARTÕES AMARELOS'), findsOneWidget);
        expect(find.text('CARTÕES VERMELHOS'), findsOneWidget);
      },
    );

    testWidgets(
      'Não exibe card MVP quando não há gols',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('⭐ Destaque da Partida ⭐'), findsNothing);
      },
    );

    testWidgets(
      'Exibe card MVP quando há eventos de gol',
      (tester) async {
        // Tipos com GOL
        when(() => mockGameService.getTiposEventos(any()))
            .thenAnswer((_) async => [
                  {'id': 't1', 'nome': 'GOL'},
                ]);

        // Eventos com gols
        when(() => mockGameService.getEventosPartida(any()))
            .thenAnswer((_) async => [
                  {
                    'tipo_evento_id': 't1',
                    'atleta_id': 'jogador1',
                    'atletas': {
                      'atletica_id': 'atl1',
                      'nome': 'Cristiano Goleador',
                    },
                  },
                  {
                    'tipo_evento_id': 't1',
                    'atleta_id': 'jogador1',
                    'atletas': {
                      'atletica_id': 'atl1',
                      'nome': 'Cristiano Goleador',
                    },
                  },
                ]);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // MVP card deve aparecer
        expect(find.text('⭐ Destaque da Partida ⭐'), findsOneWidget);
        expect(find.text('Cristiano Goleador'), findsOneWidget);
        expect(find.text('2 Gols'), findsOneWidget);
        expect(find.text('Time Alpha'), findsNWidgets(2)); // header + MVP team
      },
    );
  });
}
