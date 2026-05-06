import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/producto_model.dart';

enum VentasView { search, history, receipts }

class VentasController extends ChangeNotifier {
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  List<Producto> productosEncontrados = [];
  final Map<String, Producto> cacheProductos = {};
  final Map<String, int> carrito = {};
  final Map<String, String> presentacionMap = {}; // ID -> Nombre
  
  List<dynamic> ventasHistorial = [];
  Map<String, dynamic>? ultimaVenta;
  VentasView vistaActual = VentasView.search;
  
  bool isLoading = false;
  bool isLoadingHistorial = false;
  String? mensaje;
  String? error;

  void setVista(VentasView vista) {
    vistaActual = vista;
    if (vista == VentasView.history || vista == VentasView.receipts) {
      cargarHistorialVentas();
    }
    notifyListeners();
  }

  Future<void> cargarHistorialVentas() async {
    isLoadingHistorial = true;
    notifyListeners();
    try {
      ventasHistorial = await ApiService.getSales();
      await cargarPresentaciones();
    } catch (e) {
      error = 'Error al cargar historial: $e';
    } finally {
      isLoadingHistorial = false;
      notifyListeners();
    }
  }

  Future<void> cargarPresentaciones() async {
    try {
      final List<dynamic> pList = await ApiService.getPresentations();
      for (var p in pList) {
        presentacionMap[p['presentacionId'].toString()] = p['nombre'].toString();
      }
    } catch (e) {
      debugPrint('Error al cargar presentaciones: $e');
    }
  }

  void clearMessage() {
    mensaje = null;
    error = null;
    notifyListeners();
  }

  Future<void> buscarPorCodigo() async {
    final codigo = barcodeController.text.trim();
    if (codigo.isEmpty) return;

    isLoading = true;
    mensaje = null;
    error = null;
    notifyListeners();

    try {
      final prodData = await ApiService.getProductByIdentifier(codigo);
      if (prodData != null) {
        final producto = Producto.fromJson(prodData);
        cacheProductos[producto.productoId] = producto;
        agregarAlCarrito(producto);
        barcodeController.clear();
      } else {
        error = 'Producto no encontrado por código: $codigo';
      }
    } catch (e) {
      error = 'Error al buscar producto: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> buscarPorNombre() async {
    final nombre = searchController.text.trim();
    if (nombre.isEmpty) return;

    isLoading = true;
    mensaje = null;
    error = null;
    productosEncontrados = [];
    notifyListeners();

    try {
      final results = await ApiService.searchProducts(nombre);
      productosEncontrados = results.map((json) => Producto.fromJson(json)).toList();
      for (var p in productosEncontrados) {
        cacheProductos[p.productoId] = p;
      }
      if (productosEncontrados.isEmpty) {
        error = 'No se encontraron productos con: $nombre';
      }
    } catch (e) {
      error = 'Error al buscar por nombre: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void agregarAlCarrito(Producto producto) {
    final id = producto.productoId;
    if (producto.cantidadDisponible <= (carrito[id] ?? 0)) {
       // We can return a specific error or use a callback to show snackbar
       // For now, let's just use the error string
       error = 'Stock insuficiente para ${producto.nombre}';
       notifyListeners();
       return;
    }
    carrito[id] = (carrito[id] ?? 0) + 1;
    cacheProductos[id] = producto;
    notifyListeners();
  }

  void quitarDeCarrito(String id) {
    if (carrito.containsKey(id)) {
      if (carrito[id]! > 1) {
        carrito[id] = carrito[id]! - 1;
      } else {
        carrito.remove(id);
      }
      notifyListeners();
    }
  }

  void eliminarDelCarrito(String id) {
    carrito.remove(id);
    notifyListeners();
  }

  void vaciarCarrito() {
    carrito.clear();
    notifyListeners();
  }

  double get total {
    double total = 0;
    carrito.forEach((id, qty) {
      final prod = cacheProductos[id];
      if (prod != null) {
        total += prod.precioPorUnidad * qty;
      }
    });
    return total;
  }

  Future<Map<String, dynamic>?> registrarVenta() async {
    if (carrito.isEmpty) {
      error = 'El carrito está vacío';
      notifyListeners();
      return null;
    }

    isLoading = true;
    mensaje = null;
    error = null;
    notifyListeners();
    try {
      final List<Map<String, dynamic>> saleData = [];
      carrito.forEach((id, qty) {
        final prod = cacheProductos[id];
        if (prod != null) {
          saleData.add({
            "codigoProducto": prod.codigoBarras ?? prod.productoId,
            "cantidad": qty,
          });
        }
      });

      final result = await ApiService.registerSale(saleData);
      
      // EXTREME ROBUSTNESS: Construct a full sale object even if backend returns minimal data
      final responseData = result['data'] as Map<String, dynamic>? ?? {};
      
      // We need a local backup of details because sometimes backend doesn't return them on POST
      final List<Map<String, dynamic>> localDetalles = saleData.map((item) {
        Producto? prod;
        try {
          prod = cacheProductos.values.firstWhere((p) => (p.codigoBarras == item['codigoProducto'] || p.productoId == item['codigoProducto']));
        } catch (_) {}
        
        final presName = (prod != null) ? (presentacionMap[prod.presentacionId] ?? '') : '';
        return {
          'productoId': prod?.productoId ?? 'N/A',
          'nombre': prod?.nombre ?? 'Producto',
          'presentacion': presName.isNotEmpty ? presName : null,
          'cantidadDeUnidades': item['cantidad'],
          'subTotal': (prod?.precioPorUnidad ?? 0) * item['cantidad'],
        };
      }).toList();

      ultimaVenta = {
        'ventaId': responseData['ventaId'] ?? responseData['id'] ?? 'N/A',
        'total': responseData['total'] ?? total,
        'fechaDeVenta': responseData['fechaDeVenta'] ?? responseData['fecha'] ?? responseData['createdAt'] ?? DateTime.now().toIso8601String(),
        'productosVendidos': (responseData['productosVendidos'] != null && (responseData['productosVendidos'] as List).isNotEmpty) 
            ? responseData['productosVendidos'] 
            : (responseData['detalles'] != null && (responseData['detalles'] as List).isNotEmpty)
                ? responseData['detalles']
                : localDetalles,
      };

      carrito.clear();
      mensaje = '¡Venta registrada correctamente! Total: \$${result['data']['total']}';
      productosEncontrados = [];
      notifyListeners();
      return result;
    } catch (e) {
      error = 'Error al registrar venta: $e';
      notifyListeners();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    barcodeController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
