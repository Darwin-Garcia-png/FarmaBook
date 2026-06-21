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
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(TextFormField), findsAtLeast(1));
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    });
  });
}
