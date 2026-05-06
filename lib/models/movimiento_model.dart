class Movimiento {
  final String cambioId;
  final String usuarioId;
  final String nombreUsuario;
  final String accion;
  final String entidad;
  final Map<String, dynamic>? payload;
  final DateTime? createdAt;

  Movimiento({
    required this.cambioId,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.accion,
    required this.entidad,
    this.payload,
    this.createdAt,
  });

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    return Movimiento(
      cambioId: json['cambioId']?.toString() ?? '',
      usuarioId: json['usuarioId']?.toString() ?? '',
      nombreUsuario: json['nombreUsuario']?.toString() ?? '',
      accion: json['accion']?.toString() ?? '',
      entidad: json['entidad']?.toString() ?? '',
      payload: json['payload'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
