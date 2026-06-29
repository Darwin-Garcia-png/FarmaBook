import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ErrorDisplay {
  ErrorDisplay._();

  static Widget fullScreen({
    required String message,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.reiOrangeRed)),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.reiOrangeRed, foregroundColor: Colors.white),
                child: const Text('REINTENTAR'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget inline({
    required String message,
    VoidCallback? onDismiss,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.reiOrangeRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(child: Text(message,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.reiOrangeRed))),
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
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.reiOrangeRed)),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ACEPTAR', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  static void snackBar({
    required BuildContext context,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.reiOrangeRed,
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  static void successSnackBar({
    required BuildContext context,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.greenMetal,
        behavior: SnackBarBehavior.floating,
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  static String cleanMessage(dynamic error) {
    if (error == null) return 'Error desconocido';
    try {
      if (error is ApiException) return error.message;
      final resp = error.response;
      if (resp != null && resp.data is Map) {
        final d = resp.data as Map;
        final msg = d['message'] ?? d['error'] ?? d['mensaje'];
        if (msg != null && msg.toString().isNotEmpty) return msg.toString();
      }
      if (resp != null && resp.data is String) {
        return resp.data.toString();
      }
    } catch (_) {}
    final s = error.toString();
    return s
        .replaceAll(RegExp(r'^Exception:\s*'), '')
        .replaceAll(RegExp(r'^HttpException:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^SocketException:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^FormatException:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^TypeError:\s*', caseSensitive: false), '')
        .trim();
  }
}
