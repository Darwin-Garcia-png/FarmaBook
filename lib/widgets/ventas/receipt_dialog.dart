import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../theme/app_theme.dart';
import '../../utils/price_formatter.dart';
import '../error_display.dart';

const _nit = 'NIT: 900.123.456-7';

class ReceiptDialog extends StatelessWidget {
  final Map<String, dynamic> sale;
  final String direccion;
  final String telefono;

  const ReceiptDialog({super.key, required this.sale, this.direccion = 'SENA', this.telefono = '3101234567'});

  @override
  Widget build(BuildContext context) {
    final productos = _getProductos();
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 20)],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.black, size: 60),
              const SizedBox(height: 16),
              const Text('FarmaBook', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
              const Text(_nit, style: TextStyle(fontSize: 11, color: Colors.black54)),
              const SizedBox(height: 4),
              const Text('RECIBO DE VENTA', style: TextStyle(letterSpacing: 2, fontSize: 12, color: Colors.black)),
              const Divider(height: 32, thickness: 1, color: Colors.black),
              _receiptRow(context, 'Factura #:', '#${sale['numeroFactura'] ?? sale['ventaId']}'),
              _receiptRow(context, 'Fecha:', _formatDate(_getSafeDate(sale))),
              _receiptRow(context, 'Hora:', _formatTime(_getSafeDate(sale))),
              _receiptRow(context, 'Cliente:', _clienteName()),
              const Divider(height: 16, thickness: 1, color: Colors.black),
              const Text('FARMACIA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54, letterSpacing: 2)),
              const SizedBox(height: 4),
              _receiptRow(context, 'Dirección:', direccion),
              _receiptRow(context, 'Teléfono:', telefono),
              const Divider(height: 16, thickness: 1, color: Colors.black),
              ...productos.map((det) {
                final d = det as Map<String, dynamic>;
                final String nombre = d['nombre'] ?? 'Producto';
                final String pres = d['presentacion']?.toString() ?? '';
                final int qty = d['cantidadDeUnidades'] ?? d['cantidad'] ?? 1;
                final double unitPrice = _getUnitPrice(d);
                final double total = double.tryParse(d['subTotal']?.toString() ?? d['precioTotal']?.toString() ?? '0') ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                          Text(formatCop(unitPrice), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Cant: $qty', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                          Text(formatCop(total), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 32, thickness: 2, color: Colors.black),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
                  Text(formatCop(double.tryParse(sale['total']?.toString() ?? '0') ?? 0),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black)),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Gracias por su compra!', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black)),
              const SizedBox(height: 12),
              Text('Los medicamentos no tienen cambio ni devolución\npor disposición sanitaria.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: Colors.grey[600])),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _printTicket(context),
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('IMPRIMIR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.ayanamiBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.grey.shade800,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('CERRAR'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<dynamic> _getProductos() {
    return (sale['productosVendidos'] as List<dynamic>?) ??
        (sale['detalles'] as List<dynamic>?) ??
        (sale['items'] as List<dynamic>?) ??
        [];
  }

  String _cajero() => sale['cajero']?.toString() ?? '\u2014';

  String _getClienteNombre() {
    return (sale['clienteNombre']?.toString() ??
        sale['nombreCliente']?.toString() ??
        sale['cliente']?['nombre']?.toString() ??
        sale['cliente']?['nombreCompleto']?.toString() ??
        sale['cliente']?['razonSocial']?.toString() ??
        sale['cliente_nombre']?.toString() ??
        sale['nombre']?.toString() ??
        sale['clienteName']?.toString() ??
        '').trim();
  }

  String _getClienteIdentificacion() {
    return (sale['clienteIdentificacion']?.toString() ??
        sale['identificacionCliente']?.toString() ??
        sale['cliente']?['identificacion']?.toString() ??
        sale['cliente']?['cedula']?.toString() ??
        sale['cliente']?['ruc']?.toString() ??
        sale['clienteId']?.toString() ??
        sale['cliente_id']?.toString() ??
        sale['cedulaCliente']?.toString() ??
        sale['clienteCedula']?.toString() ??
        sale['idCliente']?.toString() ??
        '').trim();
  }

  String _clienteName({bool maskId = false}) {
    final n = _getClienteNombre();
    String id = _getClienteIdentificacion();
    if (maskId && id.length > 4) {
      id = '${'*' * 4}${id.substring(4)}';
    }
    if (n.isNotEmpty && id.isNotEmpty) return '$n ($id)';
    if (n.isNotEmpty) return n;
    if (id.isNotEmpty) return id;
    return '\u2014';
  }

  Future<void> _printTicket(BuildContext context) async {
    final productos = _getProductos();

    try {
      final pdf = pw.Document();

      Uint8List? logoBytes;
      try {
        final data = await rootBundle.load('assets/images/logo_base.png');
        logoBytes = data.buffer.asUint8List();
      } catch (_) {
        try {
          final file = File('assets/images/logo_base.png');
          if (file.existsSync()) logoBytes = await file.readAsBytes();
        } catch (_) {}
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80.copyWith(marginBottom: 0, marginLeft: 4, marginRight: 4, marginTop: 0),
          build: (ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                if (logoBytes != null)
                  pw.Image(pw.MemoryImage(logoBytes), width: 50, height: 50),
                pw.SizedBox(height: 4),
                pw.Text('FarmaBook', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.Text(_nit, style: pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                pw.SizedBox(height: 2),
                pw.Text('RECIBO DE VENTA', style: pw.TextStyle(fontSize: 9, color: PdfColors.black)),
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 1, color: PdfColors.black),
                pw.SizedBox(height: 6),
                _receiptPdfRow('Factura #:', '#${sale['numeroFactura'] ?? sale['ventaId']}'),
                _receiptPdfRow('Fecha:', _formatDate(_getSafeDate(sale))),
                _receiptPdfRow('Hora:', _formatTime(_getSafeDate(sale))),
                _receiptPdfRow('Cliente:', _clienteName(maskId: true)),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 1, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Text('FARMACIA', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey, letterSpacing: 2)),
                pw.SizedBox(height: 2),
                _receiptPdfRow('Dirección:', direccion),
                _receiptPdfRow('Teléfono:', telefono),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 1, color: PdfColors.black),
                pw.SizedBox(height: 6),
                pw.Text('PRODUCTOS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.SizedBox(height: 4),
                ...productos.map((det) {
                  final d = det as Map<String, dynamic>;
                  final nombre = d['nombre'] ?? 'Producto';
                  final pres = d['presentacion']?.toString() ?? '';
                  final qty = d['cantidadDeUnidades'] ?? d['cantidad'] ?? 1;
                  final unitPrice = _getUnitPrice(d);
                  final total = double.tryParse(d['subTotal']?.toString() ?? d['precioTotal']?.toString() ?? '0') ?? 0;
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(nombre, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                          pw.Text(formatCop(unitPrice), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Cant: $qty',
                              style: pw.TextStyle(fontSize: 7, color: PdfColors.black)),
                          pw.Text(formatCop(total),
                              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                    ],
                  );
                }),
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 2, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    pw.Text(formatCop(double.tryParse(sale['total']?.toString() ?? '0') ?? 0),
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Text('Gracias por su compra!',
                    style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.black)),
                pw.SizedBox(height: 8),
                pw.Center(child: pw.Text('Los medicamentos no tienen cambio ni devolucion',
                    style: pw.TextStyle(fontSize: 6, color: PdfColors.grey))),
                pw.Center(child: pw.Text('por disposicion sanitaria.',
                    style: pw.TextStyle(fontSize: 6, color: PdfColors.grey))),
                pw.SizedBox(height: 24),
                pw.Text('Generado: ${DateTime.now().toString().substring(0, 16)}',
                    style: pw.TextStyle(fontSize: 6, color: PdfColors.black)),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'recibo_${sale['ventaId']}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ErrorDisplay.snackBar(context: context, message: ErrorDisplay.cleanMessage(e));
      }
    }
  }

  pw.Widget _receiptPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.black)),
          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
          ),
        ],
      ),
    );
  }

  double _getUnitPrice(Map<String, dynamic> d) {
    for (final f in ['precioVenta', 'precioPorUnidad', 'precioUnitario', 'precio', 'precio_unitario', 'pvp']) {
      final v = double.tryParse((d[f] ?? '').toString());
      if (v != null && v > 0) return v;
    }
    final qty = d['cantidadDeUnidades'] ?? d['cantidad'] ?? 1;
    final total = double.tryParse(d['subTotal']?.toString() ?? d['precioTotal']?.toString() ?? '0') ?? 0;
    if (qty > 0 && total > 0) return total / qty;
    return 0;
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      try {
        final s = dateStr.toString();
        if (s.contains('T')) return s.split('T')[0];
        return s.split(' ')[0];
      } catch (__) { return 'N/A'; }
    }
  }

  String _formatTime(dynamic dateStr) {
    if (dateStr == null || dateStr.toString().isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      try {
        final s = dateStr.toString();
        if (s.contains('T')) return s.split('T')[1].substring(0, 5);
        if (s.contains(' ')) return s.split(' ')[1].substring(0, 5);
      } catch (__) { return 'N/A'; }
    }
    return 'N/A';
  }

  Widget _receiptRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
        ],
      ),
    );
  }

  String _getSafeDate(Map<String, dynamic> json) {
    if (json.isEmpty) return DateTime.now().toIso8601String();
    final fields = ['fechaDeVenta', 'fechaVenta', 'fecha_venta', 'fecha', 'createdAt', 'created_at', 'date', 'updatedAt'];
    for(var f in fields) {
       if(json[f] != null && json[f].toString().isNotEmpty) return json[f].toString();
    }
    return DateTime.now().toIso8601String();
  }
}
