import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_constants.dart';

class AuthService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  AuthService() {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': email.trim(),
          'password': password,
        },
      );

      final body = response.data as Map<String, dynamic>;

      final token = body['data']?['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await _storage.write(key: AppConstants.tokenKey, value: token);
      }

      return {
        'statusCode': response.statusCode,
        'body': body,
      };
    } on DioException catch (e) {
      Map<String, dynamic> errorBody = {};
      String msg = 'Error de conexión';

      if (e.response != null) {
        errorBody = e.response!.data as Map<String, dynamic>? ?? {};
        msg = errorBody['error']?['message'] is List
            ? (errorBody['error']['message'] as List).join('\n')
            : errorBody['error']?['message'] ?? errorBody['message'] ?? msg;
      }

      return {
        'statusCode': e.response?.statusCode ?? 0,
        'body': errorBody,
        'message': msg,
        'error': true,
      };
    } catch (e) {
      return {
        'statusCode': 0,
        'message': 'Error inesperado: $e',
        'error': true,
      };
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }
}
