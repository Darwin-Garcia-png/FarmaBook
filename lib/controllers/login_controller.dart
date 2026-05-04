import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import '../utils/global_error_handler.dart' as import_handler;

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

  Future<bool> login() async {
    if (!formKey.currentState!.validate()) return false;

    isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (result['statusCode'] == 200 && result['body']['success'] == true) {
        // Save email for profile display in Settings
        const storage = FlutterSecureStorage();
        await storage.write(
            key: 'user_email', value: emailController.text.trim());
        return true;
      } else {
        final errorMsg = result['body']['error']?['message'] is List
            ? (result['body']['error']['message'] as List).join('\n')
            : result['body']['error']?['message'] ??
                result['body']['message'] ??
                result['message'] ??
                'Login fallido';
        import_handler.GlobalErrorHandler.showError(errorMsg, statusCode: result['statusCode']);
        return false;
      }
    } catch (e) {
      import_handler.GlobalErrorHandler.showError('Error: $e');
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
