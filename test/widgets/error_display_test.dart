import 'package:flutter_test/flutter_test.dart';
import 'package:farmabook_flutter/widgets/error_display.dart';
import 'package:farmabook_flutter/widgets/notification_overlay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  group('ErrorDisplay.cleanMessage', () {
    test('returns message for string error', () {
      final msg = ErrorDisplay.cleanMessage('Error de conexión');
      expect(msg, contains('Error de conexión'));
    });
  });

  group('ErrorDisplay.fullScreen widget', () {
    testWidgets('renders message and retry button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay.fullScreen(
              message: 'Error de conexión',
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Error de conexión'), findsOneWidget);
      expect(find.text('REINTENTAR'), findsOneWidget);
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
      expect(find.text('REINTENTAR'), findsNothing);
    });
  });

  group('ErrorDisplay.inline widget', () {
    testWidgets('renders message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay.inline(
              message: 'Algo salió mal',
            ),
          ),
        ),
      );

      expect(find.text('Algo salió mal'), findsOneWidget);
    });
  });

  group('ErrorDisplay.snackBar', () {
    testWidgets('delegates to NotificationService without crash', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<NotificationService>(
          create: (_) => NotificationService(),
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => ErrorDisplay.snackBar(context: context, message: 'Error test'),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
    });
  });

  group('ErrorDisplay.successSnackBar', () {
    testWidgets('delegates to NotificationService without crash', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<NotificationService>(
          create: (_) => NotificationService(),
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => ErrorDisplay.successSnackBar(context: context, message: 'Éxito'),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();
    });
  });
}
