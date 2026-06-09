import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../utils/app_constants.dart';

class AuthService {
  static Dio? _authDio;

  static Dio _getDio() {
    if (_authDio != null) return _authDio!;
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    if (!kIsWeb) {
      try {
        (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
            () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        };
      } catch (_) {}
    }
    _authDio = dio;
    return dio;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    ApiService.clearCachedToken();
    try {
      final response = await _getDio().post(
        '/auth/login',
        data: {
          'username': email.trim(),
          'password': password,
        },
      );

      final body = response.data as Map<String, dynamic>;

      String? token;
      token = body['data']?['token'] as String?;
      token ??= body['token'] as String?;
      token ??= body['access_token'] as String?;
      token ??= body['accessToken'] as String?;
      token ??= body['jwt'] as String?;
      if (token != null && token.isNotEmpty) {
        await ApiService.setToken(token);
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
        'body': <String, dynamic>{},
        'message': 'Error: $e',
        'error': true,
      };
    }
  }

  Future<void> logout() async {
    await ApiService.setToken(null);
  }

  Future<String?> getToken() async {
    return await ApiService.getToken();
  }
}
