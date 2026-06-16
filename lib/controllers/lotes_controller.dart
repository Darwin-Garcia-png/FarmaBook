import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/global_error_handler.dart';

class LotesController extends ChangeNotifier {
  Timer? _autoClearTimer;
  bool _autoInitDone = false;

  List<Map<String, dynamic>> allBatches = [];
  bool isLoading = false;
  
  bool isFetchingMore = false;
  bool hasMore = true;
  int currentPage = 1;

  String? filterProductoId;
  DateTime? filterVencidosDesde;
  DateTime? filterVencidosHasta;
  bool filtersActive = false;

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

  void applyFilters({String? productoId, DateTime? vencidosDesde, DateTime? vencidosHasta}) {
    filterProductoId = productoId;
    filterVencidosDesde = vencidosDesde;
    filterVencidosHasta = vencidosHasta;
    filtersActive = productoId != null || vencidosDesde != null || vencidosHasta != null;
    fetchAllBatches(isRefresh: true);
  }

  void clearFilters() {
    filterProductoId = null;
    filterVencidosDesde = null;
    filterVencidosHasta = null;
    filtersActive = false;
    fetchAllBatches(isRefresh: true);
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
    if (_autoInitDone) return;
    _autoInitDone = true;
    await fetchAllBatches(isRefresh: true);
  }

  /// Public refresh always fetches fresh data
  Future<void> refresh() async {
    await fetchAllBatches(isRefresh: true);
  }

  /// Call from screen to ensure init happens (safe to call multiple times)
  void ensureLoaded() {
    if (!_autoInitDone && !isLoading) {
      _autoInitDone = true;
      fetchAllBatches(isRefresh: true);
    }
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
      return;
    }

    try {
      final batchesList = await ApiService.getBatches(
        page: 1,
        limit: 999999,
        productoId: filterProductoId,
        vencidosAntes: filterVencidosHasta?.toIso8601String().split('T')[0],
        vencidosDespues: filterVencidosDesde?.toIso8601String().split('T')[0],
      );

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

  Future<Map<String, dynamic>> createBatch(Map<String, dynamic> data) async {
    try {
      final res = await ApiService.createBatch(data);
      await fetchAllBatches(isRefresh: true);
      return res;
    } catch (e) {
      GlobalErrorHandler.showError('No se pudo crear el lote.');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateBatch(String id, Map<String, dynamic> data) async {
    try {
      final res = await ApiService.updateBatch(id, data);
      await fetchAllBatches(isRefresh: true);
      return res;
    } catch (e) {
      GlobalErrorHandler.showError('No se pudo actualizar el lote.');
      rethrow;
    }
  }

  Future<void> deleteBatch(String id) async {
    try {
      await ApiService.deleteBatch(id);
      await fetchAllBatches(isRefresh: true);
    } catch (_) {
      try {
        await ApiService.updateBatch(id, {'cantidadDisponible': 0});
        await fetchAllBatches(isRefresh: true);
      } catch (_) {
        GlobalErrorHandler.showError('No se pudo eliminar el lote. El backend no soporta borrado.');
      }
    }
  }
}
