import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:farmabook_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App smoke test', () {
    testWidgets('app launches and shows login screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('Iniciar Sesión'), findsWidgets);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
    });

    testWidgets('tapping login without credentials shows validation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Por favor ingresa tu email'), findsOneWidget);
    });
  });
}
