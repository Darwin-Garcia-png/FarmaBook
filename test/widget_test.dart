import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:farmabook_flutter/main.dart';
import 'package:farmabook_flutter/widgets/notification_overlay.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<NotificationService>(
        create: (_) => NotificationService(),
        child: const MyApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
