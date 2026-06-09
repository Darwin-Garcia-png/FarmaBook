import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InicioController extends ChangeNotifier {
  final Dio _dio = ApiService.dio;
  Timer? _autoClearTimer;

  double ingresos = 0;
  double egresos = 0;
  double balance = 0;
  
  // Porcentajes para anillos radiales (0.0 a 1.0)
  double marginPercent = 0.0; 
  double expensePercent = 0.0; 
  double stockHealthPercent = 0.0; 

  List<dynamic> topProducts = [];
  List<dynamic> alertsVencimiento = [];
  List<dynamic> alertsStock = [];
  List<dynamic> recentSales = [];
  
  bool isLoading = true;
  String? error;

  @override
  void dispose() {
    _autoClearTimer?.cancel();
    super.dispose();
  }

  void touch() {
    _autoClearTimer?.cancel();
    _autoClearTimer = null;
  }

  void scheduleAutoClear() {
    _autoClearTimer?.cancel();
    _autoClearTimer = Timer(const Duration(minutes: 5), () {
      clearData();
    });
  }

  void clearData() {
    topProducts.clear();
    alertsVencimiento.clear();
    alertsStock.clear();
    recentSales.clear();
    ingresos = 0;
    egresos = 0;
    balance = 0;
    marginPercent = 0;
    expensePercent = 0;
    stockHealthPercent = 0;
    notifyListeners();
  }

  Future<void> init() async {
    await cargarDatos();
  }

  Future<void> cargarDatos() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await ApiService.setAuthHeader();

      // 1. Datos Financieros y Ventas en Paralelo
      try {
        final res = await Future.wait([
          _dio.get('/analytics/revenues/month'),
          _dio.get('/analytics/expenses'),
          _dio.get('/analytics/balance'),
          _dio.get('/sales'),
          _dio.get('/analytics/products/top', queryParameters: {'limit': 5, 'period': 'month'}),
        ]);
        
        ingresos = double.tryParse(res[0].data['data']?['ingresosMensuales']?.toString() ?? '0') ?? 0;
        egresos = double.tryParse(res[1].data['data']?['egresosMensuales']?.toString() ?? '0') ?? 0;
        balance = double.tryParse(res[2].data['data']?['balanceMensual']?.toString() ?? '0') ?? 0;
        
        // Calcular Porcentajes (Margen y Ratio de Gasto)
        if (ingresos > 0) {
          marginPercent = (ingresos - egresos) / ingresos;
          if (marginPercent < 0) marginPercent = 0;
          if (marginPercent > 1) marginPercent = 1;
          
          expensePercent = egresos / ingresos;
          if (expensePercent > 1) expensePercent = 1;
        } else {
          marginPercent = 0;
          expensePercent = 0;
        }

        final allSales = res[3].data['data'] as List? ?? [];
        // Ordenar por fecha si es posible y tomar las últimas
        recentSales = allSales.take(10).toList();
        
        topProducts = res[4].data['data'] as List? ?? [];
      } catch (e) {
        debugPrint('Error en analíticas: $e');
      }

      // 2. Salud de Inventario y Alertas
      try {
        final res = await Future.wait([
          _dio.get('/inventory/products', queryParameters: {'page': 1, 'limit': 100}),
          _dio.get('/inventory/batches'),
        ]);
        
        final rawProds = res[0].data['data'] as List? ?? [];
        final rawBatches = res[1].data['data'] as List? ?? [];

        // Vencimientos (Próximos 60 días)
        final now = DateTime.now();
        final threshold = now.add(const Duration(days: 60));
        alertsVencimiento = rawBatches.where((b) {
          if (b['fechaDeVencimiento'] == null) return false;
          final exp = DateTime.tryParse(b['fechaDeVencimiento'].toString());
          return exp != null && exp.isBefore(threshold);
        }).toList();

        // Stock Bajo - usar datos de productos directamente SIN fetch individual
        alertsStock = rawProds.where((p) {
          final stock = (p['cantidadDisponible'] as num? ?? 0).toInt();
          return stock > 0 && stock < 30;
        }).toList();

        // Salud de Stock (Ratio de productos saludables)
        final healthyCount = rawProds.where((p) {
          return (p['cantidadDisponible'] as num? ?? 0).toInt() >= 30;
        }).length;
        if (rawProds.isNotEmpty) {
           stockHealthPercent = healthyCount / rawProds.length;
           if (stockHealthPercent > 1) stockHealthPercent = 1;
        }

      } catch (e) {
        debugPrint('Error en inventario: $e');
      }

    } catch (e) {
      error = 'Error inesperado: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
