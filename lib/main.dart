import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:farmabook_flutter/router/app_router.dart';
import 'package:farmabook_flutter/services/api_service.dart';
import 'package:farmabook_flutter/utils/global_error_handler.dart';
import 'package:farmabook_flutter/utils/app_logger.dart';
import 'package:farmabook_flutter/utils/http_overrides.dart';
import 'controllers/almacen_controller.dart';
import 'controllers/lotes_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/notificaciones_controller.dart';
import 'widgets/notification_overlay.dart';
import 'theme/app_theme.dart';

void main() async {
  applyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSize = 20;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 10 << 20;
  await initializeDateFormatting('es', null);
  try {
    await ApiService.init();
    await AppLogger.init();
  } catch (e) {
    debugPrint('Init error: $e');
  }
  FlutterError.onError = (details) {
    AppLogger.e('Flutter error', details.exception, details.stack);
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    } else {
      FlutterError.presentError(details);
    }
  };
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.e('Unhandled platform error', error, stack);
    return true;
  };
  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AlmacenController()),
          ChangeNotifierProvider(create: (_) => LotesController()),
          ChangeNotifierProvider(create: (_) => DashboardController()),
          ChangeNotifierProvider(create: (_) => NotificacionesController()..init()),
          ChangeNotifierProvider(create: (_) => NotificationService()),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    AppLogger.e('Unhandled zone error', error, stack);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FarmaBook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      scaffoldMessengerKey: globalScaffoldMessengerKey,
      builder: (context, child) {
        if (kReleaseMode) {
          ErrorWidget.builder = (details) {
            AppLogger.e('Build error', details.exception, details.stack);
            return Material(
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error de interfaz',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        details.exception.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            );
          };
        }
        return NotificationOverlay(child: child!);
      },
    );
  }
}
