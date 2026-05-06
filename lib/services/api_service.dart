import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_constants.dart';
import '../utils/global_error_handler.dart';

class ApiService {
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
        onError: (DioException e, handler) {
          final statusCode = e.response?.statusCode;
          final msg = e.response?.data?['message'] ??
              e.response?.data?['error'] ??
              e.message ??
              'Ha ocurrido un problema de red inusual.';

          GlobalErrorHandler.showError(msg.toString(), statusCode: statusCode);

          return handler.next(e);
        },
      ),
    );
  static const _storage = FlutterSecureStorage();

  static Dio get dio => _dio;

  static Future<void> init() async {}

  static Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
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
    final response =
        await _dio.get('/inventory/products', queryParameters: {
          'page': 1,
          'limit': AppConstants.maxPageLimit,
        });
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

  static Future<List<dynamic>> getBatches() async {
    await setAuthHeader();
    final response = await _dio.get('/inventory/batches');
    if (response.statusCode == 200) {
      if (response.data is! Map<String, dynamic>) return [];
      final data = response.data as Map<String, dynamic>;
      return data['data'] as List<dynamic>? ?? [];
    }
    return [];
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
    final response = await _dio.get('/sales');
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
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path),
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
}
