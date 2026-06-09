import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardController extends ChangeNotifier {
  int selectedIndex = 0;

  void onItemTapped(int index) {
    selectedIndex = index;
    notifyListeners();
  }

  Future<void> logout() async {
    await ApiService.setToken(null);
  }
}
