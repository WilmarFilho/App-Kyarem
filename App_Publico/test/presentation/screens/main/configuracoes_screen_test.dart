import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kyarem_eventos_publico/presentation/screens/main/configuracoes_screen.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    
    // Default behaviors
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(null);
    
    // Injeção de SharedPreferences mockado para os testes UI
    SharedPreferences.setMockInitialValues({
      'notif_gerais': true,
      'notif_partidas': true,
      'notif_resultados': true,
      'modo_escuro': false,
    });
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ConfiguracoesScreen(supabaseClient: mockSupabase),
    );
  }

  group('Testes da Tela de Configurações (ConfiguracoesScreen)', () {
    testWidgets('Deve renderizar UI corretamente e carregar as preferências base', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Ajuste suas configurações.'), findsOneWidget);
      expect(find.text('CONFIGURAÇÕES'), findsOneWidget);
      expect(find.text('NOTIFICAÇÕES'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(4));
    });

    testWidgets('Deve desabilitar todas sub-notificações ao desligar notificações gerais', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find the switches
      final switches = find.byType(Switch);
      expect(tester.widget<Switch>(switches.at(0)).value, true); 
      expect(tester.widget<Switch>(switches.at(1)).value, true); 
      
      // Tap desativando gerais
      await tester.tap(switches.at(0));
      await tester.pumpAndSettle();

      // Ensure partidas and resultados toggled off automatically
      expect(tester.widget<Switch>(switches.at(1)).value, false);
      expect(tester.widget<Switch>(switches.at(2)).value, false);
    });

    testWidgets('Mostra dialog de alterar senha e apresenta snackbar de sucesso', (tester) async {
      when(() => mockAuth.resetPasswordForEmail(any(), redirectTo: any(named: 'redirectTo')))
          .thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Centraliza perfeitamente na tela usando Scrollable
      final element = tester.element(find.text('Alterar Senha'));
      await Scrollable.ensureVisible(element, alignment: 0.5);
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Alterar Senha'));
      await tester.pumpAndSettle();

      // Verifica se o AlertDialog apareceu
      expect(find.text('Digite seu e-mail para receber o link de redefinição de senha.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'test@example.com');
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();

      // Valida o envio (Snackbar)
      expect(find.text('E-mail de redefinição enviado!'), findsOneWidget);
    });
  });
}
