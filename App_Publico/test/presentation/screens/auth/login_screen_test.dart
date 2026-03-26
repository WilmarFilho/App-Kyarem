import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kyarem_eventos_publico/presentation/screens/auth/login_screen.dart';
import 'package:kyarem_eventos_publico/services/auth_service.dart';
import 'package:kyarem_eventos_publico/presentation/widgets/auth/auth_input_field.dart';

class MockAuthService extends Mock implements AuthService {}
class MockUser extends Mock implements User {}

void main() {
  late MockAuthService mockAuthService;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    mockAuthService = MockAuthService();
    // Default mocks required by initState
    when(() => mockAuthService.currentSession).thenReturn(null);
    when(() => mockAuthService.getSavedCredentials()).thenAnswer((_) async => {
      'email': '',
      'password': '',
      'remember': false,
    });
  });

  Widget createWidgetUnderTest({Size? windowSize}) {
    return MaterialApp(
      // Override text scale and layout sizes for responsivity tests
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: windowSize ?? const Size(400, 800),
          ),
          child: child!,
        );
      },
      home: LoginScreen(authService: mockAuthService),
      routes: {
        '/home': (context) => const Scaffold(body: Text('Home Route')),
        '/register': (context) => const Scaffold(body: Text('Register Route')),
      },
    );
  }

  group('Testes da Tela de Login (LoginScreen)', () {
    testWidgets('Renderiza todos os componentes essenciais da interface', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Seu e-mail:'), findsOneWidget);
      expect(find.text('Sua senha:'), findsOneWidget);
      expect(find.byType(AuthInputField), findsNWidgets(2));
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Lembrar'), findsOneWidget);
      expect(find.text('Esqueci a senha'), findsOneWidget);
    });

    testWidgets('Exibe mensagem de erro quando os campos estão vazios', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Entrar'));
      await tester.pump();

      expect(find.text('Preencha todos os campos'), findsOneWidget);
      verifyNever(() => mockAuthService.login(
        email: any(named: 'email'), 
        password: any(named: 'password'), 
        rememberMe: any(named: 'rememberMe')
      ));
    });

    testWidgets('Login com sucesso navega para a rota /home', (WidgetTester tester) async {
      when(() => mockAuthService.login(
        email: 'test@email.com',
        password: 'password123',
        rememberMe: false,
      )).thenAnswer((_) async => MockUser());

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter email
      await tester.enterText(find.byType(TextField).at(0), 'test@email.com');
      // Enter password
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      
      // Tap login
      await tester.tap(find.text('Entrar'));
      await tester.pump(); // Start loading
      await tester.pumpAndSettle(); // Finish loading and navigation

      // Verify navigation to home route
      expect(find.text('Home Route'), findsOneWidget);
      verify(() => mockAuthService.login(
        email: 'test@email.com',
        password: 'password123',
        rememberMe: false,
      )).called(1);
    });

    testWidgets('Credenciais inválidas exibem mensagem de erro', (WidgetTester tester) async {
      when(() => mockAuthService.login(
        email: 'wrong@email.com',
        password: 'wrongpassword',
        rememberMe: false,
      )).thenThrow(const AuthException('Invalid login credentials', statusCode: '400'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'wrong@email.com');
      await tester.enterText(find.byType(TextField).at(1), 'wrongpassword');
      
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('E-mail ou senha incorretos'), findsOneWidget);
    });

    testWidgets('Erro de rede exibe mensagem amigável de erro de conexão', (WidgetTester tester) async {
      when(() => mockAuthService.login(
        email: 'test@email.com',
        password: 'password',
        rememberMe: false,
      )).thenThrow(const AuthException('network connection failed'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'test@email.com');
      await tester.enterText(find.byType(TextField).at(1), 'password');
      
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Sem conexão'), findsOneWidget);
    });

    testWidgets('Adapta o layout corretamente para telas pequenas', (WidgetTester tester) async {
      // Screen width < 393
      await tester.pumpWidget(createWidgetUnderTest(windowSize: const Size(320, 600)));
      await tester.pumpAndSettle();

      // Ensure no overflow errors and proper rendering
      expect(find.text('Login'), findsOneWidget);
      
      // Verify text size change on Title implicitly by no exceptions being thrown 
      // when laid out (a full test could inspect the RenderObject or TextStyle directly)
      final textWidget = tester.widget<Text>(find.text('Login'));
      expect(textWidget.style?.fontSize, 28);
    });
  });
}
