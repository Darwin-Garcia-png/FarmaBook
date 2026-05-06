class Categoria {
  final String categoriaId;
  final String nombre;
  final String? descripcion;
  final bool activo;
  final DateTime? createdAt;

  Categoria({
    required this.categoriaId,
    required this.nombre,
    this.descripcion,
    this.activo = true,
    this.createdAt,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      categoriaId: json['categoriaId']?.toString() ?? '',
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
      if (categoriaId.isNotEmpty) 'categoriaId': categoriaId,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
    };
  }
}
