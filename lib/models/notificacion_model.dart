class Notificacion {
  final String notificacionId;
  final String tipo;
  final String mensaje;
  final Map<String, dynamic>? payload;
  final DateTime? createdAt;

  Notificacion({
    required this.notificacionId,
    required this.tipo,
    required this.mensaje,
    this.payload,
    this.createdAt,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      notificacionId: json['notificacionId']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      mensaje: json['mensaje']?.toString() ?? '',
      payload: json['payload'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
