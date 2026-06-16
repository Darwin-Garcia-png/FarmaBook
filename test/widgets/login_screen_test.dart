import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:farmabook_flutter/controllers/almacen_controller.dart';
import 'package:farmabook_flutter/controllers/lotes_controller.dart';
import 'package:farmabook_flutter/screens/login_screen.dart';

class MockAlmacenController extends Mock implements AlmacenController {}
class MockLotesController extends Mock implements LotesController {}

Widget createLoginScreen() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: MockAlmacenController()),
      ChangeNotifierProvider.value(value: MockLotesController()),
    ],
    child: const MaterialApp(
      home: LoginScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginScreen', () {
    testWidgets('renders login form with email and password fields', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      expect(find.byType(TextFormField), findsAtLeast(1));
      expect(find.text('Iniciar Sesión'), findsWidgets);
    });

    testWidgets('has register link - two separate texts', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      expect(find.text('¿No tienes cuenta? '), findsOneWidget);
      expect(find.text('Registrarse'), findsOneWidget);
    });

    testWidgets('tapping Registrarse opens dialog', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      await tester.tap(find.text('Registrarse'));
      await tester.pump();

      expect(find.text('Crear Cuenta'), findsOneWidget);
    });

    testWidgets('register dialog has form fields and role dropdown', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      await tester.tap(find.text('Registrarse'));
      await tester.pump();

      expect(find.text('Usuario *'), findsOneWidget);
      expect(find.text('Email *'), findsOneWidget);
      expect(find.text('Contraseña *'), findsOneWidget);
      expect(find.text('ROL'), findsOneWidget);
    });

    testWidgets('register dialog can be cancelled', (tester) async {
      await tester.pumpWidget(createLoginScreen());
      await tester.pump();

      await tester.tap(find.text('Registrarse'));
      await tester.pump();

      await tester.tap(find.text('CANCELAR'));
      await tester.pump();

      expect(find.text('Crear Cuenta'), findsNothing);
    });
  });
}
