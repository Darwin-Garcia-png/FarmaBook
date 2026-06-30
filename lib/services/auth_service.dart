import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../utils/app_constants.dart';
import '../utils/app_logger.dart';

class AuthService {
  static http.Client? _client;

  static http.Client get _http {
    if (_client == null) _client = http.Client();
    return _client!;
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, dynamic>> login(String email, String password) async {
    ApiService.clearCachedToken();
    AppLogger.auth('Login attempt: $email');
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/auth/login');
      final response = await _http
          .post(uri,
              headers: _headers,
              body: jsonEncode({
                'username': email.trim(),
                'password': password,
              }))
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      String? token;
      token = body['data']?['token'] as String?;
      token ??= body['token'] as String?;
      token ??= body['access_token'] as String?;
      token ??= body['accessToken'] as String?;
      token ??= body['jwt'] as String?;
      if (token != null && token.isNotEmpty) {
        await ApiService.setToken(token);
        AppLogger.auth('Login success: $email');
      }

      return {
        'statusCode': response.statusCode,
        'body': body,
      };
    } catch (e) {
      AppLogger.auth('Login failed: $email — $e');
      if (e is http.ClientException) {
        return {
          'statusCode': 0,
          'body': <String, dynamic>{},
          'message': 'Error de conexión',
          'error': true,
        };
      }
      if (e is Exception && e.toString().contains('TimeoutException')) {
        return {
          'statusCode': 0,
          'body': <String, dynamic>{},
          'message': 'Tiempo de espera agotado',
          'error': true,
        };
      }
      Map<String, dynamic> errorBody = {};
      String msg = 'Error de conexión';
      if (e is http.Response) {
        try { errorBody = jsonDecode(e.body) as Map<String, dynamic>; } catch (_) {}
        msg = errorBody['error']?['message'] is List
            ? (errorBody['error']['message'] as List).join('\n')
            : errorBody['error']?['message'] ?? errorBody['message'] ?? msg;
        return {
          'statusCode': e.statusCode,
          'body': errorBody,
          'message': msg,
          'error': true,
        };
      }
      return {
        'statusCode': 0,
        'body': <String, dynamic>{},
        'message': 'Error de conexión. Verifica tu red.',
        'error': true,
      };
    }
  }

  Future<void> logout() async {
    AppLogger.auth('Logout');
    await ApiService.setToken(null);
  }

  Future<String?> getToken() async {
    return await ApiService.getToken();
  }
}
