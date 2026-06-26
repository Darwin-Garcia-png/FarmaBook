import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/producto_model.dart';

enum VentasView { search, history, receipts }

class VentasController extends ChangeNotifier {
  Timer? _autoClearTimer;
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController clienteIdController = TextEditingController();
  final TextEditingController clienteIdentificacionController = TextEditingController();

  List<Producto> productosEncontrados = [];
  final Map<String, Producto> cacheProductos = {};
  final Map<String, int> carrito = {};
  final Map<String, String> presentacionMap = {};
  final Map<String, Map<String, dynamic>> _batchCache = {};

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
      ventasHistorial = await ApiService.getSales(limit: 999999);
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

  Future<Map<String, dynamic>?> _enrichWithBatches(Producto producto) async {
    final id = producto.productoId;
    if (_batchCache.containsKey(id)) return _batchCache[id];

    try {
      final batches = await ApiService.getBatchesByProduct(id);
      if (batches.isNotEmpty) {
        int totalStock = 0;
        DateTime? nearestExpiry;
        for (var b in batches) {
          totalStock += (b['cantidadDisponible'] as num? ?? 0).toInt();
          final raw = b['fechaDeVencimiento']?.toString() ??
              b['fechaVencimiento']?.toString();
          if (raw != null) {
            final d = DateTime.tryParse(raw);
            if (d != null) {
              if (nearestExpiry == null || d.isBefore(nearestExpiry)) {
                nearestExpiry = d;
              }
            }
          }
        }

        double price = producto.precioPorUnidad;
        if (price == 0.0) {
          final firstBatch = batches.first;
          for (final f in ['precioPorUnidad', 'costoDeCompra', 'precioVenta', 'precio', 'precioCompra', 'precio_unitario', 'pvp']) {
            final v = firstBatch[f];
            if (v != null) {
              price = double.tryParse(v.toString()) ?? 0.0;
              if (price != 0.0) break;
            }
          }
        }

        final enriched = <String, dynamic>{
          'batches': batches,
          'totalStock': totalStock,
          'price': price,
          'nearestExpiryDate': nearestExpiry,
        };
        _batchCache[id] = enriched;
        return enriched;
      }
    } catch (_) {}
    return null;
  }

  void touch() {
    _autoClearTimer?.cancel();
    _autoClearTimer = null;
    cargarProductosMasVendidos();
  }

