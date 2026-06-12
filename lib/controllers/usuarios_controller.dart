import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UsuariosController extends ChangeNotifier {
  List<Map<String, dynamic>> usuarios = [];
  List<Map<String, dynamic>> deletedUsuarios = [];
  bool isLoading = false;
  bool isLoadingDeleted = false;
  String? error;
  bool showDeleted = false;

  UsuariosController();

  Future<void> fetchAll() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final res = await ApiService.getUsers();
      usuarios = res.cast<Map<String, dynamic>>();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDeleted() async {
    isLoadingDeleted = true;
    notifyListeners();
    try {
      final res = await ApiService.getDeletedUsers();
      deletedUsuarios = res.cast<Map<String, dynamic>>();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoadingDeleted = false;
      notifyListeners();
    }
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    await ApiService.createUser(data);
    await fetchAll();
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await ApiService.updateUser(id, data);
    await fetchAll();
  }

  Future<void> deleteUser(String id) async {
    await ApiService.deleteUser(id);
    await fetchAll();
  }

  Future<void> restoreUser(String id) async {
    await ApiService.restoreUser(id);
    await fetchAll();
    await fetchDeleted();
  }
}
