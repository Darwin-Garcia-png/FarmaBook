import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AlertasController extends ChangeNotifier {
  final Dio _dio = ApiService.dio;

  List<dynamic> alertsStock = [];
  List<dynamic> alertsVencimiento = [];
  List<dynamic> notifications = [];
  bool isLoading = true;
  String? error;

  Future<void> init() async {
    await cargarAlertas();
  }

  Future<void> cargarAlertas() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await ApiService.setAuthHeader();

      final results = await Future.wait([
        _dio.get('/inventory/alerts/stock'),
        _dio.get('/inventory/alerts/expiry'),
        _dio.get('/notifications'),
        _dio.get('/inventory/products?limit=1000'),
      ]);

      alertsStock = results[0].data['data'] ?? [];
      alertsVencimiento = results[1].data['data'] ?? [];
      notifications = results[2].data['data'] ?? [];

      final allProds = results[3].data['data'] as List? ?? [];
      final criticalLocal = allProds.where((p) {
        final stock = p['cantidadDisponible'] as num? ?? 0;
        return stock <= 5;
      }).toList();

      for (var p in criticalLocal) {
        if (!alertsStock.any((a) => a['productoId'] == p['productoId'])) {
          alertsStock.add(p);
        }
      }
    } catch (e) {
      debugPrint("Error loading alerts: $e");
      error = "Error al conectar con el servidor";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
