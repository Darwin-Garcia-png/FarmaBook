import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:farmabook_flutter/controllers/login_controller.dart';
import 'package:farmabook_flutter/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuth;
  late LoginController controller;

  setUp(() {
    mockAuth = MockAuthService();
    controller = LoginController(authService: mockAuth);
  });

  tearDown(() {
    controller.dispose();
  });

  group('LoginController', () {
    test('initial state is correct', () {
      expect(controller.isLoading, false);
      expect(controller.obscurePassword, true);
      expect(controller.emailController.text, '');
      expect(controller.passwordController.text, '');
    });

    test('togglePasswordVisibility flips obscurePassword', () {
      expect(controller.obscurePassword, true);
      controller.togglePasswordVisibility();
      expect(controller.obscurePassword, false);
      controller.togglePasswordVisibility();
      expect(controller.obscurePassword, true);
    });

    test('togglePasswordVisibility calls notifyListeners', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.togglePasswordVisibility();
      expect(notified, true);
    });
  });

  group('LoginController.login (requires widget tree)', () {
    testWidgets('returns false when form is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Form(key: controller.formKey, child: const SizedBox()))),
      );

      final result = await controller.login();
      expect(result, false);
    });

    testWidgets('calls authService with credentials when form is valid', (tester) async {
      controller.emailController.text = 'test@farmabook.com';
      controller.passwordController.text = 'Password123';

      when(() => mockAuth.login(any(), any())).thenAnswer((_) async => {
        'statusCode': 401,
        'body': {'error': {'message': 'bad'}},
      });
      when(() => mockAuth.getToken()).thenAnswer((_) async => null);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Form(key: controller.formKey, child: const SizedBox()))),
      );

      await controller.login();

      verify(() => mockAuth.login('test@farmabook.com', 'Password123')).called(1);
    });

    testWidgets('returns false on API error', (tester) async {
      controller.emailController.text = 'test@farmabook.com';
      controller.passwordController.text = 'Password123';

      when(() => mockAuth.login(any(), any())).thenAnswer((_) async => ({
        'statusCode': 401,
        'body': {'error': {'message': 'Credenciales inválidas'}},
      }));
      when(() => mockAuth.getToken()).thenAnswer((_) async => null);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Form(key: controller.formKey, child: const SizedBox()))),
      );

      final result = await controller.login();
      expect(result, false);
    });

    testWidgets('returns false when token is missing after 200', (tester) async {
      controller.emailController.text = 'test@farmabook.com';
      controller.passwordController.text = 'Password123';

      when(() => mockAuth.login(any(), any())).thenAnswer((_) async => ({
        'statusCode': 200,
        'body': {},
      }));
      when(() => mockAuth.getToken()).thenAnswer((_) async => null);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Form(key: controller.formKey, child: const SizedBox()))),
      );

      final result = await controller.login();
      expect(result, false);
    });
  });
}
