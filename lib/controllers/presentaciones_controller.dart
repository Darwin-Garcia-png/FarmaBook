import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PresentacionesController extends ChangeNotifier {
  final Dio _dio = ApiService.dio;


  List<dynamic> presentaciones = [];
  bool isLoading = true;
  String? error;

  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController descripcionCtrl = TextEditingController();

  PresentacionesController();

  @override
  void dispose() {
    nombreCtrl.dispose();
    descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> init() async {
    await cargarPresentaciones();
  }

  Future<void> cargarPresentaciones() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await ApiService.setAuthHeader();
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
      await ApiService.setAuthHeader();
      
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
      await ApiService.setAuthHeader();
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
      await ApiService.setAuthHeader();
      await _dio.delete('/inventory/presentations/$id');
      await cargarPresentaciones();
      return true;
    } catch (e) {
      return false;
    }
  }
}
