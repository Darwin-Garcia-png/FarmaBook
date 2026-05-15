import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:farmabook_flutter/router/app_router.dart';
import 'package:farmabook_flutter/utils/global_error_handler.dart';
import 'providers/theme_provider.dart';
import 'controllers/almacen_controller.dart';
import 'controllers/lotes_controller.dart';
import 'controllers/notificaciones_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AlmacenController()..init()),
        ChangeNotifierProvider(create: (_) => LotesController()..init()),
        ChangeNotifierProvider(create: (_) => NotificacionesController()..init()),
        ChangeNotifierProvider(create: (_) => DashboardController()),
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