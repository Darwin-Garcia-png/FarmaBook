import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../router/app_router.dart';
import '../widgets/error_display.dart';

class LoginController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool obscurePassword = true;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void _showError(String message, {int? statusCode}) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final hint = ErrorDisplay.hintFromMessage(message);
    ErrorDisplay.dialog(context: ctx, message: message, hint: hint, title: statusCode != null ? 'Error ($statusCode)' : 'Error');
  }

  Future<bool> login() async {
    if (!formKey.currentState!.validate()) return false;

    isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (result['statusCode'] == 200) {
        final storedToken = await _authService.getToken();
        if (storedToken == null || storedToken.isEmpty) {
          _showError(
            'Login exitoso pero no se encontró token.\n'
            'Respuesta del servidor:\n$result',
            statusCode: 200,
          );
          return false;
        }
        const storage = FlutterSecureStorage();
        await storage.write(
            key: 'user_email', value: emailController.text.trim());
        return true;
      } else {
        final errorMsg = result['body']?['error']?['message'] is List
            ? (result['body']['error']['message'] as List).join('\n')
            : result['body']?['error']?['message'] ??
                result['body']?['message'] ??
                result['message'] ??
                'Login fallido';
        _showError(errorMsg, statusCode: result['statusCode']);
        return false;
      }
    } catch (e) {
      _showError('Error: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
