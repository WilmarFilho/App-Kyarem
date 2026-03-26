import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kyarem_eventos_publico/presentation/screens/auth/reset_password_screen.dart';
import 'package:kyarem_eventos_publico/services/auth_service.dart';
import 'package:kyarem_eventos_publico/presentation/widgets/auth/auth_input_field.dart';

class MockAuthService extends Mock implements AuthService {}

class MockUserResponse extends Mock implements UserResponse {}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ResetPasswordScreen(authService: mockAuthService),
      routes: {
        '/login': (context) => const Scaffold(body: Text('Login Route')),
      },
    );
  }

  group('Testes da Tela de Recuperação de Senha (ResetPasswordScreen)', () {
    testWidgets('Renderiza todos os componentes da interface', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('NOVA SENHA'), findsOneWidget);
      expect(find.text('Nova Senha:'), findsOneWidget);
      expect(find.text('Confirmar Senha:'), findsOneWidget);
      expect(find.text('SALVAR NOVA SENHA'), findsOneWidget);
      expect(find.byType(AuthInputField), findsNWidgets(2));
    });

    testWidgets('Exibe erro quando as senhas informadas não coincidem', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'password123');
      await tester.enterText(find.byType(TextField).at(1), 'password456');

      await tester.tap(find.text('SALVAR NOVA SENHA'));
      await tester.pump();

      expect(find.text('As senhas não coincidem'), findsOneWidget);
    });

    testWidgets(
      'Recuperação com sucesso navega para login exibindo mensagem de sucesso (snackbar)',
      (WidgetTester tester) async {
        final mockResponse = MockUserResponse();
        when(
          () => mockAuthService.updatePassword('password123'),
        ).thenAnswer((_) async => mockResponse);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).at(0), 'password123');
        await tester.enterText(find.byType(TextField).at(1), 'password123');

        await tester.tap(find.text('SALVAR NOVA SENHA'));
        // Needed to handle SnackBar rendering
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Login Route'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      },
    );
  });
}