  Future<void> cargarProductosMasVendidos() async {
    isLoading = true;
    mensaje = null;
    error = null;
    productosEncontrados = [];
    notifyListeners();

    try {
      List<dynamic> rawList = [];

      try {
        final topResponse = await ApiService.getTopProducts();
        if (topResponse['data'] is List) {
          rawList = topResponse['data'] as List<dynamic>;
        } else if (topResponse['data'] is Map) {
          final map = topResponse['data'] as Map<String, dynamic>;
          if (map['products'] is List) {
            rawList = map['products'] as List<dynamic>;
          }
        } else if (topResponse['products'] is List) {
          rawList = topResponse['products'] as List<dynamic>;
        }
      } catch (_) {}

      if (rawList.isEmpty) {
        rawList = await ApiService.getProductos(limit: 50);
      }

      final List<Producto> hydrated = [];
      for (var json in rawList) {
        var producto = Producto.fromJson(json);
        cacheProductos[producto.productoId] = producto;
        final enriched = await _enrichWithBatches(producto);
        if (enriched != null) {
          producto = _updateProducto(producto, enriched);
          cacheProductos[producto.productoId] = producto;
        }
        hydrated.add(producto);
      }
      productosEncontrados = hydrated;
    } catch (e) {
      error = 'Error al cargar productos: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void scheduleAutoClear() {
    _autoClearTimer?.cancel();
    _autoClearTimer = Timer(const Duration(minutes: 5), () {
      clearData();
    });
  }

  void clearData() {
    productosEncontrados.clear();
    cacheProductos.clear();
    carrito.clear();
    _batchCache.clear();
    notifyListeners();
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
        var producto = Producto.fromJson(prodData);
        cacheProductos[producto.productoId] = producto;

        final enriched = await _enrichWithBatches(producto);
        if (enriched != null) {
          producto = _updateProducto(producto, enriched);
          cacheProductos[producto.productoId] = producto;
        }

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
      final List<Producto> hydrated = [];

      for (var json in results) {
        var producto = Producto.fromJson(json);
        cacheProductos[producto.productoId] = producto;

        final enriched = await _enrichWithBatches(producto);
        if (enriched != null) {
          producto = _updateProducto(producto, enriched);
          cacheProductos[producto.productoId] = producto;
        }
        hydrated.add(producto);
      }

      productosEncontrados = hydrated;
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

  Producto _updateProducto(Producto producto, Map<String, dynamic> enriched) {
    return Producto(
      productoId: producto.productoId,
      codigoBarras: producto.codigoBarras,
      nombre: producto.nombre,
      descripcion: producto.descripcion,
      categoriaId: producto.categoriaId,
      presentacionId: producto.presentacionId,
      proveedoresId: producto.proveedoresId,
      cantidadDisponible: enriched['totalStock'] ?? producto.cantidadDisponible,
      precioPorUnidad: enriched['price'] ?? producto.precioPorUnidad,
      imagenUrl: producto.imagenUrl,
      dosisRecomendada: producto.dosisRecomendada,
      nearestExpiryDate: enriched['nearestExpiryDate'] as DateTime?,
    );
  }

  void agregarAlCarrito(Producto producto) {
    final id = producto.productoId;
    if (producto.cantidadDisponible <= (carrito[id] ?? 0)) {
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

      final clienteNombre = clienteIdController.text.trim();
      final clienteIdentificacion = clienteIdentificacionController.text.trim();
      final result = await ApiService.registerSale(
        saleData: saleData,
        clienteId: clienteIdentificacion.isNotEmpty ? clienteIdentificacion : '0000000000',
      );

      final responseData = result['data'] as Map<String, dynamic>? ?? {};

      final List<Map<String, dynamic>> localDetalles = saleData.map((item) {
        Producto? prod;
        try {
          prod = cacheProductos.values.firstWhere((p) =>
              (p.codigoBarras == item['codigoProducto'] ||
                  p.productoId == item['codigoProducto']));
        } catch (_) {}

        final presName =
            (prod != null) ? (presentacionMap[prod.presentacionId] ?? '') : '';
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
        'numeroFactura': responseData['numeroFactura'],
        'total': responseData['total'] ?? total,
        'fechaDeVenta': responseData['fechaDeVenta'] ??
            responseData['fecha'] ??
            responseData['createdAt'] ??
            DateTime.now().toIso8601String(),
        'productosVendidos':
            (responseData['productosVendidos'] != null &&
                    (responseData['productosVendidos'] as List).isNotEmpty)
                ? responseData['productosVendidos']
                : (responseData['detalles'] != null &&
                        (responseData['detalles'] as List).isNotEmpty)
                    ? responseData['detalles']
                    : localDetalles,
        'clienteNombre': clienteNombre,
        'clienteIdentificacion': clienteIdentificacion,
      };

      carrito.clear();
      clienteIdController.clear();
      clienteIdentificacionController.clear();
      mensaje =
          '¡Venta registrada correctamente! Total: \$${result['data']['total']}';
      productosEncontrados = [];
      cacheProductos.clear();
      _batchCache.clear();
      presentacionMap.clear();
      notifyListeners();
      cargarProductosMasVendidos();
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

  Future<bool> cancelSale(String saleId) async {
    try {
      await ApiService.deleteSale(saleId);
      ventasHistorial.removeWhere((s) => s['ventaId']?.toString() == saleId || s['id']?.toString() == saleId);
      mensaje = 'Venta anulada correctamente';
      notifyListeners();
      return true;
    } catch (e) {
      error = 'Error al anular venta: $e';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _autoClearTimer?.cancel();
    barcodeController.dispose();
    searchController.dispose();
    clienteIdController.dispose();
    clienteIdentificacionController.dispose();
    cacheProductos.clear();
    _batchCache.clear();
    ventasHistorial.clear();
    productosEncontrados.clear();
    carrito.clear();
    presentacionMap.clear();
    super.dispose();
  }
}
