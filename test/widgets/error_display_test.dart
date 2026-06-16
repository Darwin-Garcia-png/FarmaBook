import 'package:flutter_test/flutter_test.dart';
import 'package:farmabook_flutter/widgets/error_display.dart';
import 'package:flutter/material.dart';

void main() {
  group('ErrorDisplay.hintFromMessage', () {
    test('returns connection hint on socket/refused', () {
      final hint = ErrorDisplay.hintFromMessage('Connection refused');
      expect(hint, contains('servidor no está disponible'));
    });

    test('returns timeout hint on timeout', () {
      final hint = ErrorDisplay.hintFromMessage('Request timed out');
      expect(hint, contains('tardó demasiado'));
    });

    test('returns auth hint on 401', () {
      final hint = ErrorDisplay.hintFromMessage('401 Unauthorized');
      expect(hint, contains('sesión expiró'));
    });

    test('returns auth hint on token error', () {
      final hint = ErrorDisplay.hintFromMessage('Invalid token');
      expect(hint, contains('sesión expiró'));
    });

    test('returns forbidden hint on 403', () {
      final hint = ErrorDisplay.hintFromMessage('403 Forbidden');
      expect(hint, contains('No tienes permisos'));
    });

    test('returns not found hint on 404', () {
      final hint = ErrorDisplay.hintFromMessage('404 Not Found');
      expect(hint, contains('recurso solicitado no existe'));
    });

    test('returns conflict hint on 409', () {
      final hint = ErrorDisplay.hintFromMessage('409 Conflict: ya existe');
      expect(hint, contains('ya está registrado'));
    });

    test('returns validation hint on validation error', () {
      final hint = ErrorDisplay.hintFromMessage('Validation error');
      expect(hint, contains('campos tengan valores válidos'));
    });

    test('returns null for unknown error', () {
      final hint = ErrorDisplay.hintFromMessage('Unknown error occurred');
      expect(hint, isNull);
    });

    test('is case insensitive', () {
      final hint = ErrorDisplay.hintFromMessage('CONNECTION REFUSED');
      expect(hint, contains('servidor no está disponible'));
    });

    group('mixed/compound messages', () {
      test('matches 401 even with extra text', () {
        final hint = ErrorDisplay.hintFromMessage('Error 401: Invalid credentials');
        expect(hint, contains('sesión expiró'));
      });

      test('matches 404 even with extra text', () {
        final hint = ErrorDisplay.hintFromMessage('GET /users/999 returned 404');
        expect(hint, contains('recurso solicitado no existe'));
      });
    });
  });

  group('ErrorDisplay.fullScreen widget', () {
    testWidgets('renders message and retry button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay.fullScreen(
              message: 'Error de conexión',
              hint: 'Verifica tu internet',
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Error de conexión'), findsOneWidget);
      expect(find.text('Verifica tu internet'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('renders without retry button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay.fullScreen(
              message: 'Error sin retry',
            ),
          ),
        ),
      );

      expect(find.text('Error sin retry'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
    });
  });

  group('ErrorDisplay.inline widget', () {
    testWidgets('renders message and hint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay.inline(
              message: 'Algo salió mal',
              hint: 'Intenta de nuevo',
            ),
          ),
        ),
      );

      expect(find.text('Algo salió mal'), findsOneWidget);
      expect(find.text('Intenta de nuevo'), findsOneWidget);
    });
  });

  group('ErrorDisplay.snackBar', () {
    testWidgets('shows error SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ErrorDisplay.snackBar(context: context, message: 'Error test'),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Error test'), findsOneWidget);
    });
  });

  group('ErrorDisplay.successSnackBar', () {
    testWidgets('shows success SnackBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ErrorDisplay.successSnackBar(context: context, message: 'Éxito'),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('Éxito'), findsOneWidget);
    });
  });
}
