import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CategoriasController extends ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://farmabook.onrender.com'));
  final _storage = const FlutterSecureStorage();

  List<dynamic> categorias = [];
  bool isLoading = true;
  String? error;

  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController descripcionCtrl = TextEditingController();

  Future<void> init() async {
    await cargarCategorias();
  }

  Future<void> cargarCategorias() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
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
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
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
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
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
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      await _dio.delete('/inventory/categories/$id');
      await cargarCategorias();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    descripcionCtrl.dispose();
    super.dispose();
  }
}
