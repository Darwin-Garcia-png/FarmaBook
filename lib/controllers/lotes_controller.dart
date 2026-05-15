import 'dart:async'; // Añadido para Timer
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../utils/global_error_handler.dart';

class LotesController extends ChangeNotifier {
  final _dio = ApiService.dio;
  Timer? _refreshTimer;

  List<Map<String, dynamic>> allBatches = [];
  bool isLoading = false;

  List<Map<String, dynamic>> _vencidos = [];
  List<Map<String, dynamic>> _porVencer = [];
  List<Map<String, dynamic>> _bajoStock = [];
  List<Map<String, dynamic>> _saludables = [];
  List<Map<String, dynamic>> _agotados = [];
  List<Map<String, dynamic>> _archivedBatches = [];
  List<Map<String, dynamic>> _activeBatches = [];

  List<Map<String, dynamic>> get vencidos => _vencidos;
  List<Map<String, dynamic>> get porVencer => _porVencer;
  List<Map<String, dynamic>> get bajoStock => _bajoStock;
  List<Map<String, dynamic>> get saludables => _saludables;
  List<Map<String, dynamic>> get agotados => _agotados;
  List<Map<String, dynamic>> get archivedBatches => _archivedBatches;
  List<Map<String, dynamic>> get activeBatches => _activeBatches;

  LotesController() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 120), (timer) {
      if (!isLoading) fetchAllBatches();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _recomputeCategories() {
    final now = DateTime.now();
    final sixtyDays = now.add(const Duration(days: 60));
    _vencidos = [];
    _porVencer = [];
    _bajoStock = [];
    _saludables = [];
    _agotados = [];
    _archivedBatches = [];
    _activeBatches = [];
    for (final b in allBatches) {
      final d = DateTime.tryParse(b['fechaDeVencimiento'] ?? b['fechaVencimiento'] ?? '');
      final stock = int.tryParse(b['cantidadDisponible'].toString()) ?? 0;
      final isExpired = d != null && d.isBefore(now);
      final hasNoProduct = (b['originalProduct'] as Map?)?.isEmpty ?? true;
      // Archived = agotado OR expired OR product deleted
      if (stock <= 0 || isExpired || hasNoProduct) {
        _archivedBatches.add(b);
        if (stock <= 0) _agotados.add(b);
        if (isExpired) _vencidos.add(b);
        continue;
      }
      _activeBatches.add(b);
      if (d != null && d.isBefore(sixtyDays)) {
        _porVencer.add(b);
      }
      if (stock > 0 && stock < 30) {
        _bajoStock.add(b);
      }
      if ((d == null || d.isAfter(sixtyDays)) && stock >= 30) {
        _saludables.add(b);
      }
    }
  }

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

      _recomputeCategories();

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
    } catch (_) {
      // Fallback: si DELETE no existe en backend, se asigna stock 0 via PATCH
      try {
        await _dio.patch('/inventory/batches/$id', data: {'cantidadDisponible': 0});
        await fetchAllBatches();
      } catch (_) {
        GlobalErrorHandler.showError('No se pudo eliminar el lote. El backend no soporta borrado.');
      }
    }
  }
}
