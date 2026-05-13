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
    // getPartidaComEquipes now returns flattened public schema data
    when(() => mockGameService.getPartidaComEquipes(any()))
        .thenAnswer((_) async => {
              'partida_id': '1',
              'campeonato_modalidade_id': 'm1',
              'time_a_atletica_id': 'atl1',
              'time_b_atletica_id': 'atl2',
            });

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

    testWidgets(
      'Não exibe card MVP quando não há gols',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('⭐ Destaque da Partida ⭐'), findsNothing);
      },
    );

    testWidgets(
      'Exibe card MVP quando há eventos de gol com tipo_evento_codigo',
      (tester) async {
        // Eventos com gols usando o schema público (tipo_evento_codigo ao invés de tipo_evento_id)
        when(() => mockGameService.getEventosPartida(any()))
            .thenAnswer((_) async => [
                  {
                    'tipo_evento_codigo': 'GOL',
                    'tipo_evento_nome': 'Gol',
                    'atleta_id': 'jogador1',
                    'atleta_nome_exibicao': 'Cristiano Goleador',
                    'atleta_foto_url': null,
                    'equipe_id': 'atl1',
                    'equipe_nome': 'Time Alpha',
                  },
                  {
                    'tipo_evento_codigo': 'GOL',
                    'tipo_evento_nome': 'Gol',
                    'atleta_id': 'jogador1',
                    'atleta_nome_exibicao': 'Cristiano Goleador',
                    'atleta_foto_url': null,
                    'equipe_id': 'atl1',
                    'equipe_nome': 'Time Alpha',
                  },
                ]);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // MVP card deve aparecer
        expect(find.text('⭐ Destaque da Partida ⭐'), findsOneWidget);
        expect(find.text('Cristiano Goleador'), findsOneWidget);
        expect(find.text('2 Gols'), findsOneWidget);
      },
    );
  });
}
