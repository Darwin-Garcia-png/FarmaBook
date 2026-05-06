import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UsuariosController extends ChangeNotifier {
  Timer? _refreshTimer;
  List<dynamic> usuarios = [];
  // Hardcoded default roles as fallback to ensure the UI is never empty
  List<dynamic> roles = [
    {'rolId': 'admin-uuid-placeholder', 'nombre': 'Administrador'},
    {'rolId': 'cajero-uuid-placeholder', 'nombre': 'Cajero'},
    {'rolId': 'dueno-uuid-placeholder', 'nombre': 'Dueño'},
  ];
  bool isLoading = false;
  String? error;

  UsuariosController() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!isLoading) fetchAll();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchAll() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final resUsers = await ApiService.getUsers();
      usuarios = resUsers;
      
      // DISCOVERY: Extract unique roles from the user list itself
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
    }

    try {
      final resRoles = await ApiService.getRoles();
      if (resRoles.isNotEmpty) {
        // Only if the guessed endpoint actually works, we prefer that
        roles = resRoles;
      }
    } catch (e) {
      print('DEBUG: Error fetching explicit roles: $e');
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
