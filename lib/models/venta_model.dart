class ProductoVendido {
  final String productoId;
  final String nombre;
  final int cantidadDeUnidades;
  final double subTotal;

  ProductoVendido({
    required this.productoId,
    required this.nombre,
    required this.cantidadDeUnidades,
    required this.subTotal,
  });

  factory ProductoVendido.fromJson(Map<String, dynamic> json) {
    return ProductoVendido(
      productoId: json['productoId']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      cantidadDeUnidades:
          int.tryParse(json['cantidadDeUnidades']?.toString() ?? '0') ?? 0,
      subTotal: double.tryParse(json['subTotal']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class Venta {
  final String ventaId;
  final double total;
  final DateTime fechaDeVenta;
  final List<ProductoVendido> productosVendidos;
  final String? nombreConsumidor;

  Venta({
    required this.ventaId,
    required this.total,
    required this.fechaDeVenta,
    required this.productosVendidos,
    this.nombreConsumidor,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      ventaId: json['ventaId']?.toString() ?? '',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      fechaDeVenta: json['fechaDeVenta'] != null
          ? DateTime.tryParse(json['fechaDeVenta'].toString()) ?? DateTime.now()
          : DateTime.now(),
      productosVendidos: json['productosVendidos'] != null
          ? (json['productosVendidos'] as List)
              .map((e) => ProductoVendido.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      nombreConsumidor: json['nombreConsumidor']?.toString(),
    );
  }
}
