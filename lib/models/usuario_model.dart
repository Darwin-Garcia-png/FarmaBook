class Usuario {
  final String usuarioId;
  final String nombre;
  final bool activo;
  final String? rolId;
  final DateTime? createdAt;

  Usuario({
    required this.usuarioId,
    required this.nombre,
    this.activo = true,
    this.rolId,
    this.createdAt,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      usuarioId: json['usuarioId']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      activo: json['activo'] ?? true,
      rolId: json['rolId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
