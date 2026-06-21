import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:farmabook_flutter/router/app_router.dart';
import 'package:farmabook_flutter/services/api_service.dart';
import 'package:farmabook_flutter/utils/global_error_handler.dart';
import 'package:farmabook_flutter/utils/app_logger.dart';
import 'providers/theme_provider.dart';
import 'controllers/almacen_controller.dart';
import 'controllers/lotes_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/notificaciones_controller.dart';
import 'theme/app_theme.dart';

class _AllowAllCerts extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() async {
  HttpOverrides.global = _AllowAllCerts();
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSize = 20;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 10 << 20;
  FlutterError.onError = (details) {
    AppLogger.e('Flutter error', details.exception, details.stack);
    FlutterError.presentError(details);
  };
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.e('Unhandled platform error', error, stack);
    return true;
  };
  await initializeDateFormatting('es', null);
  try {
    await ApiService.init();
    await AppLogger.init();
    AppLogger.i('App initialized');
  } catch (e) {
    debugPrint('Init error: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AlmacenController()),
        ChangeNotifierProvider(create: (_) => LotesController()),
        ChangeNotifierProvider(create: (_) => DashboardController()),
        ChangeNotifierProvider(create: (_) => NotificacionesController()..init()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'FarmaBook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: appRouter,
      scaffoldMessengerKey: globalScaffoldMessengerKey,
    );
  }
}
