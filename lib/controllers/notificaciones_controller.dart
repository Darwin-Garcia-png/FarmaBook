import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificacionesController extends ChangeNotifier {
  int unreadCount = 0;
  List<Map<String, dynamic>> notificaciones = [];
  Timer? _timer;
  int _previousCount = 0;
  int _toastShownCount = 0;

  /// Returns a message to show as a toast if new notifications appeared
  /// since the last time we checked.
  String? get toastMessage {
    if (unreadCount > 0 && unreadCount > _toastShownCount) {
      return notificaciones.isNotEmpty ? notificaciones.first['mensaje'] as String : null;
    }
    return null;
  }

  void clearData() {
    notificaciones.clear();
    unreadCount = 0;
    _previousCount = 0;
    _toastShownCount = 0;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void init() {
    fetchAlerts();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchAlerts());
  }

  Future<void> fetchAlerts() async {
    try {
      final res = await Future.wait([
        ApiService.getProductos(page: 1, limit: 100),
        ApiService.getBatches(page: 1, limit: 999999),
      ]);

      final rawProds = res[0] as List? ?? [];
      final rawBatches = res[1] as List? ?? [];

      List<Map<String, dynamic>> nuevasNotifs = [];

      final now = DateTime.now();
      final threshold = now.add(const Duration(days: 30));
      for (var b in rawBatches) {
        if (b['fechaDeVencimiento'] == null && b['fechaVencimiento'] == null) continue;
        final exp = DateTime.tryParse(b['fechaDeVencimiento']?.toString() ?? b['fechaVencimiento']?.toString() ?? '');
        final stock = int.tryParse(b['cantidadDisponible']?.toString() ?? '0') ?? 0;
        
        if (exp != null && exp.isBefore(threshold) && stock > 0) {
          nuevasNotifs.add({
            'id': b['loteId'] ?? b['id'],
            'tipo': 'vencimiento',
            'mensaje': 'Lote próximo a vencer: ${b['nombreLote']}',
          });
        }
      }

      for (var p in rawProds) {
        final stock = int.tryParse(p['cantidadDisponible']?.toString() ?? '0') ?? 0;
        if (stock > 0 && stock < 30) {
          nuevasNotifs.add({
            'id': p['productoId'] ?? p['id'],
            'tipo': 'stock_bajo',
            'mensaje': 'Stock bajo: ${p['nombre']} ($stock uds)',
          });
        }
      }

      notificaciones = nuevasNotifs;
      _previousCount = unreadCount;
      unreadCount = notificaciones.length;
      notifyListeners();
    } catch (_) {}
  }

  void markToastShown() {
    _toastShownCount = unreadCount;
  }

  void markAllAsRead() {
    unreadCount = 0;
    _toastShownCount = 0;
    _previousCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
