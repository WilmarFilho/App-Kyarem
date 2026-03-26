import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kyarem_eventos_publico/presentation/screens/auth/register_screen.dart';
import 'package:kyarem_eventos_publico/services/auth_service.dart';
import 'package:kyarem_eventos_publico/presentation/widgets/auth/auth_input_field.dart';

class MockAuthService extends Mock implements AuthService {}

class MockAuthResponse extends Mock implements AuthResponse {}

void main() {
  late MockAuthService mockAuthService;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    mockAuthService = MockAuthService();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(home: RegisterScreen(authService: mockAuthService));
  }

  group('Testes da Tela de Cadastro (RegisterScreen)', () {
    testWidgets('Renderiza todos os componentes da interface', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Nova Conta'), findsOneWidget);
      expect(find.text('E-mail:'), findsOneWidget);
      expect(find.text('Senha:'), findsOneWidget);
      expect(find.text('Confirmar Senha:'), findsOneWidget);
      expect(find.text('CADASTRAR'), findsOneWidget);
      expect(find.byType(AuthInputField), findsNWidgets(3));
    });

    testWidgets(
      'Exibe erro quando tentativa de cadastro possui campos vazios',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        await tester.tap(find.text('CADASTRAR'));
        await tester.pump();

        expect(find.text('Preencha todos os campos'), findsOneWidget);
      },
    );

    testWidgets('Exibe erro quando as senhas informadas não coincidem', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'test@email.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.enterText(find.byType(TextField).at(2), 'password456');

      await tester.tap(find.text('CADASTRAR'));
      await tester.pump();

      expect(find.text('As senhas não coincidem'), findsOneWidget);
    });

    testWidgets('Exibe erro quando a senha é muito curta', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'test@email.com');
      await tester.enterText(find.byType(TextField).at(1), '12345');
      await tester.enterText(find.byType(TextField).at(2), '12345');

      await tester.tap(find.text('CADASTRAR'));
      await tester.pump();

      expect(
        find.text('A senha deve ter pelo menos 6 caracteres'),
        findsOneWidget,
      );
    });

    testWidgets('Cadastro com sucesso exibe mensagem de confirmação', (
      WidgetTester tester,
    ) async {
      final mockResponse = MockAuthResponse();
      when(
        () => mockAuthService.signUp(
          email: 'test@email.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => mockResponse);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'test@email.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.enterText(find.byType(TextField).at(2), 'password123');

      await tester.tap(find.text('CADASTRAR'));
      await tester.pumpAndSettle();

      expect(
        find.text('Conta criada! Verifique seu e-mail para confirmar.'),
        findsOneWidget,
      );
      verify(
        () => mockAuthService.signUp(
          email: 'test@email.com',
          password: 'password123',
        ),
      ).called(1);
    });
  });
}
