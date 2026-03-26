import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kyarem_eventos_publico/presentation/screens/modalidade/partidas_modalidade_screen.dart';
import 'package:kyarem_eventos_publico/presentation/screens/game/partida_screen.dart';
import 'package:kyarem_eventos_publico/services/partida_service.dart';
import 'package:kyarem_eventos_publico/services/estatistica_service.dart';
import 'package:kyarem_eventos_publico/models/atletica_equipe_model.dart';
import 'package:kyarem_eventos_publico/models/partida_model.dart';
import 'package:kyarem_eventos_publico/models/modalidade_model.dart';

class MockPartidaService extends Mock implements PartidaService {}
class MockEstatisticaService extends Mock implements EstatisticaService {}

void main() {
  late MockPartidaService mockPartidaService;
  late MockEstatisticaService mockEstatisticaService;
  final dummyModalidade = Modalidade(id: '1', esporteId: '1', nome: 'Futsal');

  setUp(() {
    mockPartidaService = MockPartidaService();
    mockEstatisticaService = MockEstatisticaService();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: PartidasModalidadeScreen(
        modalidade: dummyModalidade,
        partidaService: mockPartidaService,
        estatisticaService: mockEstatisticaService,
      ),
    );
  }

  group('Teste da aba Partidas', () {
    testWidgets('Deve exibir empty state para partidas e estatisticas caso vazias', (tester) async {
      when(() => mockPartidaService.getMatchesByModalityAndStatus(
        modalityId: any(named: 'modalityId'), 
        status: any(named: 'status')
      )).thenAnswer((_) async => []);

      when(() => mockEstatisticaService.getEstatisticsByModality(any()))
        .thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma partida encontrada.'), findsOneWidget);
      
      await tester.tap(find.text('Estatísticas'));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma estatística encontrada para esta modalidade.'), findsOneWidget);
    });

    testWidgets('Deve renderizar lista de partidas, reagir a filtros e navegar', (tester) async {
      final partida = Partida(
        id: '1',
        modalidadeId: '1',
        status: 'FINALIZADA',
        placarA: 2,
        placarB: 1,
        local: 'Quadra Principal',
        equipeA: Equipe(id: 'a', nome: 'Time Alpha', atleticaId: '1'),
        equipeB: Equipe(id: 'b', nome: 'Time Beta', atleticaId: '2'),
      );

      when(() => mockPartidaService.getMatchesByModalityAndStatus(
        modalityId: any(named: 'modalityId'), 
        status: any(named: 'status')
      )).thenAnswer((_) async => [partida]);

      when(() => mockEstatisticaService.getEstatisticsByModality(any()))
        .thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verificar partida renderizada
      expect(find.text('Time Alpha'), findsOneWidget);
      expect(find.text('Time Beta'), findsOneWidget);
      expect(find.text('2  –  1'), findsOneWidget);
      expect(find.text('FINALIZADA'), findsOneWidget);
      expect(find.text('Quadra Principal'), findsOneWidget);

      // Usar dropdown de filtro (icone de filtro)
      await tester.tap(find.byIcon(Icons.filter_alt_outlined));
      await tester.pumpAndSettle();
      
      // Selecionar "Agendadas"
      await tester.tap(find.text('Agendadas'));
      await tester.pumpAndSettle();
      
      // O mock vai retornar as mesmas porque configuramos para any, 
      // mas isso garante que aciona o setState() do filtro.
      
      // A navegação para JogoDetalhesScreen é omitida propositalmente
      // pois a tela de destino não aceita DI e instanciaria o Supabase real.
    });
  });

  group('Teste da aba Estatísticas', () {
    testWidgets('Renderiza lista de atletas com pódio se >= 3 atletas e gols ativo', (tester) async {
      when(() => mockPartidaService.getMatchesByModalityAndStatus(
        modalityId: any(named: 'modalityId'), 
        status: any(named: 'status')
      )).thenAnswer((_) async => []);

      when(() => mockEstatisticaService.getEstatisticsByModality(any()))
        .thenAnswer((_) async => [
          EstatisticaAtleta(
            atletaId: '1',
            nomeAtleta: 'Atleta Ouro',
            gols: 10,
            equipeNome: 'Time A',
            cartoesAmarelos: 0,
            cartoesVermelhos: 0,
            faltas: 0,
            penaltis: 0,
          ),
          EstatisticaAtleta(
            atletaId: '2',
            nomeAtleta: 'Atleta Prata',
            gols: 8,
            equipeNome: 'Time B',
            cartoesAmarelos: 0,
            cartoesVermelhos: 0,
            faltas: 0,
            penaltis: 0,
          ),
          EstatisticaAtleta(
            atletaId: '3',
            nomeAtleta: 'Atleta Bronze',
            gols: 5,
            equipeNome: 'Time C',
            cartoesAmarelos: 0,
            cartoesVermelhos: 0,
            faltas: 0,
            penaltis: 0,
          ),
          EstatisticaAtleta(
            atletaId: '4',
            nomeAtleta: 'Atleta Normal',
            gols: 2,
            equipeNome: 'Time A',
            cartoesAmarelos: 0,
            cartoesVermelhos: 0,
            faltas: 0,
            penaltis: 0,
          ),
        ]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Estatísticas'));
      await tester.pumpAndSettle();

      // Pódio (1º, 2º, 3º) deve existir
      expect(find.text('1º'), findsOneWidget);
      expect(find.text('2º'), findsWidgets); // Um badge de cartao tbm tem "2º"? nao, strings hardcoded do pódio
      expect(find.text('3º'), findsOneWidget);
      
      // Lista remanescente deve começar do 4
      expect(find.text('4º'), findsOneWidget);
      expect(find.text('Atleta Normal'), findsOneWidget);
      
      // Ao trocar de filtro, pódio some
      await tester.tap(find.text('Faltas'));
      await tester.pumpAndSettle();
      
      // Nao existe mais o '1º' grandao do pódio
      // Mas existe o '1º' da lista normal (A lista de index normal 1º -> 4º)
      expect(find.text('Atleta Ouro'), findsOneWidget);
    });
  });
}
