import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class AlmacenController extends ChangeNotifier {
  final Dio _dio = ApiService.dio;
  Timer? _refreshTimer;
  Timer? _debounceTimer;

  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> _allFetchedProducts = [];

  List<dynamic> categorias = [];
  List<dynamic> presentaciones = [];
  List<dynamic> proveedores = [];

  bool isLoadingInitial = false;
  bool showLowStockOnly = false;
  String? categoriaSeleccionada;
  String? error;
  String _lastSearchQuery = '';

  final TextEditingController searchCtrl = TextEditingController();

  AlmacenController() {
    searchCtrl.addListener(_onSearchChanged);
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
       if (!isLoadingInitial) {
         fetchProducts(isRefresh: false);
       }
    });
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (searchCtrl.text != _lastSearchQuery) {
        _applyLocalFilters();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _debounceTimer?.cancel();
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> init() async {
    fetchCategorias();
    fetchPresentaciones();
    fetchProveedores();
    await fetchProducts(isRefresh: true);
  }

  Future<void> fetchCategorias() async {
    try {
      await ApiService.setAuthHeader();
      final res = await _dio.get('/inventory/categories');
      categorias = _deDuplicate(res.data['data'] ?? [], 'categoriaId');
    } catch (_) {
      try {
        categorias = _deDuplicate(await ApiService.getPresentations(), 'id');
      } catch (_) {}
    }
    notifyListeners();
  }

  List<dynamic> _deDuplicate(List list, String idKey) {
    if (list.isEmpty) return [];
    final seen = <String>{};
    final List result = [];
    for (var i in list) {
      final id = (i[idKey] ?? i['id'] ?? i['proveedorId'] ?? '').toString();
      if (!seen.contains(id)) {
        seen.add(id);
        result.add(i);
      }
    }
    return result;
  }

  Future<void> fetchPresentaciones() async {
    try {
      await ApiService.setAuthHeader();
      presentaciones =
          _deDuplicate(await ApiService.getPresentations(), 'presentacionId');
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchProveedores() async {
    try {
      await ApiService.setAuthHeader();
      final res = await _dio.get('/inventory/suppliers');
      final List data = res.data['data'] ?? [];
      proveedores = _deDuplicate(data, 'proveedorId').map((e) {
        final m = Map<String, dynamic>.from(e);
        m['proveedorId'] ??= m['id'];
        m['nombre'] ??=
            m['nombreProveedor'] ?? m['razonSocial'] ?? 'Sin nombre';
        return m;
      }).toList();
    } catch (_) {
      try {
        final res = await _dio.get('/inventory/proveedores');
        final List data = res.data['data'] ?? [];
        proveedores = _deDuplicate(data, 'proveedorId').map((e) {
          final m = Map<String, dynamic>.from(e);
          m['proveedorId'] ??= m['id'];
          m['nombre'] ??=
              m['nombreProveedor'] ?? m['razonSocial'] ?? 'Sin nombre';
          return m;
        }).toList();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> fetchProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      isLoadingInitial = true;
      error = null;
      notifyListeners();
    }

    try {
      await ApiService.setAuthHeader();
      final List rawData = await ApiService.getProductos();

      _allFetchedProducts = rawData.whereType<Map<String, dynamic>>().map((p) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(p);
        m['lotes'] ??= [];
        return m;
      }).toList();

      _applyLocalFilters();
      _backgroundHydration();
    } catch (e) {
      error = "Error al cargar: $e";
    } finally {
      isLoadingInitial = false;
      notifyListeners();
    }
  }

  void _backgroundHydration() async {
    final products = _allFetchedProducts;
    if (products.isEmpty) return;

    const int chunkSize = 15;
    for (int i = 0; i < products.length; i += chunkSize) {
      final end =
          (i + chunkSize < products.length) ? i + chunkSize : products.length;
      final chunkRange = products.sublist(i, end);

      await Future.wait(chunkRange.map((p) async {
        final id = p['productoId']?.toString();
        if (id == null) return;

        try {
          final batches = await ApiService.getBatchesByProduct(id);
          if (batches.isNotEmpty) {
            p['lotes'] = batches;

            int total = 0;
            for (var b in batches) {
              total += (b['cantidadDisponible'] as num? ?? 0).toInt();
            }
            p['cantidadDisponible'] = total;

            final currentPrice =
                double.tryParse((p['precioPorUnidad'] ?? '0').toString()) ??
                    0.0;
            if (currentPrice == 0) {
              final firstB = batches.first;
              final bPrice =
                  double.tryParse(firstB['precioPorUnidad']?.toString() ?? '0') ?? 0.0;
              if (bPrice > 0) p['precioPorUnidad'] = bPrice;
            }
          }
        } catch (_) {}
      }));

      _applyLocalFilters();
    }
  }

  void _applyLocalFilters() {
    List<Map<String, dynamic>> filtered = _allFetchedProducts;

    final query = searchCtrl.text.toLowerCase().trim();
    _lastSearchQuery = searchCtrl.text;

    if (query.isNotEmpty) {
      filtered = filtered.where((p) {
        final nom = (p['nombre'] ?? '').toString().toLowerCase();
        final cod = (p['codigoBarras'] ?? '').toString().toLowerCase();
        return nom.contains(query) || cod.contains(query);
      }).toList();
    }

    if (categoriaSeleccionada != null) {
      filtered = filtered
          .where((p) => p['categoriaId']?.toString() == categoriaSeleccionada)
          .toList();
    }

    if (showLowStockOnly) {
      filtered = filtered
          .where((p) => (p['cantidadDisponible'] as num? ?? 0) < 30)
          .toList();
    }

    productos = filtered;
    notifyListeners();
  }

  Future<Response> saveProduct(
      {required bool isEdit,
      required String? productId,
      required Map<String, dynamic> data}) async {
    if (isEdit) {
      return await _dio.patch('/inventory/products/$productId', data: data);
    } else {
      return await _dio.post('/inventory/products', data: data);
    }
  }

  Future<void> deleteProduct(String productId) async {
    await _dio.delete('/inventory/products/$productId');
    await fetchProducts(isRefresh: true);
  }

  void toggleLowStockFilter() {
    showLowStockOnly = !showLowStockOnly;
    _applyLocalFilters();
  }

  void updateCategoriaSeleccionada(String? v) {
    categoriaSeleccionada = v;
    _applyLocalFilters();
  }
}
