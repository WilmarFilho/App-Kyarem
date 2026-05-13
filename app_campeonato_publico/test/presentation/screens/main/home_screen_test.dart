import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kyarem_eventos_publico/presentation/screens/main/home_screen.dart';
import 'package:kyarem_eventos_publico/services/partida_service.dart';
import 'package:kyarem_eventos_publico/services/modalidade_service.dart';
import 'package:kyarem_eventos_publico/services/atleta_service.dart';
import 'package:kyarem_eventos_publico/models/partida_model.dart';
import 'package:kyarem_eventos_publico/models/modalidade_model.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockSupabaseStreamFilterBuilder extends Mock implements SupabaseStreamFilterBuilder {}
class MockPartidaService extends Mock implements PartidaService {}
class MockModalidadeService extends Mock implements ModalidadeService {}
class MockAtletaService extends Mock implements AtletaService {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockPartidaService mockPartidaService;
  late MockModalidadeService mockModalidadeService;
  late MockAtletaService mockAtletaService;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockSupabaseStreamFilterBuilder mockStreamBuilder;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    dotenv.testLoad(fileInput: '''
CAMPEONATO_ID=1
APP_NAME=Nome Teste
''');

    mockSupabase = MockSupabaseClient();
    mockPartidaService = MockPartidaService();
    mockModalidadeService = MockModalidadeService();
    mockAtletaService = MockAtletaService();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockStreamBuilder = MockSupabaseStreamFilterBuilder();

    SharedPreferences.setMockInitialValues({});

    // Mocks the stream creation
    when(() => mockSupabase.from('partidas')).thenAnswer((_) => mockQueryBuilder);
    when(() => mockQueryBuilder.stream(primaryKey: any(named: 'primaryKey')))
        .thenAnswer((_) => mockStreamBuilder);
    
    // Simplest way to mock stream listener locally without complex inheritance
    when(() => mockStreamBuilder.listen(
      any(),
      onError: any(named: 'onError'),
      onDone: any(named: 'onDone'),
      cancelOnError: any(named: 'cancelOnError'),
    )).thenAnswer((_) => const Stream<List<Map<String, dynamic>>>.empty().listen((_) {}));

    // Default basic answers
    when(() => mockAtletaService.getTopAthletes(any())).thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(() => mockPartidaService.getFinishedMatches()).thenAnswer((_) async => <Partida>[]);
    when(() => mockModalidadeService.getModalities()).thenAnswer((_) async => <Modalidade>[]);
    when(() => mockPartidaService.getActiveMatches()).thenAnswer((_) async => <Partida>[]);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: HomeScreen(
        supabaseClient: mockSupabase,
        partidaService: mockPartidaService,
        modalidadeService: mockModalidadeService,
        atletaService: mockAtletaService,
      ),
    );
  }

  group('Testes da Tela Inicial (HomeScreen)', () {
    testWidgets('Deve renderizar os placeholders iniciais (como Quadras Vazias)', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('PARTIDAS AO VIVO'), findsOneWidget);
      expect(find.text('QUADRAS VAZIAS NO MOMENTO'), findsOneWidget);
      expect(find.text('ÚLTIMAS FINALIZADAS'), findsOneWidget);
      expect(find.text('Nenhuma partida finalizada recentemente.'), findsOneWidget);
    });

    testWidgets('Deve renderizar modalidades vindo da API', (tester) async {
      when(() => mockModalidadeService.getModalities()).thenAnswer((_) async => [
        Modalidade(id: '1', esporteId: '1', nome: 'FUTSAL MASCULINO'),
      ]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('PARTIDAS AO VIVO'), findsOneWidget);
      expect(find.text('FUTSAL MASCULINO', skipOffstage: false), findsOneWidget);
    });
  });
}
