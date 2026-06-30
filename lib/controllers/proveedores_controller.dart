import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProveedoresController extends ChangeNotifier {
  List<dynamic> proveedores = [];
  List<dynamic> _filteredCache = [];
  bool isLoading = true;
  String? error;

  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController direccionCtrl = TextEditingController();
  final TextEditingController telefonoCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController searchCtrl = TextEditingController();

  @override
  void dispose() {
    nombreCtrl.dispose();
    direccionCtrl.dispose();
    telefonoCtrl.dispose();
    emailCtrl.dispose();
    searchCtrl.dispose();
    super.dispose();
  }

  List<dynamic> get filteredProveedores => _filteredCache;

  Future<void> init() async {
    await cargarProveedores();
  }

  void search(String query) {
    _applyLocalFilter(query);
  }

  void _applyLocalFilter([String? query]) {
    final q = (query ?? searchCtrl.text).toLowerCase().trim();
    if (q.isEmpty) {
      _filteredCache = proveedores;
    } else {
      _filteredCache = proveedores.where((p) {
        final name = (p['nombre'] ?? '').toString().toLowerCase();
        final mail = (p['email'] ?? '').toString().toLowerCase();
        return name.contains(q) || mail.contains(q);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> cargarProveedores() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      proveedores = await ApiService.getSuppliers();
      _applyLocalFilter();
    } catch (e) {
      error = 'No se pudieron cargar los proveedores';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> agregarProveedor() async {
    if (nombreCtrl.text.trim().isEmpty) return false;

    try {
      
      await ApiService.createSupplier({
        'nombre': nombreCtrl.text.trim(),
        'direccion': direccionCtrl.text.trim(),
        'telefono': telefonoCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
      });

      limpiarForm();
      await cargarProveedores();
      return true;
    } catch (e) {
      error = 'Error al guardar. Verifica los datos.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarProveedor(String id, Map<String, dynamic> data) async {
    try {
      await ApiService.updateSupplier(id, data);
      await cargarProveedores();
      return true;
    } catch (e) {
      error = 'Error al actualizar. Verifica los datos.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarProveedor(String id) async {
    try {
      await ApiService.deleteSupplier(id);
      await cargarProveedores();
      return true;
    } catch (e) {
      error = 'Error al eliminar. Puede tener dependencias asociadas.';
      notifyListeners();
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
