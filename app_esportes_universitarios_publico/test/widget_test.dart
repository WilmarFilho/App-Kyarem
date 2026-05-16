// Widget smoke test for the Kyarem Public Sports App.
//
// This test verifies that the root widget builds without throwing.
// More granular tests should be added per screen/feature as the app grows.

import 'package:flutter_test/flutter_test.dart';

import 'package:app_esportes_universitarios_publico/main.dart';

void main() {
  testWidgets('KyaremPublicSportsApp smoke test', (WidgetTester tester) async {
    // Build the root widget and verify it does not throw.
    await tester.pumpWidget(const KyaremPublicSportsApp());
  });
}
