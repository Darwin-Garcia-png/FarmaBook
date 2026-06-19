class UserSession {
  static String? email;
  static String? role;
  static int? userId;

  static bool get isDueno => role?.toLowerCase() == 'dueño' || role?.toLowerCase() == 'admin';
  static bool get isEmpleado => role?.toLowerCase() == 'empleado' || role?.toLowerCase() == 'cajero';

  static void save(Map<String, dynamic>? userData) {
    if (userData == null) return;
    email = userData['email']?.toString() ?? userData['username']?.toString();
    role = userData['rol']?.toString();
    userId = userData['usuarioId'] ?? userData['id'];
  }

  static void clear() {
    email = null;
    role = null;
    userId = null;
  }
}
