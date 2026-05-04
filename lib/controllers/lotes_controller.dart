import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../utils/global_error_handler.dart';

class LotesController extends ChangeNotifier {
  final _dio = ApiService.dio;

  List<Map<String, dynamic>> allBatches = [];
  bool isLoading = false;
  
  // Categorization
  List<Map<String, dynamic>> get vencidos => allBatches.where((b) {
    final d = DateTime.tryParse(b['fechaDeVencimiento'] ?? b['fechaVencimiento'] ?? '');
    return d != null && d.isBefore(DateTime.now());
  }).toList();
  
  List<Map<String, dynamic>> get porVencer => allBatches.where((b) {
    final d = DateTime.tryParse(b['fechaDeVencimiento'] ?? b['fechaVencimiento'] ?? '');
    return d != null && d.isAfter(DateTime.now()) && d.isBefore(DateTime.now().add(const Duration(days: 60)));
  }).toList();
  
  List<Map<String, dynamic>> get bajoStock => allBatches.where((b) {
    final stock = int.tryParse(b['cantidadDisponible'].toString()) ?? 0;
    return stock > 0 && stock < 30;
  }).toList();
  
  List<Map<String, dynamic>> get saludables => allBatches.where((b) {
    final d = DateTime.tryParse(b['fechaDeVencimiento'] ?? b['fechaVencimiento'] ?? '');
    final stock = int.tryParse(b['cantidadDisponible'].toString()) ?? 0;
    final isNotExpiredOrNear = d == null || d.isAfter(DateTime.now().add(const Duration(days: 60)));
    return isNotExpiredOrNear && stock >= 30;
  }).toList();
  
  List<Map<String, dynamic>> get agotados => allBatches.where((b) {
    final stock = int.tryParse(b['cantidadDisponible'].toString()) ?? 0;
    return stock <= 0;
  }).toList();

  String? error;
  String externalSearchQuery = '';

  void setExternalSearch(String query) {
    externalSearchQuery = query;
    notifyListeners();
  }

  void clearExternalSearch() {
    externalSearchQuery = '';
    notifyListeners();
  }

  Future<void> init() async {
    await fetchAllBatches();
  }

  Future<void> fetchAllBatches() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await ApiService.setAuthHeader();

      // Peticiones paralelas para máxima velocidad
      final results = await Future.wait([
        _dio.get('/inventory/products?page=1&limit=10000'),
        _dio.get('/inventory/batches'),
      ]);

      final productsList = results[0].data['data'] as List? ?? [];
      final batchesList = results[1].data['data'] as List? ?? [];

      // Mapeo O(1) de productos
      final productMap = {
        for (var p in productsList) p['productoId'].toString(): p
      };

      allBatches = batchesList.map((b) {
        final pId = b['productoId']?.toString();
        final p = productMap[pId] ?? {};
        return {
          ...Map<String, dynamic>.from(b),
          'productoNombre': p['nombre'] ?? 'Producto Desconocido',
          'productoCodigo': p['codigoBarras'] ?? 'N/A',
          'originalProduct': p,
        };
      }).toList();
      
      // Ordenar por defecto por fecha de vencimiento más cercana
      allBatches.sort((a, b) {
        final dateA = DateTime.tryParse(a['fechaDeVencimiento'] ?? a['fechaVencimiento'] ?? '9999-12-31');
        final dateB = DateTime.tryParse(b['fechaDeVencimiento'] ?? b['fechaVencimiento'] ?? '9999-12-31');
        return dateA?.compareTo(dateB ?? DateTime(9999)) ?? 0;
      });

    } catch (e) {
      error = "Error al cargar lotes";
      GlobalErrorHandler.showError('No se pudieron cargar los lotes. Verifica tu conexión.');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Response> createBatch(Map<String, dynamic> data) async {
    await ApiService.setAuthHeader();
    try {
      final res = await _dio.post('/inventory/batches', data: data);
      await fetchAllBatches();
      return res;
    } catch (e) {
      GlobalErrorHandler.showError('No se pudo crear el lote.');
      rethrow;
    }
  }

  Future<Response> updateBatch(String id, Map<String, dynamic> data) async {
    await ApiService.setAuthHeader();
    try {
      final res = await _dio.patch('/inventory/batches/$id', data: data);
      await fetchAllBatches();
      return res;
    } catch (e) {
      GlobalErrorHandler.showError('No se pudo actualizar el lote.');
      rethrow;
    }
  }

  Future<void> deleteBatch(String id) async {
    await ApiService.setAuthHeader();
    try {
      await _dio.delete('/inventory/batches/$id');
      await fetchAllBatches();
    } catch (e) {
      GlobalErrorHandler.showError('No se pudo eliminar el lote.');
      rethrow;
    }
  }
}
