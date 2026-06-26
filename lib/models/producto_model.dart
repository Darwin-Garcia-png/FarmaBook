class Producto {
  final String productoId;
  final String? codigoBarras;
  final String nombre;
  final String? descripcion;
  final String? categoriaId;
  final String? presentacionId;
  final List<String>? proveedoresId;
  final int cantidadDisponible;
  final double precioPorUnidad;
  final String? imagenUrl;
  final String? dosisRecomendada;
  final DateTime? nearestExpiryDate;

  Producto({
    required this.productoId,
    this.codigoBarras,
    required this.nombre,
    this.descripcion,
    this.categoriaId,
    this.presentacionId,
    this.proveedoresId,
    required this.cantidadDisponible,
    this.precioPorUnidad = 0.0,
    this.imagenUrl,
    this.dosisRecomendada,
    this.nearestExpiryDate,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      productoId: json['productoId']?.toString() ?? '',
      codigoBarras: json['codigoBarras']?.toString(),
      nombre: json['nombre']?.toString() ?? 'Sin nombre',
      descripcion: json['descripcion']?.toString(),
      categoriaId: json['categoriaId']?.toString(),
      presentacionId: json['presentacionId']?.toString(),
      proveedoresId: json['proveedoresId'] != null
          ? (json['proveedoresId'] as List)
              .map((e) => e.toString())
              .toList()
          : null,
      cantidadDisponible:
          int.tryParse(json['cantidadDisponible']?.toString() ?? '0') ?? 0,
      precioPorUnidad: _parsePrice(json),
      imagenUrl: json['imagenUrl']?.toString(),
      dosisRecomendada: json['dosisRecomendada']?.toString(),
    );
  }

  static double _parsePrice(Map<String, dynamic> json) {
    for (final f in ['precioPorUnidad', 'precioVenta', 'precio_venta', 'pvp', 'precio_unidad', 'precioUnidad', 'precio', 'costoCompra', 'costoDeCompra', 'precioCompra']) {
      final v = json[f];
      if (v != null) {
        final p = double.tryParse(v.toString());
        if (p != null && p > 0) return p;
      }
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      if (productoId.isNotEmpty) 'productoId': productoId,
      if (codigoBarras != null) 'codigoBarras': codigoBarras,
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (categoriaId != null) 'categoriaId': categoriaId,
      if (presentacionId != null) 'presentacionId': presentacionId,
      if (proveedoresId != null) 'proveedoresId': proveedoresId,
      'cantidadDisponible': cantidadDisponible,
      'precioPorUnidad': precioPorUnidad,
      if (imagenUrl != null) 'imagenUrl': imagenUrl,
      if (dosisRecomendada != null) 'dosisRecomendada': dosisRecomendada,
      if (nearestExpiryDate != null) 'nearestExpiryDate': nearestExpiryDate!.toIso8601String(),
    };
  }
}
