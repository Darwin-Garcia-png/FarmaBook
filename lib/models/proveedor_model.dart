class Proveedor {
  final String proveedorId;
  final String nombre;
  final String? direccion;
  final String? telefono;
  final String? email;
  final bool activo;
  final DateTime? createdAt;

  Proveedor({
    required this.proveedorId,
    required this.nombre,
    this.direccion,
    this.telefono,
    this.email,
    this.activo = true,
    this.createdAt,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      proveedorId: json['proveedorId']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      direccion: json['direccion']?.toString(),
      telefono: json['telefono']?.toString(),
      email: json['email']?.toString(),
      activo: json['activo'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (proveedorId.isNotEmpty) 'proveedorId': proveedorId,
      'nombre': nombre,
      if (direccion != null) 'direccion': direccion,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
    };
  }
}
