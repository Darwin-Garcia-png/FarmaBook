import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PresentacionesController extends ChangeNotifier {
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
      presentaciones = await ApiService.getPresentations();
    } catch (e) {
      error = 'No se pudieron cargar las presentaciones';
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
      
      await ApiService.createPresentation({
        'nombre': nombreCtrl.text.trim(),
        'descripcion': descripcionCtrl.text.trim(),
      });

      nombreCtrl.clear();
      descripcionCtrl.clear();
      await cargarPresentaciones();
      return true;
    } catch (e) {
      error = 'Error al guardar. Verifica los datos.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarPresentacion(dynamic id) async {
    try {
      await ApiService.updatePresentation(id, {
        'nombre': nombreCtrl.text.trim(),
        'descripcion': descripcionCtrl.text.trim(),
      });
      await cargarPresentaciones();
      return true;
    } catch (e) {
      error = 'Error al actualizar. Verifica los datos.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarPresentacion(dynamic id) async {
    try {
      await ApiService.deletePresentation(id);
      await cargarPresentaciones();
      return true;
    } catch (e) {
      error = 'Error al eliminar. Puede tener dependencias asociadas.';
      notifyListeners();
      return false;
    }
  }
}
