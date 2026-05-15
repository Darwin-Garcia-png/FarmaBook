import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProveedoresController extends ChangeNotifier {
  final Dio _dio = ApiService.dio;
  Timer? _refreshTimer;
  Timer? _debounceTimer;

  List<dynamic> proveedores = [];
  List<dynamic> _filteredCache = [];
  bool isLoading = true;
  String? error;

  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController direccionCtrl = TextEditingController();
  final TextEditingController telefonoCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController searchCtrl = TextEditingController();

  ProveedoresController() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 120), (timer) {
      if (!isLoading) cargarProveedores();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _debounceTimer?.cancel();
    nombreCtrl.dispose();
    direccionCtrl.dispose();
    telefonoCtrl.dispose();
    emailCtrl.dispose();
    searchCtrl.dispose();
    super.dispose();
  }

  List<dynamic> get filteredProveedores => _filteredCache;

  Future<void> init() async {
    searchCtrl.addListener(_onSearchChanged);
    await cargarProveedores();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _applyLocalFilter();
    });
  }

  void _applyLocalFilter() {
    final query = searchCtrl.text.toLowerCase().trim();
    if (query.isEmpty) {
      _filteredCache = proveedores;
    } else {
      _filteredCache = proveedores.where((p) {
        final name = (p['nombre'] ?? '').toString().toLowerCase();
        final mail = (p['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || mail.contains(query);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> cargarProveedores() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await ApiService.setAuthHeader();
      final res = await _dio.get('/inventory/suppliers');
      proveedores = res.data['data'] ?? [];
      _applyLocalFilter();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> agregarProveedor() async {
    if (nombreCtrl.text.trim().isEmpty) return false;

    try {
      await ApiService.setAuthHeader();
      
      await _dio.post('/inventory/suppliers', data: {
        'nombre': nombreCtrl.text.trim(),
        'direccion': direccionCtrl.text.trim(),
        'telefono': telefonoCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
      });

      limpiarForm();
      await cargarProveedores();
      return true;
    } catch (e) {
      debugPrint("Error adding supplier: $e");
      return false;
    }
  }

  Future<bool> actualizarProveedor(String id, Map<String, dynamic> data) async {
    try {
      await ApiService.setAuthHeader();
      await _dio.put('/inventory/suppliers/$id', data: data);
      await cargarProveedores();
      return true;
    } catch (e) {
      debugPrint("Error updating supplier: $e");
      return false;
    }
  }

  Future<bool> eliminarProveedor(String id) async {
    try {
      await ApiService.setAuthHeader();
      await _dio.delete('/inventory/suppliers/$id');
      await cargarProveedores();
      return true;
    } catch (e) {
      debugPrint("Error deleting supplier: $e");
      return false;
    }
  }

  void limpiarForm() {
    nombreCtrl.clear();
    direccionCtrl.clear();
    telefonoCtrl.clear();
    emailCtrl.clear();
  }
}
