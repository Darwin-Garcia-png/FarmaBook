import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/app_constants.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, dynamic>? serverBody;
  ApiException(this.message, {this.statusCode, this.serverBody});
  @override
  String toString() => message;
}

class ApiService {
  static String? _cachedToken;
  static const _storage = FlutterSecureStorage();
  static http.Client? _client;

  @visibleForTesting
  static set testClient(http.Client? c) => _client = c;

  @visibleForTesting
  static set testCachedToken(String? t) => _cachedToken = t;

  static http.Client get _http {
    if (_client == null) _client = http.Client();
    return _client!;
  }

  static void _disposeClient() {
    _client?.close();
    _client = null;
  }

  static Future<void> init() async {
    _cachedToken = await _storage.read(key: AppConstants.tokenKey);
  }

  static Future<String?> getToken() async {
    return _cachedToken ?? await _storage.read(key: AppConstants.tokenKey);
  }

  static Future<Map<String, String>> _headers({bool auth = true, bool json = false}) async {
    final h = <String, String>{'Accept': 'application/json'};
    if (json) h['Content-Type'] = 'application/json';
    if (auth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        h['Authorization'] = 'Bearer $token';
      }
    }
    return h;
  }

  static Map<String, dynamic> _parseBody(http.Response r) {
    if (r.body.isEmpty) return {};
    try { return jsonDecode(r.body) as Map<String, dynamic>; }
    catch (_) { return {}; }
  }

  static dynamic _parseData(http.Response r) {
    if (r.body.isEmpty) return {};
    try { return jsonDecode(r.body); }
    catch (_) { return r.body; }
  }

  static void checkResponse(http.Response r) {
    if (r.statusCode >= 400) {
      final body = _parseBody(r);
      throw ApiException(
        body['message']?.toString() ?? body['error']?['message']?.toString() ?? 'Error ${r.statusCode}',
        statusCode: r.statusCode,
        serverBody: body,
      );
    }
  }

  static void clearCachedToken() {
    _cachedToken = null;
  }

  static Future<void> releaseMemory() async {
    _cachedToken = null;
    try { await _storage.delete(key: AppConstants.tokenKey); } catch (_) {}
    _disposeClient();
  }

  static Future<void> setToken(String? token) async {
    _cachedToken = token;
    if (token != null && token.isNotEmpty) {
      try { await _storage.write(key: AppConstants.tokenKey, value: token); } catch (_) {}
    } else {
      try { await _storage.delete(key: AppConstants.tokenKey); } catch (_) {}
    }
  }

  static Future<http.Response> _get(String path, {Map<String, String>? query, bool auth = true}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path').replace(queryParameters: query);
    final resp = await _http.get(uri, headers: await _headers(auth: auth)).timeout(AppConstants.connectTimeout!);
    if (resp.statusCode >= 400) {
      final body = _parseBody(resp);
      throw ApiException(
        body['message']?.toString() ?? body['error']?['message']?.toString() ?? 'Error ${resp.statusCode}',
        statusCode: resp.statusCode,
        serverBody: body,
      );
    }
    return resp;
  }

  static Future<http.Response> _post(String path, {Map<String, dynamic>? data, bool auth = true}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final resp = await _http.post(uri, headers: await _headers(auth: auth, json: data != null), body: data != null ? jsonEncode(data) : null).timeout(AppConstants.connectTimeout!);
    if (resp.statusCode >= 400) {
      final body = _parseBody(resp);
      throw ApiException(
        body['message']?.toString() ?? body['error']?['message']?.toString() ?? 'Error ${resp.statusCode}',
        statusCode: resp.statusCode,
        serverBody: body,
      );
    }
    return resp;
  }

  static Future<http.Response> _patch(String path, {Map<String, dynamic>? data, bool auth = true}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final resp = await _http.patch(uri, headers: await _headers(auth: auth, json: data != null), body: data != null ? jsonEncode(data) : null).timeout(AppConstants.connectTimeout!);
    if (resp.statusCode >= 400) {
      final body = _parseBody(resp);
      throw ApiException(
        body['message']?.toString() ?? body['error']?['message']?.toString() ?? 'Error ${resp.statusCode}',
        statusCode: resp.statusCode,
        serverBody: body,
      );
    }
    return resp;
  }

  static Future<http.Response> _delete(String path, {bool auth = true}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final resp = await _http.delete(uri, headers: await _headers(auth: auth)).timeout(AppConstants.connectTimeout!);
    if (resp.statusCode >= 400) {
      final body = _parseBody(resp);
      throw ApiException(
        body['message']?.toString() ?? body['error']?['message']?.toString() ?? 'Error ${resp.statusCode}',
        statusCode: resp.statusCode,
        serverBody: body,
      );
    }
    return resp;
  }

  static String _mimeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      case 'bmp': return 'image/bmp';
      default: return 'image/jpeg';
    }
  }

  static Future<http.Response> _postMultipart(String path, {required Map<String, dynamic> fields, List<MapEntry<String, String>>? filePaths, bool auth = true}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final request = http.MultipartRequest('POST', uri);
    final h = await _headers(auth: auth);
    request.headers.addAll(h);
    final encodedData = jsonEncode(fields);
    debugPrint('[_postMultipart] $path — fields keys: ${fields.keys.join(", ")}');
    debugPrint('[_postMultipart] JSON: $encodedData');
    request.fields['data'] = encodedData;
    if (filePaths != null) {
      for (final entry in filePaths) {
        final file = File(entry.value);
        final bytes = await file.readAsBytes();
        final ext = entry.value.split('.').last.toLowerCase();
        final mime = _mimeFromPath(entry.value);
        request.files.add(http.MultipartFile.fromBytes(entry.key, bytes, filename: 'image.$ext', contentType: MediaType.parse(mime)));
      }
    }
    final streamed = await request.send().timeout(AppConstants.connectTimeout!);
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 400) {
      final body = _parseBody(resp);
      throw ApiException(
        body['message']?.toString() ?? body['error']?['message']?.toString() ?? 'Error ${resp.statusCode}',
        statusCode: resp.statusCode,
        serverBody: body,
      );
    }
    return resp;
  }

  static Future<http.Response> _patchMultipart(String path, {required Map<String, dynamic> fields, List<MapEntry<String, String>>? filePaths, bool auth = true}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final request = http.MultipartRequest('PATCH', uri);
    final h = await _headers(auth: auth);
    request.headers.addAll(h);
    final encodedData = jsonEncode(fields);
    debugPrint('[_patchMultipart] $path — fields keys: ${fields.keys.join(", ")}');
    debugPrint('[_patchMultipart] JSON: $encodedData');
    request.fields['data'] = encodedData;
    if (filePaths != null) {
      for (final entry in filePaths) {
        final file = File(entry.value);
        final bytes = await file.readAsBytes();
        final ext = entry.value.split('.').last.toLowerCase();
        final mime = _mimeFromPath(entry.value);
        request.files.add(http.MultipartFile.fromBytes(entry.key, bytes, filename: 'image.$ext', contentType: MediaType.parse(mime)));
      }
    }
    final streamed = await request.send().timeout(AppConstants.connectTimeout!);
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 400) {
      final body = _parseBody(resp);
      throw ApiException(
        body['message']?.toString() ?? body['error']?['message']?.toString() ?? 'Error ${resp.statusCode}',
        statusCode: resp.statusCode,
        serverBody: body,
      );
    }
    return resp;
  }

  static List<dynamic> _listFromBody(http.Response r) {
    final data = _parseBody(r);
    return data['data'] as List<dynamic>? ?? [];
  }

  static Map<String, dynamic>? _mapFromBody(http.Response r) {
    final data = _parseBody(r);
    return data['data'] as Map<String, dynamic>?;
  }

  // ────────────────────────────────────────────────────────────────
  // PRODUCTS
  // ────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getProductos({int page = 1, int limit = 20, Map<String, dynamic>? extraParams}) async {
    final query = <String, String>{'page': '$page', 'limit': '$limit'};
    if (extraParams != null) for (final e in extraParams.entries) query[e.key] = e.value.toString();
    final r = await _get('/inventory/products', query: query);
    return _listFromBody(r);
  }

  static Future<List<dynamic>> searchProducts(String query) async {
    try {
      final r = await _get('/inventory/search', query: {'query': query.trim()});
      return _listFromBody(r);
    } on ApiException { return []; }
  }

  static Future<Map<String, dynamic>?> getProductByIdentifier(String identifier) async {
    try {
      final r = await _get('/inventory/products/$identifier');
      return _mapFromBody(r);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // PRESENTATIONS, CATEGORIES, SUPPLIERS, HOUSES
  // ────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getPresentations() async {
    final r = await _get('/inventory/presentations');
    return _listFromBody(r);
  }

  static Future<List<dynamic>> getCategories() async {
    final r = await _get('/inventory/categories');
    return _listFromBody(r);
  }

  static Future<List<dynamic>> getSuppliers() async {
    final r = await _get('/inventory/suppliers');
    return _listFromBody(r);
  }

  static Future<List<dynamic>> getHouses() async {
    final r = await _get('/inventory/houses');
    return _listFromBody(r);
  }

  // ────────────────────────────────────────────────────────────────
  // BATCHES
  // ────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getBatches({int page = 1, int limit = 100}) async {
    final r = await _get('/inventory/batches', query: {'page': '$page', 'limit': '$limit'});
    return _listFromBody(r);
  }

  static Future<List<dynamic>> getBatchesByProduct(String productId) async {
    final r = await _get('/inventory/products/$productId/batches');
    return _listFromBody(r);
  }

  static Future<Map<String, dynamic>?> getBatchById(String batchId) async {
    try {
      final r = await _get('/inventory/batches/$batchId');
      return _mapFromBody(r);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // SALES
  // ────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getSales({int limit = 999999}) async {
    final r = await _get('/sales', query: {'page': '1', 'limit': '$limit'});
    return _listFromBody(r);
  }

  static Future<Map<String, dynamic>?> getSaleById(String id) async {
    final r = await _get('/sales/$id');
    return _mapFromBody(r);
  }

  static Future<Map<String, dynamic>> registerSale({
    required List<Map<String, dynamic>> saleData,
    String? clienteId,
  }) async {
    final body = <String, dynamic>{
      'saleData': saleData,
      'clienteId': clienteId ?? '0000000000',
    };
    final r = await _post('/sales', data: body);
    return _parseBody(r);
  }

  // ────────────────────────────────────────────────────────────────
  // CLOUDINARY
  // ────────────────────────────────────────────────────────────────
  static Future<String?> uploadImage(dynamic imageFile) async {
    try {
      final uri = Uri.parse(AppConstants.cloudinaryUploadUrl);
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = AppConstants.cloudinaryUploadPreset;
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'image.png'));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      }
      final streamed = await request.send();
      final r = await http.Response.fromStream(streamed);
      if (r.statusCode == 200 || r.statusCode == 201) {
        final data = _parseBody(r);
        return data['secure_url']?.toString();
      }
    } catch (_) { rethrow; }
    return null;
  }

  // ────────────────────────────────────────────────────────────────
  // MULTIPART PRODUCT SAVE (usado por el controller)
  // ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createProductMultipart(Map<String, dynamic> data, {dynamic imageFile}) async {
    if (imageFile != null) {
      final result = await _createProductWithImage(data, imageFile);
      if (result != null) return result;
    }
    // Regular JSON POST avoids multipart parsing issues on server
    final r = await _post('/inventory/products', data: data);
    final parsed = _parseBody(r);
    return parsed['data'] as Map<String, dynamic>? ?? parsed;
  }

  static Future<Map<String, dynamic>?> _createProductWithImage(Map<String, dynamic> data, dynamic imageFile) async {
    final paths = <MapEntry<String, String>>[];
    if (!kIsWeb) paths.add(MapEntry('imagen', imageFile.path));
    try {
      final r = await _postMultipart('/inventory/products', fields: data, filePaths: paths.isNotEmpty ? paths : null);
      final parsed = _parseBody(r);
      return parsed['data'] as Map<String, dynamic>? ?? parsed;
    } on ApiException catch (e) {
      if (e.statusCode == 400 && e.serverBody.toString().contains('_internalHasFile')) {
        return null;
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateProductMultipart(String id, Map<String, dynamic> data, {dynamic imageFile}) async {
    if (imageFile != null) {
      final result = await _updateProductWithImage(id, data, imageFile);
      if (result != null) return result;
    }
    // Regular JSON PATCH avoids multipart parsing issues on server
    final r = await _patch('/inventory/products/$id', data: data);
    final parsed = _parseBody(r);
    return parsed['data'] as Map<String, dynamic>? ?? parsed;
  }

  static Future<Map<String, dynamic>?> _updateProductWithImage(String id, Map<String, dynamic> data, dynamic imageFile) async {
    final paths = <MapEntry<String, String>>[];
    if (!kIsWeb) paths.add(MapEntry('imagen', imageFile.path));
    try {
      final r = await _patchMultipart('/inventory/products/$id', fields: data, filePaths: paths.isNotEmpty ? paths : null);
      final parsed = _parseBody(r);
      return parsed['data'] as Map<String, dynamic>? ?? parsed;
    } on ApiException catch (e) {
      if (e.statusCode == 400 && e.serverBody.toString().contains('_internalHasFile')) {
        return null;
      }
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // USERS
  // ────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getUsers() async {
    final r = await _get('/users');
    return _listFromBody(r);
  }

  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final r = await _post('/users', data: data);
    return _parseBody(r);
  }

  static Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> data) async {
    final r = await _patch('/users/$id', data: data);
    return _parseBody(r);
  }

  static Future<void> deleteUser(String id) async {
    await _delete('/users/$id');
  }

  static Future<Map<String, dynamic>?> getUserByName(String nombre) async {
    try {
      final r = await _get('/users/$nombre');
      return _mapFromBody(r);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<List<dynamic>> getDeletedUsers() async {
    final r = await _get('/users/deleted');
    return _listFromBody(r);
  }

  static Future<Map<String, dynamic>> restoreUser(String id) async {
    final r = await _patch('/users/$id/restore');
    return _parseBody(r);
  }

  // ────────────────────────────────────────────────────────────────
  // ANALYTICS
  // ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getRevenueToday() async {
    final r = await _get('/analytics/revenues/today');
    return _parseBody(r);
  }

  static Future<Map<String, dynamic>> getRevenueMonth() async {
    final r = await _get('/analytics/revenues/month');
    return _parseBody(r);
  }

  static Future<Map<String, dynamic>> getSalesToday() async {
    final r = await _get('/analytics/sales/today');
    return _parseBody(r);
  }

  static Future<Map<String, dynamic>> getSalesMonth() async {
    final r = await _get('/analytics/sales/month');
    return _parseBody(r);
  }

  static Future<Map<String, dynamic>> getTopProducts() async {
    final r = await _get('/analytics/products/top');
    return _parseBody(r);
  }

  static Future<Map<String, dynamic>> getExpenses() async {
    final r = await _get('/analytics/expenses');
    return _parseBody(r);
  }

  static Future<Map<String, dynamic>> getBalance() async {
    final r = await _get('/analytics/balance');
    return _parseBody(r);
  }

  static Future<List<int>> getAnalyticsReportPdf() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/analytics/report');
    final h = await _headers();
    final resp = await _http.get(uri, headers: h).timeout(AppConstants.connectTimeout!);
    if (resp.statusCode >= 400) {
      throw ApiException('Error ${resp.statusCode}', statusCode: resp.statusCode);
    }
    return resp.bodyBytes.toList();
  }

  // ────────────────────────────────────────────────────────────────
  // NOTIFICATIONS
  // ────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getNotifications() async {
    final r = await _get('/notifications');
    return _listFromBody(r);
  }

  // ────────────────────────────────────────────────────────────────
  // MOVEMENTS
  // ────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getMovements() async {
    final r = await _get('/movements');
    return _listFromBody(r);
  }

  // ────────────────────────────────────────────────────────────────
  // CRUD HELPERS
  // ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final r = await _post('/inventory/products', data: data);
    return _parseBody(r);
  }

  static Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> data) async {
    final r = await _patch('/inventory/products/$id', data: data);
    return _parseBody(r);
  }

  static Future<void> deleteProduct(String id) async {
    await _delete('/inventory/products/$id');
  }

  static Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    final r = await _post('/inventory/categories', data: data);
    return _parseBody(r);
  }

  static Future<Map<String, dynamic>> updateCategory(String id, Map<String, dynamic> data) async {
    final r = await _patch('/inventory/categories/$id', data: data);
    return _parseBody(r);
  }

  static Future<void> deleteCategory(String id) async {
    await _delete('/inventory/categories/$id');
  }

  static Future<bool> categoryExists(String name) async {
    final r = await _get('/inventory/categories/exists', query: {'name': name});
    return _parseBody(r)['data'] == true;
  }

  static Future<Map<String, dynamic>> createPresentation(Map<String, dynamic> data) async {
    final r = await _post('/inventory/presentations', data: data);
    return _parseBody(r);
  }

  static Future<Map<String, dynamic>> updatePresentation(String id, Map<String, dynamic> data) async {
    final r = await _patch('/inventory/presentations/$id', data: data);
    return _parseBody(r);
  }

  static Future<void> deletePresentation(String id) async {
    await _delete('/inventory/presentations/$id');
  }

  static Future<bool> presentationExists(String name) async {
    final r = await _get('/inventory/presentations/exists', query: {'name': name});
    return _parseBody(r)['data'] == true;
  }

  static Future<Map<String, dynamic>> createSupplier(Map<String, dynamic> data) async {
    final r = await _post('/inventory/suppliers', data: data);
    return _parseBody(r);
  }

  static Future<Map<String, dynamic>> updateSupplier(String id, Map<String, dynamic> data) async {
    final r = await _patch('/inventory/suppliers/$id', data: data);
    return _parseBody(r);
  }

  static Future<void> deleteSupplier(String id) async {
    await _delete('/inventory/suppliers/$id');
  }

  static Future<bool> supplierExistsByName(String name) async {
    final r = await _get('/inventory/suppliers/exists', query: {'name': name});
    return _parseBody(r)['data'] == true;
  }

  static Future<bool> supplierExistsByEmail(String email) async {
    final r = await _get('/inventory/suppliers/exists', query: {'email': email});
    return _parseBody(r)['data'] == true;
  }

  static Future<Map<String, dynamic>> createHouse(Map<String, dynamic> data) async {
    final r = await _post('/inventory/houses', data: data);
    return _parseBody(r);
  }

  static Future<Map<String, dynamic>> updateHouse(String id, Map<String, dynamic> data) async {
    final r = await _patch('/inventory/houses/$id', data: data);
    return _parseBody(r);
  }

  static Future<void> deleteHouse(String id) async {
    await _delete('/inventory/houses/$id');
  }

  static Future<bool> houseExists(String name) async {
    final r = await _get('/inventory/houses/exists', query: {'name': name});
    return _parseBody(r)['data'] == true;
  }

  static Future<Map<String, dynamic>> createBatch(Map<String, dynamic> data) async {
    final r = await _post('/inventory/batches', data: data);
    return _parseBody(r);
  }

  static Future<Map<String, dynamic>> updateBatch(String id, Map<String, dynamic> data) async {
    final r = await _patch('/inventory/batches/$id', data: data);
    return _parseBody(r);
  }

  static Future<void> deleteBatch(String id) async {
    await _delete('/inventory/batches/$id');
  }

  // ────────────────────────────────────────────────────────────────
  // PRODUCT-SUPPLIER
  // ────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getProductSuppliers(String productId) async {
    final r = await _get('/inventory/products/$productId/suppliers');
    return _listFromBody(r);
  }

  static Future<Map<String, dynamic>> addSupplierToProduct(String productId, String supplierId) async {
    final r = await _post('/inventory/products/$productId/suppliers', data: {'proveedorId': supplierId});
    return _parseBody(r);
  }

  static Future<void> removeSupplierFromProduct(String productId, String supplierId) async {
    await _delete('/inventory/products/$productId/suppliers/$supplierId');
  }

  // ────────────────────────────────────────────────────────────────
  // GET BY IDENTIFIER
  // ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getCategoryByIdentifier(String identifier) async {
    try {
      final r = await _get('/inventory/categories/$identifier');
      return _mapFromBody(r);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getPresentationByIdentifier(String identifier) async {
    try {
      final r = await _get('/inventory/presentations/$identifier');
      return _mapFromBody(r);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getSupplierByIdentifier(String identifier) async {
    try {
      final r = await _get('/inventory/suppliers/$identifier');
      return _mapFromBody(r);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getInventoryAll() async {
    final r = await _get('/inventory/all');
    return _parseBody(r);
  }
}
