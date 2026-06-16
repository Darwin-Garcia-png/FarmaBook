import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shows a styled error box with message and contextual hint.
class ErrorDisplay {
  ErrorDisplay._();

  /// Builds a full-screen error state with icon, message, hint and retry button.
  static Widget fullScreen({
    required String message,
    String? hint,
    VoidCallback? onRetry,
    IconData icon = Icons.cloud_off_rounded,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            _buildIcon(icon),
            const SizedBox(height: 24),
            _buildBox(message, hint),
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar', style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.ayanamiBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds an inline error banner for use inside Column/ListView.
  static Widget inline({
    required String message,
    String? hint,
    IconData icon = Icons.warning_amber_rounded,
    VoidCallback? onDismiss,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.reiOrangeRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.reiOrangeRed.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.reiOrangeRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.reiOrangeRed)),
                if (hint != null) ...[
                  const SizedBox(height: 4),
                  Text(hint, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade400),
            ),
        ],
      ),
    );
  }

  /// Shows an error dialog with optional hint.
  static Future<void> dialog({
    required BuildContext context,
    required String message,
    String? hint,
    String title = 'Error',
    IconData icon = Icons.error_outline_rounded,
  }) {
    return showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        title: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          decoration: BoxDecoration(
            color: AppTheme.reiOrangeRed.withValues(alpha: 0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.reiOrangeRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.reiOrangeRed, size: 22),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.reiOrangeRed.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.reiOrangeRed.withValues(alpha: 0.08)),
              ),
              child: Text(message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.4)),
            ),
            if (hint != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(hint,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic, height: 1.4)),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ENTENDIDO', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  /// Shows a SnackBar styled as error with hint.
  static void snackBar({
    required BuildContext context,
    required String message,
    String? hint,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: AppTheme.reiOrangeRed,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
            ]),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(hint,
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85), fontStyle: FontStyle.italic)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Shows a success SnackBar.
  static void successSnackBar({
    required BuildContext context,
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        backgroundColor: AppTheme.greenMetal,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(children: [
          const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
        ]),
      ),
    );
  }

  static Widget _buildIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.reiOrangeRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Icon(icon, size: 64, color: AppTheme.reiOrangeRed.withValues(alpha: 0.5)),
    );
  }

  static Widget _buildBox(String message, String? hint) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.reiOrangeRed.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.reiOrangeRed.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.reiOrangeRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.error_outline_rounded, color: AppTheme.reiOrangeRed, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('ERROR',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.reiOrangeRed, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4)),
          if (hint != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(hint,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic, height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Returns a common hint based on the error message text.
  static String? hintFromMessage(String message) {
    final m = message.toLowerCase();
    if (m.contains('connection refused') || m.contains('socket') || m.contains('Host unreachable')) {
      return 'El servidor no está disponible. Verifica que el backend esté encendido.';
    }
    if (m.contains('timeout') || m.contains('timed out')) {
      return 'La solicitud tardó demasiado. Revisa tu conexión a internet.';
    }
    if (m.contains('401') || m.contains('unauthorized') || m.contains('token')) {
      return 'Tu sesión expiró. Inicia sesión nuevamente.';
    }
    if (m.contains('403') || m.contains('forbidden')) {
      return 'No tienes permisos para realizar esta acción.';
    }
    if (m.contains('404') || m.contains('not found')) {
      return 'El recurso solicitado no existe. Puede haber sido eliminado.';
    }
    if (m.contains('409') || m.contains('already exists') || m.contains('ya existe')) {
      return 'El nombre o email ya está registrado. Usa otros diferentes.';
    }
    if (m.contains('validation') || m.contains('validación')) {
      return 'Revisa que todos los campos tengan valores válidos.';
    }
    if (m.contains('connection') || m.contains('network') || m.contains('internet')) {
      return 'Revisa tu conexión a internet y vuelve a intentar.';
    }
    return null;
  }
}
