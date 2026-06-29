import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InicioController extends ChangeNotifier {
  Timer? _autoClearTimer;

  double ingresos = 0;
  double egresos = 0;
  double balance = 0;

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

    try {

      try {
        final res = await Future.wait([
          ApiService.getRevenueMonth(),
          ApiService.getExpenses(),
          ApiService.getBalance(),
          ApiService.getSales(limit: 100),
          ApiService.getTopProducts(),
        ]).timeout(const Duration(seconds: 15));

        ingresos = double.tryParse((res[0] as Map)['data']?['ingresosMensuales']?.toString() ?? '0') ?? 0;
        egresos = double.tryParse((res[1] as Map)['data']?['egresosMensuales']?.toString() ?? '0') ?? 0;
        balance = double.tryParse((res[2] as Map)['data']?['balanceMensual']?.toString() ?? '0') ?? 0;

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

        final allSales = res[3] as List? ?? [];
        recentSales = allSales.take(10).toList();

        topProducts = (res[4] as Map)['data'] as List? ?? [];
      } catch (e) {
        debugPrint('Error en analíticas: $e');
      }

      try {
        final res = await Future.wait([
          ApiService.getProductos(page: 1, limit: 100),
          ApiService.getBatches(page: 1, limit: 999999),
        ]).timeout(const Duration(seconds: 15));

        final rawProds = res[0] as List? ?? [];
        final rawBatches = res[1] as List? ?? [];

        final now = DateTime.now();
        final threshold = now.add(const Duration(days: 60));
        alertsVencimiento = rawBatches.where((b) {
          if (b['fechaDeVencimiento'] == null) return false;
          final exp = DateTime.tryParse(b['fechaDeVencimiento'].toString());
          return exp != null && exp.isBefore(threshold);
        }).toList();

        alertsStock = rawProds.where((p) {
          final stock = (p['cantidadDisponible'] as num? ?? 0).toInt();
          return stock > 0 && stock < 30;
        }).toList();

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
      error = 'Error al cargar datos del inicio';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
