import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kyarem_eventos_publico/presentation/screens/main/main_screen.dart';
import 'package:kyarem_eventos_publico/presentation/screens/main/home_screen.dart';
import 'package:kyarem_eventos_publico/presentation/screens/main/modalidades_screen.dart';
import 'package:kyarem_eventos_publico/presentation/screens/main/configuracoes_screen.dart';
import 'package:kyarem_eventos_publico/presentation/widgets/layout/bottom_navigation_widget.dart';
import 'package:kyarem_eventos_publico/services/partida_service.dart';
import 'package:kyarem_eventos_publico/services/modalidade_service.dart';
import 'package:kyarem_eventos_publico/services/atleta_service.dart';
import 'package:kyarem_eventos_publico/models/partida_model.dart';
import 'package:kyarem_eventos_publico/models/modalidade_model.dart';
import 'dart:async';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockPartidaService extends Mock implements PartidaService {}
class MockModalidadeService extends Mock implements ModalidadeService {}
class MockAtletaService extends Mock implements AtletaService {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockSupabaseStreamFilterBuilder extends Mock implements SupabaseStreamFilterBuilder {}
class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockPartidaService mockPartidaService;
  late MockModalidadeService mockModalidadeService;
  late MockAtletaService mockAtletaService;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    dotenv.testLoad(fileInput: '''
CAMPEONATO_ID=1
CAMPEONATO_NOME=Campeonato Teste
''');

    mockSupabase = MockSupabaseClient();
    mockPartidaService = MockPartidaService();
    mockModalidadeService = MockModalidadeService();
    mockAtletaService = MockAtletaService();

    SharedPreferences.setMockInitialValues({});
    
    final mockQueryBuilder = MockSupabaseQueryBuilder();
    final mockStreamBuilder = MockSupabaseStreamFilterBuilder();
    final mockAuth = MockGoTrueClient();

    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(null);
    when(() => mockSupabase.from('partidas')).thenAnswer((_) => mockQueryBuilder);
    when(() => mockQueryBuilder.stream(primaryKey: any(named: 'primaryKey')))
        .thenAnswer((_) => mockStreamBuilder);
    when(() => mockStreamBuilder.listen(
      any(),
      onError: any(named: 'onError'),
      onDone: any(named: 'onDone'),
      cancelOnError: any(named: 'cancelOnError'),
    )).thenAnswer((_) => const Stream<List<Map<String, dynamic>>>.empty().listen((_) {}));

    when(() => mockAtletaService.getTopAthletes(any())).thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(() => mockPartidaService.getFinishedMatches()).thenAnswer((_) async => <Partida>[]);
    when(() => mockModalidadeService.getModalities()).thenAnswer((_) async => <Modalidade>[]);
    when(() => mockPartidaService.getActiveMatches()).thenAnswer((_) async => <Partida>[]);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MainScreen(
        supabaseClient: mockSupabase,
        partidaService: mockPartidaService,
        modalidadeService: mockModalidadeService,
        atletaService: mockAtletaService,
      ),
    );
  }

  group('Testes da MainScreen', () {
    testWidgets('Deve renderizar a BottomNavigationWidget e a HomeScreen inicialmente', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationWidget), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Deve trocar de aba para Modalidades ao clicar no seu respectivo ícone', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.sports_soccer_rounded).first);
      await tester.pumpAndSettle();

      expect(find.byType(ModalidadesScreen), findsOneWidget);
    });

    testWidgets('Deve trocar de aba para Configuracoes ao clicar no seu respectivo ícone', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_rounded).first);
      await tester.pumpAndSettle();

      expect(find.byType(ConfiguracoesScreen), findsOneWidget);
    });
  });
}
