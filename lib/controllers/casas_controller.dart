import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/error_display.dart';

class CasasController extends ChangeNotifier {

  List<dynamic> casas = [];
  bool isLoading = true;
  String? error;

  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController paisCtrl = TextEditingController();

  CasasController();

  @override
  void dispose() {
    nombreCtrl.dispose();
    paisCtrl.dispose();
    super.dispose();
  }

  Future<void> init() async {
    await cargarCasas();
  }

  Future<void> cargarCasas() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      casas = await ApiService.getHouses();
    } catch (e) {
      error = 'No se pudieron cargar las casas';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> agregarCasa() async {
    if (nombreCtrl.text.trim().isEmpty) return false;

    try {
      final data = <String, dynamic>{
        'nombre': nombreCtrl.text.trim(),
      };
      if (paisCtrl.text.trim().isNotEmpty) {
        data['paisDeOrigen'] = paisCtrl.text.trim();
      }

      await ApiService.createHouse(data);

      nombreCtrl.clear();
      paisCtrl.clear();
      await cargarCasas();
      return true;
    } catch (e) {
      error = ErrorDisplay.cleanMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarCasa(String id) async {
    try {
      final data = <String, dynamic>{
        'nombre': nombreCtrl.text.trim(),
      };
      if (paisCtrl.text.trim().isNotEmpty) {
        data['paisDeOrigen'] = paisCtrl.text.trim();
      }

      await ApiService.updateHouse(id, data);
      await cargarCasas();
      return true;
    } catch (e) {
      error = ErrorDisplay.cleanMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarCasa(String id) async {
    try {
      await ApiService.deleteHouse(id);
      await cargarCasas();
      return true;
    } catch (e) {
      error = ErrorDisplay.cleanMessage(e);
      notifyListeners();
      return false;
    }
  }
}
