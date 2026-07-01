import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class AlmacenController extends ChangeNotifier {
  List<Map<String, dynamic>> productos = [];
  List<dynamic> categorias = [];
  List<dynamic> presentaciones = [];
  List<dynamic> proveedores = [];
  List<dynamic> casas = [];

  bool isLoadingInitial = false;
  bool isFetchingMore = false;
  bool hasMore = true;
  int currentPage = 1;

  bool showLowStockOnly = false;
  String? categoriaSeleccionada;
  String? casaSeleccionada;
  String? proveedorSeleccionada;
  String? presentacionSeleccionada;
  String? error;

  final TextEditingController searchCtrl = TextEditingController();

  void search() {
    fetchProducts(isRefresh: true);
  }

  Future<void> init() async {
    await refreshCatalogos();
    await fetchProducts(isRefresh: true);
  }

  /// Always fetches fresh catalog data from the API.
  Future<void> refreshCatalogos() async {
    await Future.wait([
      fetchCategorias(),
      fetchPresentaciones(),
      fetchProveedores(),
      fetchCasas(),
    ]);
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

  Future<void> fetchCasas() async {
    try {
      casas = await ApiService.getHouses();
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
        rawData = await ApiService.searchProducts(query);
        // If text search returned nothing, try barcode lookup
        if (rawData.isEmpty) {
          final prodData = await ApiService.getProductByIdentifier(query);
          if (prodData != null) rawData = [prodData];
        }
        hasMore = false; 
      } else {
        Map<String, dynamic> extraParams = {};
        if (categoriaSeleccionada != null) {
          extraParams['categoriaId'] = categoriaSeleccionada;
        }
        if (casaSeleccionada != null) {
          extraParams['casaId'] = casaSeleccionada;
        }
        if (proveedorSeleccionada != null) {
          extraParams['proveedorId'] = proveedorSeleccionada;
        }
        if (presentacionSeleccionada != null) {
          extraParams['presentacionId'] = presentacionSeleccionada;
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
      // Si es error de red y es la carga inicial, reintentamos una vez después de 2 segundos
      final isNetworkError = e is SocketException || e is HttpException || e is TimeoutException;
      if (isNetworkError && isRefresh) {
        isLoadingInitial = false;
        isFetchingMore = false;
        notifyListeners();
        await Future.delayed(const Duration(seconds: 2));
        // Solo reintentamos si no se ha cancelado (el widget sigue vivo)
        if (!_disposed) {
          await fetchProducts(isRefresh: true);
          return;
        }
      } else {
        error = 'Sin conexión. Verifique su red e intente de nuevo.';
      }
    } finally {
      isLoadingInitial = false;
      isFetchingMore = false;
      notifyListeners();
    }
  }

  bool _disposed = false;

  Future<Map<String, dynamic>> saveProduct({
    required bool isEdit,
    required String? productId,
    required Map<String, dynamic> data,
    XFile? image,
  }) async {
    if (isEdit && productId != null) {
      return await ApiService.updateProductMultipart(productId, data, imageFile: image);
    }
    return await ApiService.createProductMultipart(data, imageFile: image);
  }

  Future<void> deleteProduct(String productId) async {
    await ApiService.deleteProduct(productId);
    await fetchProducts(isRefresh: true);
  }

  List<Map<String, dynamic>> deletedProducts = [];
  bool isLoadingDeleted = false;

  Future<void> fetchDeletedProducts() async {
    isLoadingDeleted = true;
    notifyListeners();
    try {
      final raw = await ApiService.getDeletedProducts();
      deletedProducts = raw.cast<Map<String, dynamic>>().toList();
    } catch (_) {
      deletedProducts = [];
    } finally {
      isLoadingDeleted = false;
      notifyListeners();
    }
  }

  Future<void> restoreProduct(String productId) async {
    await ApiService.restoreProduct(productId);
    deletedProducts.removeWhere((p) =>
        p['productoId'] == productId || p['id'] == productId);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    searchCtrl.dispose();
    super.dispose();
  }

  void touch() {
    // Sin efecto — se mantiene para compatibilidad con llamadas existentes
  }

  void clearData() {
    productos.clear();
    categorias.clear();
    presentaciones.clear();
    proveedores.clear();
    casas.clear();
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

  void updateCasaSeleccionada(String? v) {
    casaSeleccionada = v;
    fetchProducts(isRefresh: true);
  }

  void updateProveedorSeleccionada(String? v) {
    proveedorSeleccionada = v;
    fetchProducts(isRefresh: true);
  }

  void updatePresentacionSeleccionada(String? v) {
    presentacionSeleccionada = v;
    fetchProducts(isRefresh: true);
  }
}
