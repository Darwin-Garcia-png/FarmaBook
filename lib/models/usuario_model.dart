class Usuario {
  final String usuarioId;
  final String nombre;
  final String email;
  final String rolNombre;
  final String? username;
  final bool activo;
  final DateTime? createdAt;

  Usuario({
    required this.usuarioId,
    required this.nombre,
    required this.email,
    required this.rolNombre,
    this.username,
    this.activo = true,
    this.createdAt,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      usuarioId: json['usuarioId']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      rolNombre: json['rolNombre']?.toString() ?? 'Personal',
      username: json['username']?.toString(),
      activo: json['activo'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
