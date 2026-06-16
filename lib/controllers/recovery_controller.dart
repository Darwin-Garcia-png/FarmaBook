import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RecoveryController extends ChangeNotifier {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;
  String? resetToken;
  String? errorMessage;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleConfirmVisibility() {
    obscureConfirm = !obscureConfirm;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> sendPin() async {
    if (!formKey.currentState!.validate()) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await ApiService.restorePassword(usernameController.text.trim());
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = 'Error de conexión';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyPin() async {
    if (!formKey.currentState!.validate()) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      resetToken = await ApiService.verifyRestorePin(
        usernameController.text.trim(),
        pinController.text.trim(),
      );
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = 'Error de conexión';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setNewPassword() async {
    if (!formKey.currentState!.validate()) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await ApiService.resetPassword(resetToken!, passwordController.text);
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = 'Error de conexión';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    usernameController.clear();
    pinController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    resetToken = null;
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    usernameController.dispose();
    pinController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
