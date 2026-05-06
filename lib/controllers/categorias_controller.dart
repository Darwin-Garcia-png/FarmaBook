import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoriasController extends ChangeNotifier {
  final Dio _dio = ApiService.dio;
  Timer? _refreshTimer;

  List<dynamic> categorias = [];
  bool isLoading = true;
  String? error;

  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController descripcionCtrl = TextEditingController();

  CategoriasController() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!isLoading) cargarCategorias();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    nombreCtrl.dispose();
    descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> init() async {
    await cargarCategorias();
  }

  Future<void> cargarCategorias() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await ApiService.setAuthHeader();
      final res = await _dio.get('/inventory/categories');
      categorias = res.data['data'] ?? [];
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> agregarCategoria() async {
    if (nombreCtrl.text.trim().isEmpty) {
      return false;
    }

    try {
      await ApiService.setAuthHeader();
      
      await _dio.post('/inventory/categories', data: {
        'nombre': nombreCtrl.text.trim(),
        'descripcion': descripcionCtrl.text.trim(),
      });

      nombreCtrl.clear();
      descripcionCtrl.clear();
      await cargarCategorias();
      return true;
    } catch (e) {
      debugPrint("Error adding category: $e");
      return false;
    }
  }

  Future<bool> actualizarCategoria(dynamic id) async {
    try {
      await ApiService.setAuthHeader();
      await _dio.put('/inventory/categories/$id', data: {
        'nombre': nombreCtrl.text.trim(),
        'descripcion': descripcionCtrl.text.trim(),
      });
      await cargarCategorias();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> eliminarCategoria(dynamic id) async {
    try {
      await ApiService.setAuthHeader();
      await _dio.delete('/inventory/categories/$id');
      await cargarCategorias();
      return true;
    } catch (e) {
      return false;
    }
  }
}
