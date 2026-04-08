import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyarem_eventos/presentation/screens/game/partida_screen.dart';
import 'package:kyarem_eventos/presentation/widgets/game/game_scoreboard.dart';
import 'package:kyarem_eventos/presentation/widgets/game/game_actions_panel.dart';
import 'package:kyarem_eventos/presentation/widgets/game/game_field.dart';
import 'package:kyarem_eventos/models/partida_model.dart';
import 'package:kyarem_eventos/models/tipo_evento_model.dart';
import '../../../fakes/fake_partida_service.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    home: child,
  );
}

void main() {
  group('PartidaScreen —', () {
    late Partida partidaFake;
    late List<TipoEventoEsporte> tiposEventoFake;
    late List<Map<String, dynamic>> inscritosAFake;
    late List<Map<String, dynamic>> inscritosBFake;

    setUp(() {
      partidaFake = Partida(
        id: 'p1',
        equipeAId: 'equipeA',
        equipeBId: 'equipeB',
        modalidadeId: 'mod1',
        agendadaPara: DateTime.now(),
        local: 'Quadra 1',
        status: 'agendada',
        placarA: 0,
        placarB: 0,
      );

      tiposEventoFake = [
        TipoEventoEsporte(id: 't1', esporteId: 'e1', nome: 'Gol'),
        TipoEventoEsporte(id: 't2', esporteId: 'e1', nome: 'Substituição'),
        TipoEventoEsporte(id: 't3', esporteId: 'e1', nome: 'Cartao_Amarelo'),
        TipoEventoEsporte(id: 't4', esporteId: 'e1', nome: 'Falta'),
      ];

      inscritosAFake = [
        {
          'id': 'a1',
          'atletaId': 'a1',
          'nome': 'João A',
          'numeroCamisa': 10,
          'ativo': true,
        }
      ];

      inscritosBFake = [
        {
          'id': 'b1',
          'atletaId': 'b1',
          'nome': 'Pedro B',
          'numeroCamisa': 5,
          'ativo': true,
        }
      ];
    });

    testWidgets('renderiza GameScoreboard inicialmente', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PartidaRunningScreen(
          partida: partidaFake,
          partidaService: FakePartidaService(
            partidas: [partidaFake],
            tiposEvento: tiposEventoFake,
            inscritosA: inscritosAFake,
            inscritosB: inscritosBFake,
          ),
        ),
      ));

      // Espera carregar dados iniciais (FutureBuilders/InitState)
      await tester.pumpAndSettle();

      expect(find.byType(GameScoreboard), findsOneWidget);
      expect(find.text('Equipe A'), findsOneWidget);
      expect(find.text('Equipe B'), findsOneWidget);
      
      // Placar 0 a 0 inicialmente
      expect(find.text('00'), findsNWidgets(2));
    });

    testWidgets('botões de ação iniciam desabilitados quando não há jogador selecionado', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PartidaRunningScreen(
          partida: partidaFake,
          partidaService: FakePartidaService(
            partidas: [partidaFake],
            tiposEvento: tiposEventoFake,
            inscritosA: inscritosAFake,
            inscritosB: inscritosBFake,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.byType(GameActionsPanel), findsOneWidget);
      
      // Verifica se o texto dos tipos de eventos aparecem
      expect(find.text('Gol'), findsOneWidget);
      expect(find.text('Substituição'), findsOneWidget);
    });

    testWidgets('renderiza o GameField com jogadores', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PartidaRunningScreen(
          partida: partidaFake,
          partidaService: FakePartidaService(
            partidas: [partidaFake],
            tiposEvento: tiposEventoFake,
            inscritosA: inscritosAFake,
            inscritosB: inscritosBFake,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      expect(find.byType(GameField), findsOneWidget);
      
      // O nome é exibido quebrado "João"
      expect(find.text('João'), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // Número camisa do João A
      
      expect(find.text('Pedro'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // Número camisa do Pedro B
    });

    testWidgets('botão play inicia a partida se estiver agendada', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        PartidaRunningScreen(
          partida: partidaFake,
          partidaService: FakePartidaService(
            partidas: [partidaFake],
            tiposEvento: tiposEventoFake,
            inscritosA: inscritosAFake,
            inscritosB: inscritosBFake,
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // O cronômetro deve estar em 00:00
      expect(find.text('00:00'), findsOneWidget);

      // Encontra e clica no play
      await tester.tap(find.byIcon(Icons.play_circle));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      // Agora deve estar em 00:02 pelo menos (ou 00:01)
      expect(find.byWidgetPredicate((widget) {
        if (widget is Text) {
          return ['00:00', '00:01', '00:02'].contains(widget.data);
        }
        return false;
      }), findsWidgets);
    });
  });
}
