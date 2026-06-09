import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class NotificacionesController extends ChangeNotifier {
  final Dio _dio = ApiService.dio;

  int unreadCount = 0;
  List<Map<String, dynamic>> notificaciones = [];

  void clearData() {
    notificaciones.clear();
    unreadCount = 0;
    notifyListeners();
  }

  void init() {
    fetchAlerts();
  }

  Future<void> fetchAlerts() async {
    try {
      await ApiService.setAuthHeader();
      final res = await Future.wait([
        _dio.get('/inventory/products', queryParameters: {'page': 1, 'limit': 100}),
        _dio.get('/inventory/batches', queryParameters: {'page': 1, 'limit': 100}),
      ]);

      final rawProds = res[0].data['data'] as List? ?? [];
      final rawBatches = res[1].data['data'] as List? ?? [];

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
            'mensaje': 'Stock bajo: ${p['nombre']} ($stock)',
          });
        }
      }

      notificaciones = nuevasNotifs;
      unreadCount = notificaciones.length;
      notifyListeners();
    } catch (e) {
      // Error silencioso en background
    }
  }

  void markAllAsRead() {
    unreadCount = 0;
    notifyListeners();
  }
}
