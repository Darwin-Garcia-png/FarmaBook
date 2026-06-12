import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CategoriasController extends ChangeNotifier {
  List<dynamic> categorias = [];
  bool isLoading = true;
  String? error;

  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController descripcionCtrl = TextEditingController();

  CategoriasController();

  @override
  void dispose() {
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
            categorias = await ApiService.getCategories();
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
            
      await ApiService.createCategory({
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
            await ApiService.updateCategory(id, {
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
            await ApiService.deleteCategory(id);
      await cargarCategorias();
      return true;
    } catch (e) {
      return false;
    }
  }
}
