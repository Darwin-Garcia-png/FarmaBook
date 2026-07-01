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
        final body = error.serverBody;
        if (body != null) {
          final msg = body['message'];
          if (msg is List && msg.isNotEmpty) {
            return _translateValidationErrors(msg.cast<String>());
          }
        }
        return _cleanMessage(error.message);
      }
      final resp = error.response;
      if (resp != null && resp.data is Map) {
        final d = resp.data as Map;
        final msg = d['message'] ?? d['error'] ?? d['mensaje'];
        if (msg != null && msg.toString().isNotEmpty) {
          if (msg is List && msg.isNotEmpty) {
            return _translateValidationErrors(msg.cast<String>());
          }
          return _cleanMessage(msg.toString());
        }
      }
      if (resp != null && resp.data is String) {
        return _cleanMessage(resp.data.toString());
      }
      if (resp != null && resp.data is Map) {
        final d = resp.data as Map;
        final errors = d['errors'];
        if (errors is List && errors.isNotEmpty) {
          final first = errors.first;
          if (first is Map) {
            final m = first['message'] ?? first['msg'] ?? first.toString();
            return _cleanMessage(m.toString());
          }
          return _cleanMessage(errors.first.toString());
        }
      }
    } catch (_) {
      return 'Error de conexión. Verifique el servidor.';
    }
    return _cleanMessage(error.toString());
  }

  static String _translateValidationErrors(List<String> msgs) {
    final translated = msgs.map((m) => _translateSingleError(m)).toList();
    return translated.join('\n');
  }

  static String _translateSingleError(String msg) {
    msg = msg.trim();

    final r = RegExp(r'^(\w+)\s+(must\s+be\s+(a\s+|an\s+|)|is required|should not be empty|must not be empty)', caseSensitive: false);
    final m = r.firstMatch(msg);
    if (m != null) {
      final field = _fieldName(m.group(1)!);
      return '$field es obligatorio';
    }

    final mustMatch = RegExp(r'^(\w+)\s+must\s+be\s+(a\s+|an\s+|)(.+)$', caseSensitive: false);
    final m2 = mustMatch.firstMatch(msg);
    if (m2 != null) {
      final field = _fieldName(m2.group(1)!);
      final constraint = m2.group(3)!;
      if (constraint.contains('date') || constraint.contains('Date')) return '$field: fecha inválida';
      if (constraint.contains('number') || constraint.contains('integer')) return '$field: número inválido';
      if (constraint.contains('email')) return '$field: correo inválido';
      if (constraint.contains('positive')) return '$field debe ser positivo';
      if (constraint.contains('string')) return '$field: texto inválido';
      return '$field: formato inválido';
    }

    final lenMatch = RegExp(r'^(\w+)\s+must be longer than or equal to (\d+) characters', caseSensitive: false);
    final lm = lenMatch.firstMatch(msg);
    if (lm != null) {
      return '${_fieldName(lm.group(1)!)} debe tener al menos ${lm.group(2)} caracteres';
    }

    // Pattern 4: "is not allowed", "cannot be", "does not exist", "already exists", "is invalid"
    final validationMatch = RegExp(r'^(\w+)\s+(?:is\s+not\s+allowed|cannot\s+be\s+\w+|does\s+not\s+exist|already\s+exists|is\s+invalid)', caseSensitive: false);
    final vm = validationMatch.firstMatch(msg);
    if (vm != null) {
      final field = _fieldName(vm.group(1)!);
      if (msg.contains('not allowed')) return '$field: valor no permitido';
      if (msg.contains('cannot be')) return '$field: valor no válido';
      if (msg.contains('does not exist')) return '$field: no existe';
      if (msg.contains('already exists')) return '$field: ya existe';
      if (msg.contains('is invalid')) return '$field: inválido';
      return '$field: error de validación';
    }

    return msg;
  }

  static String _fieldName(String field) {
    switch (field.toLowerCase()) {
      case 'nombre': return 'Nombre';
      case 'email': return 'Correo electrónico';
      case 'telefono': case 'teléfono': case 'phone': return 'Teléfono';
      case 'direccion': case 'dirección': case 'address': return 'Dirección';
      case 'codigobarras': case 'codigodebarras': return 'Código de barras';
      case 'precio': case 'precioporunidad': case 'precioventa': return 'Precio';
      case 'fechadevencimiento': case 'fechavencimiento': return 'Fecha de vencimiento';
      case 'cantidaddisponible': case 'stock': case 'cantidad': return 'Stock';
      case 'preciocompra': case 'costocompra': case 'costodecompra': return 'Costo de compra';
      case 'categoriaid': case 'categoria': return 'Categoría';
      case 'presentacionid': case 'presentacion': return 'Presentación';
      case 'proveedorid': case 'proveedor': return 'Proveedor';
      case 'casasid': case 'casa': return 'Casa farmacéutica';
      case 'nombredelote': case 'nombrelote': return 'Nombre del lote';
      case 'descripcion': return 'Descripción';
      case 'concentracion': return 'Concentración';
      case 'nombregenerico': return 'Nombre genérico';
      default: return field;
    }
  }

  static final _errorCodeReg = RegExp(r'^Error\s+\d{3}:\s*', caseSensitive: false);
  static final _errorCodeOnlyReg = RegExp(r'^Error\s+\d{3}\s*$', caseSensitive: false);

  static String _cleanMessage(String s) {
    if (_errorCodeOnlyReg.hasMatch(s)) {
      final code = int.tryParse(RegExp(r'\d{3}').firstMatch(s)?.group(0) ?? '');
      if (code != null) return _statusMessage(code);
    }

    final isTechnical = s.contains('TypeError') ||
        s.contains('FormatException') ||
        s.contains('NoSuchMethodError') ||
        s.contains('Null check operator') ||
        s.contains('RangeError') ||
        s.contains('subtype of') ||
        s.contains('is not a') ||
        s.contains('null') ||
        s.contains('undefined') ||
        s.contains('dynamic') ||
        s.contains('Unexpected character') ||
        s.contains('JSON') ||
        s.contains('json');

    if (isTechnical) {
      return 'Falla de datos: Formato incompatible. Intente recargar.';
    }

    s = s
        .replaceAll(RegExp(r'^Exception:\s*'), '')
        .replaceAll(RegExp(r'^HttpException:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^SocketException:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^FormatException:\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'^TypeError:\s*', caseSensitive: false), '')
        .replaceAll(_errorCodeReg, '')
        .trim();

    if (s.isEmpty) return 'Falla de procesamiento. Intente nuevamente.';

    final trans = _translateSingleError(s);
    if (trans != s) return trans;

    final containsCode = RegExp(r'[{}[\]()<>:;=_]|instance of', caseSensitive: false).hasMatch(s);
    if (containsCode) {
      return 'Error de procesamiento: Falló la petición interna.';
    }

    return s;
  }

  static String _statusMessage(int code) {
    if (code >= 500) return 'Error de servidor: Fallo interno. Intente más tarde.';
    if (code == 404) return 'Recurso no encontrado: La dirección no existe.';
    if (code == 403) return 'Acceso denegado: No tiene permisos suficientes.';
    if (code == 401) return 'Acceso denegado: Sesión expirada o credenciales incorrectas.';
    if (code == 409) return 'Conflicto de datos: El registro ya está en uso.';
    if (code == 422) return 'Datos incorrectos: Información inválida enviada.';
    if (code == 400) return 'Petición inválida: Verifique la información ingresada.';
    return 'Error de red: Respuesta inesperada del servidor.';
  }
}
