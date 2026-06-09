import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UsuariosController extends ChangeNotifier {

  List<dynamic> usuarios = [];
  List<dynamic> roles = [];
  bool isLoading = false;
  String? error;

  UsuariosController();



  Future<void> fetchAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final resUsers = await ApiService.getUsers();
      usuarios = resUsers;

      final Map<String, dynamic> discoveredRoles = {};
      for (var u in usuarios) {
        if (u['Rol'] != null) {
          final rid = u['Rol']['rolId']?.toString();
          final rname = u['Rol']['nombre']?.toString();
          if (rid != null && rname != null) {
            discoveredRoles[rid] = {'rolId': rid, 'nombre': rname};
          }
        }
      }

      if (discoveredRoles.isNotEmpty) {
        roles = discoveredRoles.values.toList();
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    try {
      await ApiService.createUser(data);
      await fetchAll();
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    try {
      await ApiService.updateUser(id, data);
      await fetchAll();
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await ApiService.deleteUser(id);
      await fetchAll();
    } catch (e) {
      error = e.toString();
      rethrow;
    }
  }
}
