import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PresentacionesController extends ChangeNotifier {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://farmabook.onrender.com'));
  final _storage = const FlutterSecureStorage();

  List<dynamic> presentaciones = [];
  bool isLoading = true;
  String? error;

  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController descripcionCtrl = TextEditingController();

  Future<void> init() async {
    await cargarPresentaciones();
  }

  Future<void> cargarPresentaciones() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final res = await _dio.get('/inventory/presentations');
      presentaciones = res.data['data'] ?? [];
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> agregarPresentacion() async {
    if (nombreCtrl.text.trim().isEmpty) {
      return false;
    }

    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      await _dio.post('/inventory/presentations', data: {
        'nombre': nombreCtrl.text.trim(),
        'descripcion': descripcionCtrl.text.trim(),
      });

      nombreCtrl.clear();
      descripcionCtrl.clear();
      await cargarPresentaciones();
      return true;
    } catch (e) {
      debugPrint("Error adding presentation: $e");
      return false;
    }
  }

  Future<bool> actualizarPresentacion(dynamic id) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      await _dio.put('/inventory/presentations/$id', data: {
        'nombre': nombreCtrl.text.trim(),
        'descripcion': descripcionCtrl.text.trim(),
      });
      await cargarPresentaciones();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> eliminarPresentacion(dynamic id) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      await _dio.delete('/inventory/presentations/$id');
      await cargarPresentaciones();
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
