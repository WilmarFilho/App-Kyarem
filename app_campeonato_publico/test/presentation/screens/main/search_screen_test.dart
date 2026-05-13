import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kyarem_eventos_publico/presentation/screens/main/search_screen.dart';

void main() {
  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: const SearchScreen(),
      routes: {
        '/modalidades': (context) => const Scaffold(body: Text('Route Modalidades')),
        '/perfil': (context) => const Scaffold(body: Text('Route Perfil')),
        '/configuracoes': (context) => const Scaffold(body: Text('Route Configuracoes')),
      },
    );
  }

  group('Testes da Tela de Busca (SearchScreen)', () {
    testWidgets('Deve exibir os atalhos rápidos iniciais', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Explorar Modalidades'), findsOneWidget);
      expect(find.text('Meu Perfil'), findsOneWidget);
      expect(find.text('Configurações'), findsOneWidget);
    });

    testWidgets('Deve filtrar atalhos ao digitar na busca', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Busca um campo de texto e digita
      await tester.enterText(find.byType(TextField), 'Perfil');
      await tester.pumpAndSettle();

      expect(find.text('Meu Perfil'), findsOneWidget);
      // Os outros devem sumir
      expect(find.text('Explorar Modalidades'), findsNothing);
      expect(find.text('Configurações'), findsNothing);
    });

    testWidgets('Deve exibir mensagem vazia quando não há resultados', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'TermoInexistente123');
      await tester.pumpAndSettle();

      expect(find.text('Nenhum resultado encontrado.'), findsOneWidget);
    });
  });
}
