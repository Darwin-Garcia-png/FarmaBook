import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_constants.dart';
import '../utils/global_error_handler.dart';

class ApiService {
  static String? _cachedToken;
  static const _storage = FlutterSecureStorage();

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ))..interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) async {
          final statusCode = e.response?.statusCode;
          String msg;
          if (e.response?.data != null) {
            final data = e.response!.data;
            if (data is Map<String, dynamic>) {
              msg = (data['message'] ?? data['error'] ?? data.toString()) as String;
            } else {
              msg = data.toString();
            }
          } else {
            msg = e.message ?? 'Ha ocurrido un problema de red inusual.';
          }

          if (_cachedToken != null) {
            GlobalErrorHandler.showError(msg, statusCode: statusCode);
          }

          return handler.next(e);
        },
      ),
    );

  static Dio get dio => _dio;

  static Future<void> init() async {
    _cachedToken = await _storage.read(key: AppConstants.tokenKey);
  }

  static Future<String?> getToken() async {
    return _cachedToken ?? await _storage.read(key: AppConstants.tokenKey);
  }

  static Future<void> setAuthHeader() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  static void clearCachedToken() {
    _cachedToken = null;
    _dio.options.headers.remove('Authorization');
  }

  static Future<void> releaseMemory() async {
    _cachedToken = null;
    _dio.options.headers.remove('Authorization');
    try {
      await _storage.delete(key: AppConstants.tokenKey);
    } catch (_) {}
  }

  static Future<void> setToken(String? token) async {
    _cachedToken = token;
    if (token != null && token.isNotEmpty) {
      try {
        await _storage.write(key: AppConstants.tokenKey, value: token);
      } catch (_) {}
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      try {
        await _storage.delete(key: AppConstants.tokenKey);
      } catch (_) {}
      _dio.options.headers.remove('Authorization');
    }
  }

  static Future<List<dynamic>> getProductos({int page = 1, int limit = 20, Map<String, dynamic>? extraParams}) async {
    await setAuthHeader();
    final Map<String, dynamic> query = {
      'page': page,
      'limit': limit,
    };
    if (extraParams != null) query.addAll(extraParams);
    final response = await _dio.get('/inventory/products', queryParameters: query);
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
      final response = await _dio.get('/inventory/search', queryParameters: {
        'query': query.trim(),
      });

      if (response.statusCode == 200) {
        if (response.data is! Map<String, dynamic>) return [];
        final data = response.data as Map<String, dynamic>;
        return data['data'] as List<dynamic>? ?? [];
      }
      return [];
    } catch (e) {
      rethrow;
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
    final response = await _dio.get('/inventory/presentations');
    if (response.statusCode == 200) {
      if (response.data is! Map<String, dynamic>) return [];
      final data = response.data as Map<String, dynamic>;
      return data['data'] as List<dynamic>? ?? [];
    }
    return [];
  }

  static Future<List<dynamic>> getCategories() async {
    await setAuthHeader();
    final response = await _dio.get('/inventory/categories');
    if (response.statusCode == 200) {
      if (response.data is! Map<String, dynamic>) return [];
      final data = response.data as Map<String, dynamic>;
      return data['data'] as List<dynamic>? ?? [];
    }
    return [];
  }

  static Future<List<dynamic>> getSuppliers() async {
    await setAuthHeader();
    final response = await _dio.get('/inventory/suppliers');
    if (response.statusCode == 200) {
      if (response.data is! Map<String, dynamic>) return [];
      final data = response.data as Map<String, dynamic>;
      return data['data'] as List<dynamic>? ?? [];
    }
    return [];
  }

  static Future<List<dynamic>> getBatches({int page = 1, int limit = 100}) async {
    await setAuthHeader();
    final response = await _dio.get('/inventory/batches', queryParameters: {
      'page': page,
      'limit': limit,
    });
    if (response.statusCode == 200) {
      if (response.data is! Map<String, dynamic>) return [];
      final data = response.data as Map<String, dynamic>;
      return data['data'] as List<dynamic>? ?? [];
    }
    return [];
  }

  static Future<List<dynamic>> getSales({int limit = 50}) async {
    await setAuthHeader();
    final response = await _dio.get('/sales', queryParameters: {
      'page': 1,
      'limit': limit,
    });
    if (response.statusCode == 200) {
      if (response.data is! Map<String, dynamic>) return [];
      final data = response.data as Map<String, dynamic>;
      return data['data'] as List<dynamic>? ?? [];
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getSaleById(String id) async {
    await setAuthHeader();
    final response = await _dio.get('/sales/$id');
    if (response.statusCode == 200) {
      if (response.data is! Map<String, dynamic>) return null;
      final data = response.data as Map<String, dynamic>;
      return data['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  static Future<List<dynamic>> getBatchesByProduct(String productId) async {
    await setAuthHeader();
    final response =
        await _dio.get('/inventory/products/$productId/batches');
    if (response.statusCode == 200) {
      if (response.data is! Map<String, dynamic>) return [];
      return response.data['data'] as List<dynamic>? ?? [];
    }
    return [];
  }

  // CLOUDINARY UPLOAD: Send image to Cloudinary and return secure_url
  static Future<String?> uploadImage(dynamic imageFile) async {
    try {
      late MultipartFile mp;
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        mp = MultipartFile.fromBytes(bytes, filename: 'image.png');
      } else {
        mp = await MultipartFile.fromFile(imageFile.path);
      }
      final formData = FormData.fromMap({
        'file': mp,
        'upload_preset': AppConstants.cloudinaryUploadPreset,
      });

      final response = await _dio.post(
        AppConstants.cloudinaryUploadUrl,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['secure_url']?.toString();
      }
    } catch (e) {
      rethrow;
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

  static Future<Map<String, dynamic>> createUser(
      Map<String, dynamic> data) async {
    await setAuthHeader();
    final response = await _dio.post('/users', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateUser(
      String id, Map<String, dynamic> data) async {
    await setAuthHeader();
    final response = await _dio.patch('/users/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<void> deleteUser(String id) async {
    await setAuthHeader();
    await _dio.delete('/users/$id');
  }

  // Analytics
  static Future<Map<String, dynamic>> getRevenueToday() async {
    await setAuthHeader();
    final response = await _dio.get('/analytics/revenues/today');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getRevenueMonth() async {
    await setAuthHeader();
    final response = await _dio.get('/analytics/revenues/month');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getSalesToday() async {
    await setAuthHeader();
    final response = await _dio.get('/analytics/sales/today');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getSalesMonth() async {
    await setAuthHeader();
    final response = await _dio.get('/analytics/sales/month');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getTopProducts() async {
    await setAuthHeader();
    final response = await _dio.get('/analytics/products/top');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getExpenses() async {
    await setAuthHeader();
    final response = await _dio.get('/analytics/expenses');
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getBalance() async {
    await setAuthHeader();
    final response = await _dio.get('/analytics/balance');
    return response.data as Map<String, dynamic>;
  }

  // Notifications
  static Future<List<dynamic>> getNotifications() async {
    await setAuthHeader();
    final response = await _dio.get('/notifications');
    if (response.statusCode == 200) {
      if (response.data is! Map<String, dynamic>) return [];
      return response.data['data'] as List<dynamic>? ?? [];
    }
    return [];
  }

  // Movements
  static Future<List<dynamic>> getMovements() async {
    await setAuthHeader();
    final response = await _dio.get('/movements');
    if (response.statusCode == 200) {
      if (response.data is! Map<String, dynamic>) return [];
      return response.data['data'] as List<dynamic>? ?? [];
    }
    return [];
  }

  // CRUD Products
  static Future<Map<String, dynamic>> createProduct(
      Map<String, dynamic> data) async {
    await setAuthHeader();
    final response = await _dio.post('/inventory/products', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateProduct(
      String id, Map<String, dynamic> data) async {
    await setAuthHeader();
    final response = await _dio.patch('/inventory/products/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<void> deleteProduct(String id) async {
    await setAuthHeader();
    await _dio.delete('/inventory/products/$id');
  }

  // CRUD Categories
  static Future<Map<String, dynamic>> createCategory(
      Map<String, dynamic> data) async {
    await setAuthHeader();
    final response = await _dio.post('/inventory/categories', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateCategory(
      String id, Map<String, dynamic> data) async {
    await setAuthHeader();
    final response =
        await _dio.patch('/inventory/categories/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<void> deleteCategory(String id) async {
    await setAuthHeader();
    await _dio.delete('/inventory/categories/$id');
  }

  static Future<bool> categoryExists(String name) async {
    await setAuthHeader();
    final response = await _dio.get('/inventory/categories/exists',
        queryParameters: {'name': name});
    return response.data['data'] == true;
  }

  // CRUD Presentations
  static Future<Map<String, dynamic>> createPresentation(
      Map<String, dynamic> data) async {
    await setAuthHeader();
    final response =
        await _dio.post('/inventory/presentations', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updatePresentation(
      String id, Map<String, dynamic> data) async {
    await setAuthHeader();
    final response =
        await _dio.patch('/inventory/presentations/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<void> deletePresentation(String id) async {
    await setAuthHeader();
    await _dio.delete('/inventory/presentations/$id');
  }

  static Future<bool> presentationExists(String name) async {
    await setAuthHeader();
    final response = await _dio.get('/inventory/presentations/exists',
        queryParameters: {'name': name});
    return response.data['data'] == true;
  }

  // CRUD Suppliers
  static Future<Map<String, dynamic>> createSupplier(
      Map<String, dynamic> data) async {
    await setAuthHeader();
    final response = await _dio.post('/inventory/suppliers', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateSupplier(
      String id, Map<String, dynamic> data) async {
    await setAuthHeader();
    final response =
        await _dio.patch('/inventory/suppliers/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<void> deleteSupplier(String id) async {
    await setAuthHeader();
    await _dio.delete('/inventory/suppliers/$id');
  }

  static Future<bool> supplierExistsByName(String name) async {
    await setAuthHeader();
    final response = await _dio.get('/inventory/suppliers/exists',
        queryParameters: {'name': name});
    return response.data['data'] == true;
  }

  static Future<bool> supplierExistsByEmail(String email) async {
    await setAuthHeader();
    final response = await _dio.get('/inventory/suppliers/exists',
        queryParameters: {'email': email});
    return response.data['data'] == true;
  }

  // CRUD Houses
  static Future<List<dynamic>> getHouses() async {
    await setAuthHeader();
    final response = await _dio.get('/inventory/houses');
    if (response.statusCode == 200) {
      if (response.data is! Map<String, dynamic>) return [];
      final data = response.data as Map<String, dynamic>;
      return data['data'] as List<dynamic>? ?? [];
    }
    return [];
  }

  static Future<Map<String, dynamic>> createHouse(
      Map<String, dynamic> data) async {
    await setAuthHeader();
    final response = await _dio.post('/inventory/houses', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateHouse(
      String id, Map<String, dynamic> data) async {
    await setAuthHeader();
    final response = await _dio.patch('/inventory/houses/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<void> deleteHouse(String id) async {
    await setAuthHeader();
    await _dio.delete('/inventory/houses/$id');
  }

  static Future<bool> houseExists(String name) async {
    await setAuthHeader();
    final response = await _dio.get('/inventory/houses/exists',
        queryParameters: {'name': name});
    return response.data['data'] == true;
  }

  // CRUD Batches
  static Future<Map<String, dynamic>> createBatch(
      Map<String, dynamic> data) async {
    await setAuthHeader();
    final response = await _dio.post('/inventory/batches', data: data);
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateBatch(
      String id, Map<String, dynamic> data) async {
    await setAuthHeader();
    final response = await _dio.patch('/inventory/batches/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  // PRODUCTS - Suppliers
  static Future<List<dynamic>> getProductSuppliers(String productId) async {
    await setAuthHeader();
    final response =
        await _dio.get('/inventory/products/$productId/suppliers');
    if (response.statusCode == 200) {
      if (response.data is! Map<String, dynamic>) return [];
      return response.data['data'] as List<dynamic>? ?? [];
    }
    return [];
  }

  static Future<Map<String, dynamic>> addSupplierToProduct(
      String productId, String supplierId) async {
    await setAuthHeader();
    final response = await _dio.post('/inventory/products/$productId/suppliers',
        data: {'proveedorId': supplierId});
    return response.data as Map<String, dynamic>;
  }

  static Future<void> removeSupplierFromProduct(
      String productId, String supplierId) async {
    await setAuthHeader();
    await _dio.delete('/inventory/products/$productId/suppliers/$supplierId');
  }

  // GET BY IDENTIFIER
  static Future<Map<String, dynamic>?> getCategoryByIdentifier(
      String identifier) async {
    await setAuthHeader();
    try {
      final response = await _dio.get('/inventory/categories/$identifier');
      if (response.statusCode == 200) {
        return (response.data as Map<String, dynamic>)['data']
            as Map<String, dynamic>?;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getPresentationByIdentifier(
      String identifier) async {
    await setAuthHeader();
    try {
      final response =
          await _dio.get('/inventory/presentations/$identifier');
      if (response.statusCode == 200) {
        return (response.data as Map<String, dynamic>)['data']
            as Map<String, dynamic>?;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getSupplierByIdentifier(
      String identifier) async {
    await setAuthHeader();
    try {
      final response = await _dio.get('/inventory/suppliers/$identifier');
      if (response.statusCode == 200) {
        return (response.data as Map<String, dynamic>)['data']
            as Map<String, dynamic>?;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getBatchById(String batchId) async {
    await setAuthHeader();
    try {
      final response = await _dio.get('/inventory/batches/$batchId');
      if (response.statusCode == 200) {
        return (response.data as Map<String, dynamic>)['data']
            as Map<String, dynamic>?;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
    return null;
  }

  // INVENTORY ALL
  static Future<Map<String, dynamic>> getInventoryAll() async {
    await setAuthHeader();
    final response = await _dio.get('/inventory/all');
    return response.data as Map<String, dynamic>;
  }

  // USERS
  static Future<Map<String, dynamic>?> getUserByName(String nombre) async {
    await setAuthHeader();
    try {
      final response = await _dio.get('/users/$nombre');
      if (response.statusCode == 200) {
        return (response.data as Map<String, dynamic>)['data']
            as Map<String, dynamic>?;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
    return null;
  }

  // ANALYTICS REPORT
  static Future<List<int>> getAnalyticsReportPdf() async {
    await setAuthHeader();
    final response = await _dio.get('/analytics/report',
        options: Options(responseType: ResponseType.bytes));
    return response.data as List<int>;
  }

  // SALES - With optional consumer name
  static Future<Map<String, dynamic>> registerSale({
    required List<Map<String, dynamic>> saleData,
    String? clienteId,
  }) async {
    await setAuthHeader();
    final body = <String, dynamic>{
      'saleData': saleData,
      'clienteId': clienteId ?? '0000000000',
    };
    final response = await _dio.post('/sales', data: body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data as Map<String, dynamic>;
    }
    throw Exception(
        'Error ${response.statusCode}: ${response.data['message'] ?? 'Error al registrar venta'}');
  }
}
