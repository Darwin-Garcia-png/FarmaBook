import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DashboardController extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  int selectedIndex = 0;

  void onItemTapped(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }
}
