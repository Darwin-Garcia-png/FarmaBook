import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class AlmacenController extends ChangeNotifier {
  final Dio _dio = ApiService.dio;
  Timer? _autoClearTimer;

  List<Map<String, dynamic>> productos = [];
  List<dynamic> categorias = [];
  List<dynamic> presentaciones = [];
  List<dynamic> proveedores = [];

  bool isLoadingInitial = false;
  bool isFetchingMore = false;
  bool hasMore = true;
  int currentPage = 1;

  bool showLowStockOnly = false;
  String? categoriaSeleccionada;
  String? error;

  final TextEditingController searchCtrl = TextEditingController();

  @override
  void dispose() {
    _autoClearTimer?.cancel();
    searchCtrl.dispose();
    super.dispose();
  }

  void search() {
    fetchProducts(isRefresh: true);
  }

  Future<void> init() async {
    // Carga de catálogos una sola vez
    if (categorias.isEmpty) fetchCategorias();
    if (presentaciones.isEmpty) fetchPresentaciones();
    if (proveedores.isEmpty) fetchProveedores();
    await fetchProducts(isRefresh: true);
  }

  Future<void> fetchCategorias() async {
    try {
      categorias = await ApiService.getCategories();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchPresentaciones() async {
    try {
      presentaciones = await ApiService.getPresentations();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchProveedores() async {
    try {
      proveedores = await ApiService.getSuppliers();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> fetchProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      isLoadingInitial = true;
      currentPage = 1;
      hasMore = true;
      productos.clear();
      error = null;
      notifyListeners();
    } else {
      if (!hasMore || isFetchingMore) return;
      isFetchingMore = true;
      notifyListeners();
    }

    try {
      List<dynamic> rawData;
      
      final query = searchCtrl.text.trim();
      if (query.isNotEmpty) {
        // La API de búsqueda podría no estar paginada estrictamente, pero la usaremos.
        // Si hay búsqueda ignoramos low stock filter del lado del server y lo hacemos local
        rawData = await ApiService.searchProducts(query);
        // Deshabilitar paginación extra en búsqueda simple
        hasMore = false; 
      } else {
        Map<String, dynamic> extraParams = {};
        if (categoriaSeleccionada != null) {
          extraParams['categoriaId'] = categoriaSeleccionada;
        }
        // Note: Si el backend no soporta "bajo_stock" directo, podríamos tener que filtrarlo localmente.
        // Asumiendo que no lo soporta en query, lo filtramos en Dart.
        
        rawData = await ApiService.getProductos(page: currentPage, limit: 20, extraParams: extraParams);
        if (rawData.length < 20) {
          hasMore = false;
        } else {
          currentPage++;
        }
      }

      final mapped = rawData.cast<Map<String, dynamic>>().map((p) {
        p['lotes'] ??= [];
        return p;
      }).toList();

      if (query.isNotEmpty && showLowStockOnly) {
         productos = mapped.where((p) => (p['cantidadDisponible'] as num? ?? 0) < 30).toList();
      } else if (showLowStockOnly) {
         // Filtro local estricto si el API no tiene ?bajo_stock=true
         final filtrados = mapped.where((p) => (p['cantidadDisponible'] as num? ?? 0) < 30).toList();
         productos.addAll(filtrados);
      } else {
         productos.addAll(mapped);
      }
      
    } catch (e) {
      error = "Error al cargar productos: $e";
    } finally {
      isLoadingInitial = false;
      isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<Response> saveProduct(
      {required bool isEdit,
      required String? productId,
      required Map<String, dynamic> data}) async {
    await ApiService.setAuthHeader();
    if (isEdit) {
      return await _dio.patch('/inventory/products/$productId', data: data);
    } else {
      return await _dio.post('/inventory/products', data: data);
    }
  }

  Future<void> deleteProduct(String productId) async {
    await ApiService.deleteProduct(productId);
    await fetchProducts(isRefresh: true);
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
    productos.clear();
    categorias.clear();
    presentaciones.clear();
    proveedores.clear();
    currentPage = 1;
    notifyListeners();
  }

  void toggleLowStockFilter() {
    showLowStockOnly = !showLowStockOnly;
    fetchProducts(isRefresh: true);
  }

  void updateCategoriaSeleccionada(String? v) {
    categoriaSeleccionada = v;
    fetchProducts(isRefresh: true);
  }
}
