class Presentacion {
  final String presentacionId;
  final String nombre;
  final String? descripcion;
  final bool activo;
  final DateTime? createdAt;

  Presentacion({
    required this.presentacionId,
    required this.nombre,
    this.descripcion,
    this.activo = true,
    this.createdAt,
  });

  factory Presentacion.fromJson(Map<String, dynamic> json) {
    return Presentacion(
      presentacionId: json['presentacionId']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      activo: json['activo'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (presentacionId.isNotEmpty) 'presentacionId': presentacionId,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
    };
  }
}
