import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ConfigController extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  bool notificaciones = true;
  String idiomaSeleccionado = 'Español (Colombia)';
  bool darkMode = false;

  // New Local Fields
  String pharmacyName = 'Mi Farmacia';
  String userEmail = '';
  String? lastBackup;

  bool isLoading = false;

  Future<void> cargarPreferencias() async {
    final dark = await _storage.read(key: 'dark_mode') ?? 'false';
    final notif = await _storage.read(key: 'notificaciones') ?? 'true';
    final idioma = await _storage.read(key: 'idioma') ?? 'Español (Colombia)';
    final pName = await _storage.read(key: 'pharmacy_name') ?? 'Mi Farmacia';
    final email =
        await _storage.read(key: 'user_email') ?? 'usuario@farmabook.com';
    final backup = await _storage.read(key: 'last_backup');

    darkMode = dark == 'true';
    notificaciones = notif == 'true';
    idiomaSeleccionado = idioma;
    pharmacyName = pName;
    userEmail = email;
    lastBackup = backup;
    notifyListeners();
  }

  Future<void> guardarPreferencia(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  void cambiarTema(bool value) {
    darkMode = value;
    guardarPreferencia('dark_mode', value.toString());
    notifyListeners();
  }

  void cambiarNotificaciones(bool value) {
    notificaciones = value;
    guardarPreferencia('notificaciones', value.toString());
    notifyListeners();
  }

  Future<void> cambiarNombreFarmacia(String nuevoNombre) async {
    if (nuevoNombre.trim().isEmpty) return;
    pharmacyName = nuevoNombre.trim();
    await guardarPreferencia('pharmacy_name', pharmacyName);
    notifyListeners();
  }

  void cambiarIdioma(String nuevoIdioma) {
    idiomaSeleccionado = nuevoIdioma;
    guardarPreferencia('idioma', nuevoIdioma);
    notifyListeners();
  }

  // Utility: Export Inventory to CSV (Simulated/Frontend Logic)
  Future<String> exportarInventarioCSV(List<dynamic> productos) async {
    isLoading = true;
    notifyListeners();

    try {
      // Create CSV content
      StringBuffer csv = StringBuffer();
      csv.writeln('ID,Nombre,Codigo,Precio,Stock');

      for (var p in productos) {
        csv.writeln(
            '${p['productoId']},${p['nombre']},${p['codigoBarras']},${p['precioPorUnidad']},${p['cantidadDisponible']}');
      }

      // Update last backup date
      lastBackup = DateTime.now().toString().split('.')[0];
      await guardarPreferencia('last_backup', lastBackup!);

      // In a real app we would use path_provider and dart:io to save a file,
      // but for this web/demo we return the string or a success message.
      await Future.delayed(const Duration(seconds: 1)); // Simulate processing
      return csv.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> limpiarCache() async {
    // Keep auth but clear other UI preferences if needed
    // For now, let's just clear specific UI keys
    await _storage.delete(key: 'last_backup');
    lastBackup = null;
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_email');
  }
}
