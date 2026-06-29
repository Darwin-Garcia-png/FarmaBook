import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../router/app_router.dart';
import '../widgets/notification_overlay.dart';

final GlobalKey<ScaffoldMessengerState> globalScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class GlobalErrorHandler {
  static void showError(String message, {int? statusCode}) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    String title = 'Error';
    if (statusCode != null) {
      if (statusCode == 404) title = 'Recurso No Encontrado';
      else if (statusCode == 401 || statusCode == 403) title = 'Problema de Autenticación';
      else if (statusCode >= 500) title = 'Error del Servidor';
    }
    ctx.read<NotificationService>().error(message, title: title);
  }
}
