class UserSession {
  static String? email;
  static String? role;
  static int? userId;

  static bool get isDueno => role?.toLowerCase() == 'dueño' || role?.toLowerCase() == 'admin' || role?.toLowerCase() == 'administrador';
  static bool get isEmpleado => role?.toLowerCase() == 'empleado' || role?.toLowerCase() == 'cajero' || role?.toLowerCase() == 'vendedor';
  static bool get canEdit => isDueno;

  static void save(Map<String, dynamic>? userData) {
    if (userData == null) return;
    final inner = _deepFindUser(userData);
    email = _firstNonEmpty([
      inner['email']?.toString(),
      inner['correo']?.toString(),
      inner['correoElectronico']?.toString(),
      inner['mail']?.toString(),
      inner['username']?.toString(),
      inner['nombreUsuario']?.toString(),
      userData['email']?.toString(),
      userData['correo']?.toString(),
    ]);
    role = _firstNonEmpty([
      inner['rol']?.toString(),
      inner['nombreRol']?.toString(),
      inner['role']?.toString(),
      inner['tipo']?.toString(),
      inner['tipoUsuario']?.toString(),
      inner['rolNombre']?.toString(),
      userData['rol']?.toString(),
    ]);
    userId = _parseInt(
      inner['usuarioId'] ?? inner['id'] ?? inner['userId'] ??
      inner['identificador'] ?? userData['usuarioId'] ?? userData['id']
    );
  }

  static Map<String, dynamic> _deepFindUser(Map<String, dynamic> data) {
    for (final key in ['usuario', 'user', 'data', 'userData', 'profile', 'perfil']) {
      if (data[key] is Map) return data[key] as Map<String, dynamic>;
    }
    // If data has token/jwt but also email/rol at top, use data itself
    if (data['email'] != null || data['rol'] != null || data['correo'] != null) return data;
    // Last resort: check any nested map values
    for (final v in data.values) {
      if (v is Map<String, dynamic>) return v;
    }
    return data;
  }

  static String? _firstNonEmpty(List<String?> candidates) {
    for (final c in candidates) {
      if (c != null && c.isNotEmpty) return c;
    }
    return null;
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static void clear() {
    email = null;
    role = null;
    userId = null;
  }
}
