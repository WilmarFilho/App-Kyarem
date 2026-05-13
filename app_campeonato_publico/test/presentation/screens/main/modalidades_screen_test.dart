import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kyarem_eventos_publico/presentation/screens/main/modalidades_screen.dart';
import 'package:kyarem_eventos_publico/presentation/screens/modalidade/partidas_modalidade_screen.dart';
import 'package:kyarem_eventos_publico/services/modalidade_service.dart';
import 'package:kyarem_eventos_publico/services/partida_service.dart';
import 'package:kyarem_eventos_publico/services/estatistica_service.dart';
import 'package:kyarem_eventos_publico/models/campeonato_model.dart';
import 'package:kyarem_eventos_publico/models/modalidade_model.dart';

class MockModalidadeService extends Mock implements ModalidadeService {}
class MockPartidaService extends Mock implements PartidaService {}
class MockEstatisticaService extends Mock implements EstatisticaService {}

void main() {
  late MockModalidadeService mockService;
  late MockPartidaService mockPartidaService;
  late MockEstatisticaService mockEstatisticaService;
  final dummyCampeonato = Campeonato(id: '1', nome: 'Campeonato Teste');

  setUp(() {
    mockService = MockModalidadeService();
    mockPartidaService = MockPartidaService();
    mockEstatisticaService = MockEstatisticaService();
    
    when(() => mockPartidaService.getMatchesByModalityAndStatus(
      modalityId: any(named: 'modalityId'), 
      status: any(named: 'status')
    )).thenAnswer((_) async => []);
    
    when(() => mockEstatisticaService.getEstatisticsByModality(any()))
      .thenAnswer((_) async => []);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ModalidadesScreen(
        campeonato: dummyCampeonato,
        modalidadeService: mockService,
        partidaService: mockPartidaService,
        estatisticaService: mockEstatisticaService,
      ),
    );
  }

  group('Testes da Tela de Modalidades (ModalidadesScreen)', () {
    testWidgets('Exibe CircularProgressIndicator enquanto carrega', (
      tester,
    ) async {
      when(() => mockService.getModalities()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        return <Modalidade>[];
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(
        const Duration(milliseconds: 100),
      ); // allow Future to start

      // Initially, CircularProgressIndicator must be on screen
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle(); // Resolve future to avoid pending timers
    });

    testWidgets(
      'Exibe mensagem de erro e botão de recarregar quando não há resultados',
      (tester) async {
        when(
          () => mockService.getModalities(),
        ).thenAnswer((_) async => <Modalidade>[]);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Nenhuma modalidade encontrada.'), findsOneWidget);
        expect(find.text('Tentar novamente'), findsOneWidget);
      },
    );

    testWidgets('Renderiza a lista de modalidades corretamente', (
      tester,
    ) async {
      when(() => mockService.getModalities()).thenAnswer(
        (_) async => [
          Modalidade(
            id: '1',
            esporteId: '1',
            nome: 'Futsal Masculino',
            esporteNome: 'Futsal',
          ),
          Modalidade(
            id: '2',
            esporteId: '2',
            nome: 'Vôlei Feminino',
            esporteNome: 'Vôlei',
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('FUTSAL MASCULINO'), findsOneWidget);
      expect(find.text('VÔLEI FEMININO'), findsOneWidget);
      expect(find.text('Futsal'), findsOneWidget);
      expect(find.text('Vôlei'), findsOneWidget);
    });

    testWidgets('Navega para a tela de PartidasModalidade ao clicar em uma modalidade', (tester) async {
      when(() => mockService.getModalities()).thenAnswer(
        (_) async => [
          Modalidade(
            id: '1',
            esporteId: '1',
            nome: 'Futsal Masculino',
            esporteNome: 'Futsal',
          ),
        ],
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('FUTSAL MASCULINO'));
      await tester.pumpAndSettle();

      expect(find.byType(PartidasModalidadeScreen), findsOneWidget);
    });
  });
}
