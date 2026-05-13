import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kyarem_eventos_publico/presentation/screens/game/estatistica_atleta_screen.dart';
import 'package:kyarem_eventos_publico/services/game_service.dart';
import 'package:kyarem_eventos_publico/services/evento_service.dart';
import 'package:kyarem_eventos_publico/models/atleta_model.dart';

// ── Mocks ──────────────────────────────────────────────────────────────
class MockGameService extends Mock implements GameService {}
class MockEventoService extends Mock implements EventoService {}

void main() {
  late MockGameService mockGameService;
  late MockEventoService mockEventoService;

  final dummyAtleta = Atleta(
    id: 'atleta1',
    atleticaId: 'atl1',
    nome: 'Carlos Silva',
  );

  setUp(() {
    mockGameService = MockGameService();
    mockEventoService = MockEventoService();

    // Stubs padrão para o fluxo com partidaId
    when(() => mockGameService.getPartidaEquipes(any()))
        .thenAnswer((_) async => {'modalidade_id': 'm1', 'equipe_a_id': 'ea1', 'equipe_b_id': 'eb1'});

    when(() => mockGameService.getPartidaComEquipes(any()))
        .thenAnswer((_) async => {'modalidade_id': 'm1'});

    when(() => mockEventoService.getEventTypesByModality(any()))
        .thenAnswer((_) async => <Map<String, dynamic>>[]);

    when(() => mockGameService.getEventosAtleta(any(), any()))
        .thenAnswer((_) async => <Map<String, dynamic>>[]);
  });

  Widget createWidgetUnderTest({List<Map<String, dynamic>>? eventos}) {
    if (eventos != null) {
      when(() => mockGameService.getEventosAtleta(any(), any()))
          .thenAnswer((_) async => eventos);
    }

    return MaterialApp(
      home: EstatisticaAtletaScreen(
        partidaId: '1',
        atleta: dummyAtleta,
        timeNome: 'Time Alpha',
        gameService: mockGameService,
        eventoService: mockEventoService,
      ),
    );
  }

  group('Testes da Tela de Estatísticas do Atleta (EstatisticaAtletaScreen)', () {
    testWidgets(
      'Exibe o título do AppBar corretamente',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('ESTATÍSTICAS DO ATLETA'), findsOneWidget);
      },
    );

    testWidgets(
      'Exibe nome do atleta e do time no header',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Carlos Silva'), findsOneWidget);
        expect(find.text('Time Alpha'), findsOneWidget);
      },
    );

    testWidgets(
      'Exibe grid de estatísticas com valores zerados quando não há eventos',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Cards de estatísticas
        expect(find.text('Gols'), findsOneWidget);
        expect(find.text('Faltas'), findsOneWidget);
        expect(find.text('C. Amarelo'), findsOneWidget);
        expect(find.text('C. Vermelho'), findsOneWidget);

        // Todos valores devem ser 0
        expect(find.text('0'), findsNWidgets(4));
      },
    );

    testWidgets(
      'Exibe mensagem de nenhum lance quando timeline está vazia',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(
          find.text('Nenhum lance registrado para este atleta na partida.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Exibe o título LANCES DESTA PARTIDA quando partidaId é definida',
      (tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('LANCES DESTA PARTIDA'), findsOneWidget);
      },
    );

    testWidgets(
      'Calcula contadores corretamente com eventos mockados',
      (tester) async {
        // Mock tipos de eventos
        when(() => mockEventoService.getEventTypesByModality(any()))
            .thenAnswer((_) async => [
                  {'id': 't1', 'nome': 'GOL'},
                  {'id': 't2', 'nome': 'FALTA'},
                  {'id': 't3', 'nome': 'CARTAO_AMARELO'},
                ]);

        // Mock eventos do atleta
        final eventos = [
          {'tipo_evento_id': 't1', 'atleta_id': 'atleta1', 'tempo_cronometro': '05:30'},
          {'tipo_evento_id': 't1', 'atleta_id': 'atleta1', 'tempo_cronometro': '12:00'},
          {'tipo_evento_id': 't2', 'atleta_id': 'atleta1', 'tempo_cronometro': '20:00'},
          {'tipo_evento_id': 't3', 'atleta_id': 'atleta1', 'tempo_cronometro': '25:00'},
        ];

        await tester.pumpWidget(createWidgetUnderTest(eventos: eventos));
        await tester.pumpAndSettle();

        // 2 gols, 1 falta, 1 cartão amarelo, 0 vermelho
        expect(find.text('2'), findsOneWidget); // gols
        expect(find.text('1'), findsNWidgets(2)); // falta + C. Amarelo
        expect(find.text('0'), findsOneWidget); // C. Vermelho
      },
    );
  });
}
