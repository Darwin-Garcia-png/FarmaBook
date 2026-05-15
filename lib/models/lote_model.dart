class Lote {
  final String batchId;
  final String productoId;
  final String nombreLote;
  final DateTime fechaDeVencimiento;
  final int cantidadDisponible;
  final double costoDeCompra;

  Lote({
    required this.batchId,
    required this.productoId,
    required this.nombreLote,
    required this.fechaDeVencimiento,
    required this.cantidadDisponible,
    required this.costoDeCompra,
  });

  factory Lote.fromJson(Map<String, dynamic> json) {
    return Lote(
      batchId: json['batchId']?.toString() ?? json['loteId']?.toString() ?? '',
      productoId: json['productoId']?.toString() ?? '',
      nombreLote: json['nombreLote']?.toString() ?? '',
      fechaDeVencimiento: json['fechaDeVencimiento'] != null
          ? DateTime.tryParse(json['fechaDeVencimiento'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      cantidadDisponible:
          int.tryParse(json['cantidadDisponible']?.toString() ?? '0') ?? 0,
      costoDeCompra:
          double.tryParse(json['costoDeCompra']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (batchId.isNotEmpty) 'batchId': batchId,
      'productoId': productoId,
      'nombreLote': nombreLote,
      'fechaDeVencimiento': fechaDeVencimiento.toIso8601String(),
      'cantidadDisponible': cantidadDisponible,
      'costoDeCompra': costoDeCompra,
    };
  }
}
