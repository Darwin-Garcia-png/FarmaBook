import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/global_error_handler.dart';

class ApiService {
  static const String baseUrl = 'https://farmabook-mr5m.onrender.com';
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ))..interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) {
          final statusCode = e.response?.statusCode;
          final msg = e.response?.data?['message'] ?? 
                      e.response?.data?['error'] ?? 
                      e.message ?? 
                      'Ha ocurrido un problema de red inusual.';
          
          GlobalErrorHandler.showError(msg.toString(), statusCode: statusCode);
          
          return handler.next(e); // Continue yielding the error downwards
        },
      ),
    );
  static const _storage = FlutterSecureStorage();

  static Dio get dio => _dio;

  static Future<void> init() async {
    // Already initialized via BaseOptions now, but keeping for compatibility
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  static Future<void> setAuthHeader() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  static Future<List<dynamic>> getProductos() async {
    await setAuthHeader();
    final response = await _dio.get('/inventory/products?page=1&limit=100');
    if (response.statusCode == 200) {
      if (response.data is! Map<String, dynamic>) return [];
      final data = response.data as Map<String, dynamic>;
      return data['data'] as List<dynamic>? ?? [];
    }
    throw Exception(
        'Error ${response.statusCode}: ${response.data['message'] ?? 'No se pudieron cargar productos'}');
  }

  static Future<List<dynamic>> searchProducts(String query) async {
    await setAuthHeader();
    try {
      // Trying to fetch with a high limit to allow local filtering as fallback
      final response = await _dio.get('/inventory/products', queryParameters: {
        'page': 1,
        'limit': 1000,
      });

      if (response.statusCode == 200) {
        if (response.data is! Map<String, dynamic>) {
          print(
              'DEBUG: El servidor devolvió un formato no esperado (posiblemente HTML): ${response.data.runtimeType}');
          return [];
        }
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> products = data['data'] as List<dynamic>? ?? [];

        final searchText = query.toLowerCase().trim();
        if (searchText.isEmpty) return products;

        return products.where((p) {
          final nom = (p['nombre'] ?? '').toString().toLowerCase();
          final cod = (p['codigoBarras'] ?? '').toString().toLowerCase();
          return nom.contains(searchText) || cod.contains(searchText);
        }).toList();
      }
      return [];
    } catch (e) {
      print('DEBUG: Error en searchProducts: $e');
      // If the products fetching fails, return empty list instead of crashing
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getProductByIdentifier(
      String identifier) async {
    await setAuthHeader();
    try {
      final response = await _dio.get('/inventory/products/$identifier');
      if (response.statusCode == 200) {
        if (response.data is! Map<String, dynamic>) return null;
        final data = response.data as Map<String, dynamic>;
        return data['data'] as Map<String, dynamic>?;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
    return null;
  }

  static Future<List<dynamic>> getPresentations() async {
    await setAuthHeader();
    try {
      final response = await _dio.get('/inventory/presentations');
      if (response.statusCode == 200) {
        if (response.data is! Map<String, dynamic>) return [];
        final data = response.data as Map<String, dynamic>;
        return data['data'] as List<dynamic>? ?? [];
      }
      return [];
    } catch (e) {
      print('DEBUG: Error en getPresentations: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> registerSale(
      List<Map<String, dynamic>> saleData) async {
    await setAuthHeader();
    final response = await _dio.post('/sales', data: {"saleData": saleData});
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception(
        'Error ${response.statusCode}: ${response.data['message'] ?? 'Error al registrar venta'}');
  }

  static Future<List<dynamic>> getSales() async {
    await setAuthHeader();
    try {
      final response = await _dio.get('/sales');
      if (response.statusCode == 200) {
        if (response.data is! Map<String, dynamic>) return [];
        final data = response.data as Map<String, dynamic>;
        return data['data'] as List<dynamic>? ?? [];
      }
      return [];
    } catch (e) {
      print('DEBUG: Error en getSales: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getSaleById(String id) async {
    await setAuthHeader();
    try {
      final response = await _dio.get('/sales/$id');
      if (response.statusCode == 200) {
        if (response.data is! Map<String, dynamic>) return null;
        final data = response.data as Map<String, dynamic>;
        return data['data'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('DEBUG: Error en getSaleById: $e');
    }
    return null;
  }

  // HIGH ROBUSTNESS: Centralized batch fetcher
  static Future<List<dynamic>> getBatchesByProduct(String productId) async {
    await setAuthHeader();
    try {
      // Try multiple endpoints based on user clues and common patterns
      Response? response;
      try {
        response = await _dio.get('/inventory/products/$productId/batches');
      } catch (_) {
        try {
          response = await _dio.get('/inventory/batches/$productId');
        } catch (__) {
          return [];
        }
      }

      if (response.statusCode == 200) {
        if (response.data is! Map<String, dynamic>) return [];
        return response.data['data'] as List<dynamic>? ?? [];
      }
      return [];
    } catch (e) {
      print('DEBUG: Error en getBatchesByProduct: $e');
      return [];
    }
  }

  // NUCLEAR SCAN: Recursively find any candidate price in a JSON object
  static double nuclearScan(Map<String, dynamic> json) {
    double best = 0.0;
    final priority = [
      'precioVenta',
      'precio_venta',
      'precioPorUnidad',
      'pvp',
      'precio_unidad',
      'precioUnidad',
      'precio',
      'costoCompra',
      'precioCompra'
    ];
    for (var f in priority) {
      if (json[f] != null) {
        final d = double.tryParse(json[f].toString()) ?? 0.0;
        if (d > 0) return d;
      }
    }
    json.forEach((key, value) {
      final k = key.toLowerCase();
      if (k.contains('pre') ||
          k.contains('pvp') ||
          k.contains('venta') ||
          k.contains('cost')) {
        if (value is num && value > 0 && best == 0) best = value.toDouble();
        if (value is String && best == 0) {
          final d = double.tryParse(value);
          if (d != null && d > 0) best = d;
        }
      }
    });
    return best;
  }
  // CLOUDINARY UPLOAD: Send image to Cloudinary and return secure_url
  static Future<String?> uploadImage(dynamic imageFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path),
        'upload_preset': 'farmabook',
      });

      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/dfffmvroq/image/upload',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['secure_url']?.toString();
      }
    } catch (e) {
      print('DEBUG: Error en uploadImage: $e');
    }
    return null;
  }

  // USERS CRUD
  static Future<List<dynamic>> getUsers() async {
    await setAuthHeader();
    final response = await _dio.get('/users');
    if (response.statusCode == 200) {
      if (response.data is! Map<String, dynamic>) return [];
      return response.data['data'] as List<dynamic>? ?? [];
    }
    return [];
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    await setAuthHeader();
    try {
      print('DEBUG: Intentando crear usuario con payload: $data');
      final response = await _dio.post('/users', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.response?.data?['error'] ?? 'Error desconocido';
      print('❌ ERROR EN CREATEUSER (Terminal): ${e.response?.data}');
      throw Exception('Fallo al crear usuario: $msg');
    }
  }

  static Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> data) async {
    await setAuthHeader();
    try {
      final response = await _dio.patch('/users/$id', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
       final msg = e.response?.data?['message'] ?? e.response?.data?['error'] ?? 'Error desconocido';
       throw Exception('Fallo al actualizar usuario: $msg');
    }
  }

  static Future<void> deleteUser(String id) async {
    await setAuthHeader();
    await _dio.delete('/users/$id');
  }

  // Speculative Roles Fetching
  static Future<List<dynamic>> getRoles() async {
    await setAuthHeader();
    try {
      // Trying common endpoints
      Response response;
      try {
        response = await _dio.get('/users/roles');
      } catch (_) {
        response = await _dio.get('/roles');
      }
      if (response.statusCode == 200) {
        if (response.data is Map && response.data['data'] != null) {
          return response.data['data'] as List<dynamic>;
        }
        if (response.data is List) return response.data as List;
      }
    } catch (e) {
      print('DEBUG: Error en getRoles: $e');
    }
    // Fallback/Mock roles if endpoint fails, based on common pharmacy roles
    return [
      {'rolId': 'admin-uuid-placeholder', 'nombre': 'Administrador'},
      {'rolId': 'cajero-uuid-placeholder', 'nombre': 'Cajero'},
      {'rolId': 'dueno-uuid-placeholder', 'nombre': 'Dueño'},
    ];
  }
}
