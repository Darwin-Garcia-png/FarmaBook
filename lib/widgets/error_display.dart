import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'notification_overlay.dart';

class ErrorDisplay {
  ErrorDisplay._();

  static Widget fullScreen({
    String? title,
    required String message,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.reiOrangeRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.reiOrangeRed),
            ),
            const SizedBox(height: 24),
            Text(title ?? 'Error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.reiOrangeRed)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.reiOrangeRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                label: const Text('REINTENTAR', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget inline({
    String? title,
    required String message,
    VoidCallback? onDismiss,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.reiOrangeRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 20, color: AppTheme.reiOrangeRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title ?? 'Error',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.reiOrangeRed)),
                const SizedBox(height: 4),
                Text(message,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
              ],
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close, size: 18, color: AppTheme.reiOrangeRed),
            ),
        ],
      ),
    );
  }

  static Future<void> dialog({
    required BuildContext context,
    required String message,
    String title = 'Error',
  }) async {
    context.read<NotificationService>().error(cleanMessage(message), title: title);
  }

  static void snackBar({
    required BuildContext context,
    required String message,
    String? title,
  }) {
    context.read<NotificationService>().error(cleanMessage(message), title: title);
  }

  static void successSnackBar({
    required BuildContext context,
    required String message,
  }) {
    context.read<NotificationService>().success(message);
  }

  static String cleanMessage(dynamic error) {
    if (error == null) return 'Error desconocido';
    try {
      if (error is ApiException) {
        return _cleanErrorCode(error.message);
      }
      final resp = error.response;
      if (resp != null && resp.data is Map) {
        final d = resp.data as Map;
        final msg = d['message'] ?? d['error'] ?? d['mensaje'];
        if (msg != null && msg.toString().isNotEmpty) return _cleanErrorCode(msg.toString());
      }
      if (resp != null && resp.data is String) {
        return _cleanErrorCode(resp.data.toString());
      }
    } catch (_) {}
    return _cleanErrorCode(error.toString());
  }

  static final _errorCodeReg = RegExp(r'^Error\s+\d{3}:\s*', caseSensitive: false);
  static final _errorCodeOnlyReg = RegExp(r'^Error\s+\d{3}\s*$', caseSensitive: false);

  static String _cleanErrorCode(String s) {
    if (_errorCodeOnlyReg.hasMatch(s)) {
      final code = int.tryParse(RegExp(r'\d{3}').firstMatch(s)?.group(0) ?? '');
      if (code != null) return _statusMessage(code);
    }
    return s
        .replaceAll(RegExp(r'^Exception:\s*'), '')
        .replaceAll(RegExp(r'^HttpException:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^SocketException:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^FormatException:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^TypeError:\s*', caseSensitive: false), '')
        .replaceAll(_errorCodeReg, '')
        .trim();
  }

  static String _statusMessage(int code) {
    if (code >= 500) return 'Error interno del servidor. Intenta más tarde.';
    if (code == 404) return 'Recurso no encontrado en el servidor.';
    if (code == 403) return 'No tienes permiso para realizar esta acción.';
    if (code == 401) return 'Sesión expirada o credenciales inválidas.';
    if (code == 409) return 'Conflicto: el recurso ya existe o está en uso.';
    if (code == 422) return 'Datos inválidos enviados al servidor.';
    if (code == 400) return 'Solicitud inválida. Revisa los datos.';
    return 'Error del servidor (código $code).';
  }
}
