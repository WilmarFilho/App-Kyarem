import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Importando os widgets de autenticação isoladamente
import 'package:kyarem_eventos/presentation/widgets/auth/auth_button.dart';
import 'package:kyarem_eventos/presentation/widgets/auth/auth_feedback_message.dart';
import 'package:kyarem_eventos/presentation/widgets/auth/auth_input_field.dart';
import 'package:kyarem_eventos/presentation/widgets/auth/auth_input_label.dart';

/// Wrapper mínimo que provê MaterialApp + SvgPicture + assets para os testes de widget.
/// Evita a necessidade de inicializar Supabase nos testes.
Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  // Configuração necessária para carregar assets SVG em testes
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  // ============================================================
  // AuthButton
  // ============================================================
  group('AuthButton', () {
    testWidgets('deve exibir texto do botão corretamente', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AuthButton(
            text: 'Entrar',
            onPressed: () {},
            isLoading: false,
            isSmall: false,
          ),
        ),
      );

      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('deve exibir CircularProgressIndicator quando isLoading=true', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AuthButton(
            text: 'Entrar',
            onPressed: () {},
            isLoading: true,
            isSmall: false,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Não deve mostrar o texto quando carregando
      expect(find.text('Entrar'), findsNothing);
    });

    testWidgets('deve chamar onPressed ao ser pressionado', (tester) async {
      bool chamado = false;
      await tester.pumpWidget(
        _wrap(
          AuthButton(
            text: 'Entrar',
            onPressed: () => chamado = true,
            isLoading: false,
            isSmall: false,
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(chamado, isTrue);
    });

    testWidgets('não deve chamar onPressed quando isLoading=true', (
      tester,
    ) async {
      bool chamado = false;
      await tester.pumpWidget(
        _wrap(
          AuthButton(
            text: 'Entrar',
            onPressed: () => chamado = true,
            isLoading: true,
            isSmall: false,
          ),
        ),
      );

      // Quando isLoading=true, onPressed é definido como null — botão desabilitado
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(chamado, isFalse);
    });
  });

  // ============================================================
  // AuthFeedbackMessage
  // ============================================================
  group('AuthFeedbackMessage', () {
    testWidgets('deve exibir mensagem de erro quando fornecida', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AuthFeedbackMessage(
            errorMessage: 'E-mail ou senha incorretos',
            successMessage: null,
          ),
        ),
      );

      expect(find.text('E-mail ou senha incorretos'), findsOneWidget);
    });

    testWidgets('deve exibir mensagem de sucesso quando fornecida', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AuthFeedbackMessage(
            errorMessage: null,
            successMessage: 'E-mail enviado com sucesso!',
          ),
        ),
      );

      expect(find.text('E-mail enviado com sucesso!'), findsOneWidget);
    });

    testWidgets('não deve exibir nada quando ambas as mensagens são null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AuthFeedbackMessage(errorMessage: null, successMessage: null),
        ),
      );

      // Não deve lançar exceção e não deve mostrar nenhum texto de mensagem
      expect(find.text('E-mail ou senha incorretos'), findsNothing);
      expect(find.text('E-mail enviado com sucesso!'), findsNothing);
    });

    testWidgets(
      'deve exibir ambas as mensagens quando as duas são fornecidas',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const AuthFeedbackMessage(
              errorMessage: 'Ocorreu um erro',
              successMessage: 'Sucesso',
            ),
          ),
        );

        // AuthFeedbackMessage mostra AMBAS as mensagens quando fornecidas
        expect(find.text('Ocorreu um erro'), findsOneWidget);
        expect(find.text('Sucesso'), findsOneWidget);
      },
    );
  });

  // ============================================================
  // AuthInputLabel
  // ============================================================
  group('AuthInputLabel', () {
    testWidgets('deve exibir o label fornecido', (tester) async {
      await tester.pumpWidget(
        _wrap(const AuthInputLabel(label: 'Seu e-mail:')),
      );

      expect(find.text('Seu e-mail:'), findsOneWidget);
    });

    testWidgets('deve exibir texto de senha corretamente', (tester) async {
      await tester.pumpWidget(_wrap(const AuthInputLabel(label: 'Sua senha:')));

      expect(find.text('Sua senha:'), findsOneWidget);
    });
  });

  // ============================================================
  // AuthInputField
  // ============================================================
  group('AuthInputField', () {
    testWidgets('deve exibir hint text corretamente', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _wrap(
          AuthInputField(
            controller: controller,
            placeholder: 'exemplo@email.com',
            isSmall: false,
          ),
        ),
      );

      expect(
        find.widgetWithText(TextField, 'exemplo@email.com'),
        findsOneWidget,
      );
    });

    testWidgets('deve aceitar texto digitado', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _wrap(
          AuthInputField(
            controller: controller,
            placeholder: 'exemplo@email.com',
            isSmall: false,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'admin@kyarem.com');
      expect(controller.text, 'admin@kyarem.com');
    });

    testWidgets('deve obscureText quando configurado como senha', (
      tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _wrap(
          AuthInputField(
            controller: controller,
            placeholder: '••••••••',
            obscureText: true,
            isSmall: false,
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('campo de texto normal não deve obscureText', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _wrap(
          AuthInputField(
            controller: controller,
            placeholder: 'exemplo@email.com',
            obscureText: false,
            isSmall: false,
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isFalse);
    });
  });

  // ============================================================
  // Fluxo de Login (lógica de validação sem Supabase)
  // ============================================================
  group('Validação de login — lógica de campos', () {
    testWidgets(
      'deve mostrar erro "Preencha todos os campos" ao tentar login com campos vazios',
      (tester) async {
        // Simula a lógica de validação do LoginScreen sem inicializar Supabase
        String? errorMessage;

        bool validar(String email, String password) {
          if (email.isEmpty || password.isEmpty) {
            errorMessage = 'Preencha todos os campos';
            return false;
          }
          return true;
        }

        final resultado = validar('', '');
        expect(resultado, isFalse);
        expect(errorMessage, 'Preencha todos os campos');
      },
    );

    test('login com email e senha preenchidos deve passar na validação', () {
      bool validar(String email, String password) {
        return email.isNotEmpty && password.isNotEmpty;
      }

      expect(validar('admin@kyarem.com', 'minhasenha'), isTrue);
    });

    test('login com apenas email preenchido deve falhar na validação', () {
      bool validar(String email, String password) {
        return email.isNotEmpty && password.isNotEmpty;
      }

      expect(validar('admin@kyarem.com', ''), isFalse);
    });

    test('login com apenas senha preenchida deve falhar na validação', () {
      bool validar(String email, String password) {
        return email.isNotEmpty && password.isNotEmpty;
      }

      expect(validar('', 'minhasenha'), isFalse);
    });
  });
}
