import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../utils/global_error_handler.dart';

class LotesController extends ChangeNotifier {
  final _dio = ApiService.dio;
  Timer? _autoClearTimer;

  List<Map<String, dynamic>> allBatches = [];
  bool isLoading = false;
  
  bool isFetchingMore = false;
  bool hasMore = true;
  int currentPage = 1;

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
      
      // Archived = agotado OR expired
      if (stock <= 0 || isExpired) {
        _archivedBatches.add(b);
        if (stock <= 0) _agotados.add(b);
        if (isExpired) _vencidos.add(b);
        continue;
      }
      _activeBatches.add(b);
      if (d != null && d.isBefore(sixtyDays)) {
        _porVencer.add(b);
      }
      if (stock < 30) {
        _bajoStock.add(b);
      }
    }
  }

  String? error;
  String externalSearchQuery = '';

  @override
  void dispose() {
    _autoClearTimer?.cancel();
    super.dispose();
  }

  void setExternalSearch(String query) {
    externalSearchQuery = query;
    notifyListeners();
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
    allBatches.clear();
    currentPage = 1;
    notifyListeners();
  }

  void clearExternalSearch() {
    externalSearchQuery = '';
    notifyListeners();
  }

  Future<void> init() async {
    await fetchAllBatches(isRefresh: true);
  }

  Future<void> fetchAllBatches({bool isRefresh = false}) async {
    if (isRefresh) {
      isLoading = true;
      currentPage = 1;
      hasMore = true;
      allBatches.clear();
      error = null;
      notifyListeners();
    } else {
      if (!hasMore || isFetchingMore) return;
      isFetchingMore = true;
      notifyListeners();
    }

    try {
      final batchesList = await ApiService.getBatches(page: currentPage, limit: 100);
      
      if (batchesList.length < 100) {
        hasMore = false;
      } else {
        currentPage++;
      }

      final newBatches = batchesList.cast<Map<String, dynamic>>().toList();
      
      allBatches.addAll(newBatches);

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
      isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<Response> createBatch(Map<String, dynamic> data) async {
    await ApiService.setAuthHeader();
    try {
      final res = await ApiService.createBatch(data);
      await fetchAllBatches(isRefresh: true);
      // El helper devuelve map, lo casteamos a Response para mantener compatibilidad si es necesario
      return Response(requestOptions: RequestOptions(), data: res, statusCode: 200);
    } catch (e) {
      GlobalErrorHandler.showError('No se pudo crear el lote.');
      rethrow;
    }
  }

  Future<Response> updateBatch(String id, Map<String, dynamic> data) async {
    await ApiService.setAuthHeader();
    try {
      final res = await ApiService.updateBatch(id, data);
      await fetchAllBatches(isRefresh: true);
      return Response(requestOptions: RequestOptions(), data: res, statusCode: 200);
    } catch (e) {
      GlobalErrorHandler.showError('No se pudo actualizar el lote.');
      rethrow;
    }
  }

  Future<void> deleteBatch(String id) async {
    await ApiService.setAuthHeader();
    try {
      await _dio.delete('/inventory/batches/$id');
      await fetchAllBatches(isRefresh: true);
    } catch (_) {
      // Fallback: si DELETE no existe en backend, se asigna stock 0 via PATCH
      try {
        await ApiService.updateBatch(id, {'cantidadDisponible': 0});
        await fetchAllBatches(isRefresh: true);
      } catch (_) {
        GlobalErrorHandler.showError('No se pudo eliminar el lote. El backend no soporta borrado.');
      }
    }
  }
}
