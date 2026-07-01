import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/app_constants.dart';
import '../utils/app_logger.dart';

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
  static HttpClient? _httpClient;
  static DateTime? _lastClientRecreation;
  
  // Configuración de reintentos y timeouts
  static const int _maxRetries = 3;
  static const Duration _connectionTimeout = Duration(seconds: 15);
  static const Duration _idleTimeout = Duration(minutes: 5);
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const Duration _clientRecreationInterval = Duration(minutes: 10);

  @visibleForTesting
  static set testCachedToken(String? t) => _cachedToken = t;

  static dynamic testClient;

  static HttpClient get _http {
    final now = DateTime.now();
    
    // Recrea el cliente cada 10 minutos o si está nulo
    if (_httpClient == null || 
        _lastClientRecreation == null ||
        now.difference(_lastClientRecreation!).inMinutes >= 10) {
      AppLogger.i('[ApiService] Recreando HttpClient (limpieza periódica)');
      _disposeClient();
      
      _httpClient = HttpClient()
        ..connectionTimeout = _connectionTimeout
        ..idleTimeout = _idleTimeout
        ..maxConnectionsPerHost = 10
        ..userAgent = 'FarmaBook/1.0.0';
      
      _lastClientRecreation = now;
    }
    
    return _httpClient!;
  }

  /// Cierra y elimina el cliente HTTP actual para que se recree fresco.
  static void _disposeClient() {
    try { 
      _httpClient?.close(force: true); 
      AppLogger.i('[ApiService] HttpClient cerrado');
    } catch (e) { 
      AppLogger.e('[ApiService] Error cerrando HttpClient', e);
    }
    _httpClient = null;
    _lastClientRecreation = null;
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

  /// Executes [fn] with retry logic (exponential backoff)
  /// Reintenta hasta 3 veces con backoff exponencial (100ms, 300ms, 900ms)
  static Future<http.Response> _request(
    Future<HttpClientResponse> Function() fn, {
    int attemptNumber = 0,
  }) async {
    try {
      final resp = await fn().timeout(_requestTimeout);
      final body = await resp.transform(utf8.decoder).join();
      // Convierte HttpHeaders → Map<String,String> para http.Response
      final hdrs = <String, String>{};
      resp.headers.forEach((name, values) => hdrs[name] = values.join(','));
      
      if (attemptNumber > 0) {
        AppLogger.i('[ApiService] Reconexión exitosa en intento $attemptNumber');
      }
      
      return http.Response(body, resp.statusCode, headers: hdrs);
    } on TimeoutException catch (e) {
      AppLogger.w('[ApiService] Timeout en intento ${attemptNumber + 1}/$_maxRetries');
      
      if (attemptNumber < _maxRetries) {
        final backoffMs = (100 * (1 << attemptNumber)).toInt(); // 100ms, 200ms, 400ms...
        AppLogger.i('[ApiService] Reintentando en ${backoffMs}ms...');
        await Future.delayed(Duration(milliseconds: backoffMs));
        _disposeClient(); // Recrea cliente antes de reintentar
        return _request(fn, attemptNumber: attemptNumber + 1);
      }
      
      AppLogger.e('[ApiService] Timeout permanente después de $_maxRetries intentos', e);
      rethrow;
    } on SocketException catch (e) {
      AppLogger.w('[ApiService] SocketException en intento ${attemptNumber + 1}/$_maxRetries: ${e.message}');
      
      if (attemptNumber < _maxRetries) {
        final backoffMs = (100 * (1 << attemptNumber)).toInt();
        AppLogger.i('[ApiService] Reintentando en ${backoffMs}ms...');
        await Future.delayed(Duration(milliseconds: backoffMs));
        _disposeClient();
        return _request(fn, attemptNumber: attemptNumber + 1);
      }
      
      AppLogger.e('[ApiService] SocketException permanente después de $_maxRetries intentos', e);
      rethrow;
    } on HttpException catch (e) {
      AppLogger.w('[ApiService] HttpException en intento ${attemptNumber + 1}/$_maxRetries: ${e.message}');
      
      if (attemptNumber < _maxRetries) {
        final backoffMs = (100 * (1 << attemptNumber)).toInt();
        AppLogger.i('[ApiService] Reintentando en ${backoffMs}ms...');
        await Future.delayed(Duration(milliseconds: backoffMs));
        _disposeClient();
        return _request(fn, attemptNumber: attemptNumber + 1);
      }
      
      AppLogger.e('[ApiService] HttpException permanente después de $_maxRetries intentos', e);
      rethrow;
    } catch (e) {
      AppLogger.e('[ApiService] Error desconocido en intento ${attemptNumber + 1}', e);
      
      if (attemptNumber < _maxRetries && (e is! ApiException)) {
        final backoffMs = (100 * (1 << attemptNumber)).toInt();
        AppLogger.i('[ApiService] Reintentando en ${backoffMs}ms...');
        await Future.delayed(Duration(milliseconds: backoffMs));
        _disposeClient();
        return _request(fn, attemptNumber: attemptNumber + 1);
      }
      
      rethrow;
    }
  }

  static void checkResponse(http.Response r) {
    if (r.statusCode >= 400) {
      final body = _parseBody(r);
      
      // Si es 401 (Unauthorized), el token está inválido o la sesión expiró
      if (r.statusCode == 401) {
        AppLogger.w('[ApiService] 401 Unauthorized - Token inválido, borrando sesión');
        clearCachedToken();
        _disposeClient();
      }
      
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

  static Future<String?> getUserToken(String username) async {
    return await _storage.read(key: '${AppConstants.tokenKey}_$username');
  }

  static Future<void> setUserToken(String username, String? token) async {
    if (token != null && token.isNotEmpty) {
      try { await _storage.write(key: '${AppConstants.tokenKey}_$username', value: token); } catch (_) {}
    } else {
      try { await _storage.delete(key: '${AppConstants.tokenKey}_$username'); } catch (_) {}
    }
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
    if (testClient != null) {
      final uri = Uri.parse('${AppConstants.baseUrl}$path').replace(queryParameters: query);
      final h = await _headers(auth: auth);
      final resp = await testClient.get(uri, headers: h) as http.Response;
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
    final uri = Uri.parse('${AppConstants.baseUrl}$path').replace(queryParameters: query);
    final h = await _headers(auth: auth);
    
    final resp = await _request(() => _http.getUrl(uri).then((r) {
      h.forEach((k, v) => r.headers.set(k, v));
      return r.close();
    }));
    
    AppLogger.api('GET', path, resp.statusCode);
    
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
    if (testClient != null) {
      final uri = Uri.parse('${AppConstants.baseUrl}$path');
      final h = await _headers(auth: auth, json: data != null);
      final body = data != null ? jsonEncode(data) : null;
      final resp = await testClient.post(uri, headers: h, body: body) as http.Response;
      if (resp.statusCode >= 400) {
        final bodyParsed = _parseBody(resp);
        throw ApiException(
          bodyParsed['message']?.toString() ?? bodyParsed['error']?['message']?.toString() ?? 'Error ${resp.statusCode}',
          statusCode: resp.statusCode,
          serverBody: bodyParsed,
        );
      }
      return resp;
    }
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final h = await _headers(auth: auth, json: data != null);
    final body = data != null ? jsonEncode(data) : null;
    
    final resp = await _request(() => _http.postUrl(uri).then((r) {
      h.forEach((k, v) => r.headers.set(k, v));
      if (body != null) r.write(body);
      return r.close();
    }));
    
    AppLogger.api('POST', path, resp.statusCode);
    
    if (resp.statusCode >= 400) {
      final bodyParsed = _parseBody(resp);
      throw ApiException(
        bodyParsed['message']?.toString() ?? bodyParsed['error']?['message']?.toString() ?? 'Error ${resp.statusCode}',
        statusCode: resp.statusCode,
        serverBody: bodyParsed,
      );
    }
    return resp;
  }

  static Future<http.Response> _patch(String path, {Map<String, dynamic>? data, bool auth = true}) async {
    if (testClient != null) {
      final uri = Uri.parse('${AppConstants.baseUrl}$path');
      final h = await _headers(auth: auth, json: data != null);
      final body = data != null ? jsonEncode(data) : null;
      final resp = await testClient.patch(uri, headers: h, body: body) as http.Response;
      if (resp.statusCode >= 400) {
        final bodyParsed = _parseBody(resp);
        throw ApiException(
          bodyParsed['message']?.toString() ?? bodyParsed['error']?['message']?.toString() ?? 'Error ${resp.statusCode}',
          statusCode: resp.statusCode,
          serverBody: bodyParsed,
        );
      }
      return resp;
    }
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final h = await _headers(auth: auth, json: data != null);
    final body = data != null ? jsonEncode(data) : null;
    
    final resp = await _request(() => _http.patchUrl(uri).then((r) {
      h.forEach((k, v) => r.headers.set(k, v));
      if (body != null) r.write(body);
      return r.close();
    }));
    
    AppLogger.api('PATCH', path, resp.statusCode);
    
    if (resp.statusCode >= 400) {
      final bodyParsed = _parseBody(resp);
      throw ApiException(
        bodyParsed['message']?.toString() ?? bodyParsed['error']?['message']?.toString() ?? 'Error ${resp.statusCode}',
        statusCode: resp.statusCode,
        serverBody: bodyParsed,
      );
    }
    return resp;
  }

  static Future<http.Response> _delete(String path, {bool auth = true}) async {
    if (testClient != null) {
      final uri = Uri.parse('${AppConstants.baseUrl}$path');
      final h = await _headers(auth: auth);
      final resp = await testClient.delete(uri, headers: h) as http.Response;
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
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final h = await _headers(auth: auth);
    
    final resp = await _request(() => _http.deleteUrl(uri).then((r) {
      h.forEach((k, v) => r.headers.set(k, v));
      return r.close();
    }));
    
    AppLogger.api('DELETE', path, resp.statusCode);
    
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
    final streamed = await request.send().timeout(_requestTimeout);
    final resp = await http.Response.fromStream(streamed);
    AppLogger.api('POST_MULTIPART', path, resp.statusCode);
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
    final streamed = await request.send().timeout(_requestTimeout);
    final resp = await http.Response.fromStream(streamed);
    AppLogger.api('PATCH_MULTIPART', path, resp.statusCode);
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
  static Future<List<dynamic>> getBatches({int page = 1, int limit = 100, String? productoId, String? vencidosAntes, String? vencidosDespues}) async {
    final query = <String, String>{'page': '$page', 'limit': '$limit'};
    if (productoId != null) query['productoId'] = productoId;
    if (vencidosAntes != null) query['vencidosAntes'] = vencidosAntes;
    if (vencidosDespues != null) query['vencidosDespues'] = vencidosDespues;
    final r = await _get('/inventory/batches', query: query);
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
  static Future<List<dynamic>> getSales({int limit = 999999, Map<String, String>? queryParams}) async {
    final Map<String, String> query = {'page': '1', 'limit': '$limit'};
    if (queryParams != null) {
      query.addAll(queryParams);
    }
    final r = await _get('/sales', query: query);
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
    final List? suppliersList = data['proveedores'] as List?;
    final List? housesList = data['casas'] as List?;

    final Map<String, dynamic> cleanData = {};
    final modifiableFields = [
      'codigoBarras', 'nombre', 'nombreGenerico', 'concentracion', 
      'descripcion', 'precioPorUnidad', 'dosisRecomendada', 
      'tempMin', 'tempMax', 'categoriaId', 'presentacionId'
    ];
    for (var f in modifiableFields) {
      if (data.containsKey(f)) {
        cleanData[f] = data[f];
      }
    }

    Map<String, dynamic> result;
    if (imageFile != null) {
      final res = await _updateProductWithImage(id, cleanData, imageFile);
      if (res != null) {
        result = res;
      } else {
        final r = await _patchMultipart('/inventory/products/$id', fields: cleanData, filePaths: null);
        final parsed = _parseBody(r);
        result = parsed['data'] as Map<String, dynamic>? ?? parsed;
      }
    } else {
      final r = await _patchMultipart('/inventory/products/$id', fields: cleanData, filePaths: null);
      final parsed = _parseBody(r);
      result = parsed['data'] as Map<String, dynamic>? ?? parsed;
    }

    if (suppliersList != null && suppliersList.isNotEmpty) {
      for (var s in suppliersList) {
        if (s is Map) {
          final provId = s['proveedorId']?.toString();
          final costo = double.tryParse(s['costo']?.toString() ?? '0') ?? 0.0;
          if (provId != null && provId.isNotEmpty) {
            try {
              await addSupplierToProduct(id, provId, cost: costo);
            } catch (_) {}
          }
        }
      }
    }

    if (housesList != null && housesList.isNotEmpty) {
      for (var h in housesList) {
        final houseId = h?.toString();
        if (houseId != null && houseId.isNotEmpty) {
          try {
            await addHouseToProduct(id, houseId);
          } catch (_) {}
        }
      }
    }

    return result;
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
    final body = _parseBody(r);
    final token = body['data']?['token'] as String? ?? body['token'] as String?;
    if (token != null && token.isNotEmpty) {
      final username = (data['username'] ?? '').toString().trim();
      if (username.isNotEmpty) {
        await setUserToken(username, token);
        await setToken(token);
      }
    }
    return body;
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
    final h = await _headers();
    final uri = Uri.parse('${AppConstants.baseUrl}/analytics/report');
    final resp = await http.get(uri, headers: h).timeout(_requestTimeout);
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

  // NOTA: GET /inventory/products/deleted no existe en el API
  // Los productos eliminados son soft-deleted y no se pueden recuperar
  static Future<List<dynamic>> getDeletedProducts() async {
    // Devolver lista vacía para evitar peticiones al endpoint inexistente
    return [];
  }

  static Future<Map<String, dynamic>> restoreProduct(String id) async {
    final r = await _patch('/inventory/products/$id/restore');
    return _parseBody(r);
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

  static Future<Map<String, dynamic>> addSupplierToProduct(String productId, String supplierId, {double? cost}) async {
    final Map<String, dynamic> body = {'proveedorId': supplierId};
    if (cost != null && cost > 0) {
      body['costo'] = cost;
    }
    final r = await _post('/inventory/products/$productId/suppliers', data: body);
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

  // ────────────────────────────────────────────────────────────────
  // PRODUCT-HOUSES
  // ────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getProductHouses(String productId) async {
    final r = await _get('/inventory/products/$productId/houses');
    return _listFromBody(r);
  }

  static Future<Map<String, dynamic>> addHouseToProduct(String productId, String houseId) async {
    final r = await _post('/inventory/products/$productId/houses', data: {'casaId': houseId});
    return _parseBody(r);
  }

  static Future<void> removeHouseFromProduct(String productId, String houseId) async {
    await _delete('/inventory/products/$productId/houses/$houseId');
  }

  // ────────────────────────────────────────────────────────────────
  // HOUSE DETAIL
  // ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getHouseByIdentifier(String identifier) async {
    try {
      final r = await _get('/inventory/houses/$identifier');
      return _mapFromBody(r);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<List<dynamic>> getHouseSuppliers(String houseId) async {
    final r = await _get('/inventory/houses/$houseId/suppliers');
    return _listFromBody(r);
  }

  static Future<List<dynamic>> getHouseProducts(String houseId) async {
    final r = await _get('/inventory/houses/$houseId/products');
    return _listFromBody(r);
  }

  // ────────────────────────────────────────────────────────────────
  // SUPPLIER PRODUCT-HOUSES
  // ────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getSupplierProductHouses(String supplierId) async {
    final r = await _get('/inventory/suppliers/$supplierId/product-houses');
    return _listFromBody(r);
  }

  // ────────────────────────────────────────────────────────────────
  // CANCEL SALE
  // ────────────────────────────────────────────────────────────────
  static Future<void> deleteSale(String saleId) async {
    await _delete('/sales/$saleId');
  }

  // ────────────────────────────────────────────────────────────────
  // ANALYTICS: SUPPLIER RANKING
  // ────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getSupplierAvgCost({String? order, int? limit, String? casaId}) async {
    final query = <String, String>{};
    if (order != null) query['order'] = order;
    if (limit != null) query['limit'] = '$limit';
    if (casaId != null) query['casaId'] = casaId;
    final r = await _get('/analytics/suppliers/by-avg-cost', query: query.isNotEmpty ? query : null);
    return _listFromBody(r);
  }

  // ────────────────────────────────────────────────────────────────
  // PASSWORD RESTORE (no auth required, except reset-password uses reset JWT)
  // ────────────────────────────────────────────────────────────────
  static Future<void> restorePassword(String username) async {
    await _post('/auth/restore', data: {'username': username}, auth: false);
  }

  static Future<String> verifyRestorePin(String username, String pin) async {
    final r = await _post('/auth/restore-verify', data: {'username': username, 'pin': pin}, auth: false);
    final body = _parseBody(r);
    final token = body['data']?['token'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException('No se recibió token de restablecimiento', statusCode: r.statusCode, serverBody: body);
    }
    return token;
  }

  static Future<void> resetPassword(String resetToken, String password) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/auth/restore-password');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $resetToken',
    };
    final resp = await http.post(uri, headers: headers, body: jsonEncode({'password': password})).timeout(AppConstants.connectTimeout!);
    if (resp.statusCode >= 400) {
      final body = _parseBody(resp);
      throw ApiException(
        body['message']?.toString() ?? body['error']?['message']?.toString() ?? 'Error ${resp.statusCode}',
        statusCode: resp.statusCode,
        serverBody: body,
      );
    }
  }
}
