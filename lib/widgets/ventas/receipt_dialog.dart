import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../theme/app_theme.dart';
import '../../utils/price_formatter.dart';
import '../error_display.dart';

class ReceiptDialog extends StatelessWidget {
  final Map<String, dynamic> sale;

  const ReceiptDialog({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
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
              const Icon(Icons.check_circle_outline,
                  color: AppTheme.greenMetal, size: 60),
              const SizedBox(height: 16),
              Text('FarmaBook',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.titleLarge?.color)),
              const Text('RECIBO DE VENTA',
                  style: TextStyle(
                      letterSpacing: 2, fontSize: 12, color: Colors.grey)),
              Divider(
                  height: 40,
                  thickness: 1,
                  color: Theme.of(context).dividerColor),
              _receiptRow(context, 'Factura #:', '#${sale['numeroFactura'] ?? sale['ventaId']}'),
              _receiptRow(context, 'Fecha:', _formatDate(_getSafeDate(sale))),
              _receiptRow(context, 'Hora:', _formatTime(_getSafeDate(sale))),
              _receiptRow(context, 'Cliente:', _clienteName()),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('PRODUCTOS',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color:
                            Theme.of(context).textTheme.titleLarge?.color)),
              ),
              const SizedBox(height: 12),
              ...((sale['productosVendidos'] as List<dynamic>?) ??
                      (sale['detalles'] as List<dynamic>?) ??
                      (sale['items'] as List<dynamic>?) ??
                      [])
                  .map((det) {
                final Map<String, dynamic> d = det as Map<String, dynamic>;
                final String nombre = d['nombre'] ??
                    d['producto']?['nombre'] ??
                    d['nombreProducto'] ??
                    d['productoNombre'] ??
                    'Producto';
                final String pres =
                    d['presentacion'] ?? d['producto']?['presentacion'] ?? '';
                final int qty = d['cantidadDeUnidades'] ?? d['cantidad'] ?? 1;
                final double price = double.tryParse(
                        d['subTotal']?.toString() ??
                            d['precioTotal']?.toString() ??
                            d['subtotal']?.toString() ??
                            '0') ??
                    0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${qty}x $nombre ${pres.isNotEmpty ? "($pres)" : ""}',
                          style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(formatCop(price),
                          style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color)),
                    ],
                  ),
                );
              }),
              Divider(
                  height: 40,
                  thickness: 2,
                  color: Theme.of(context).dividerColor),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color:
                              Theme.of(context).textTheme.titleLarge?.color)),
                  Text(
                      formatCop(double.tryParse(sale['total']?.toString() ?? '0') ?? 0.0),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: AppTheme.greenMetal)),
                ],
              ),
              const SizedBox(height: 40),
              const Text('Gracias por su compra!',
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey)),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
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

  String _getClienteNombre() {
    final v = sale['clienteNombre']?.toString() ??
        sale['nombreCliente']?.toString() ??
        sale['cliente']?['nombre']?.toString() ??
        sale['cliente']?['nombreCompleto']?.toString() ??
        sale['cliente']?['razonSocial']?.toString() ??
        sale['cliente_nombre']?.toString() ??
        sale['nombre']?.toString() ??
        sale['clienteName']?.toString() ??
        '';
    return v.trim();
  }

  String _getClienteIdentificacion() {
    final v = sale['clienteIdentificacion']?.toString() ??
        sale['identificacionCliente']?.toString() ??
        sale['cliente']?['identificacion']?.toString() ??
        sale['cliente']?['cedula']?.toString() ??
        sale['cliente']?['ruc']?.toString() ??
        sale['clienteId']?.toString() ??
        sale['cliente_id']?.toString() ??
        sale['cedulaCliente']?.toString() ??
        sale['clienteCedula']?.toString() ??
        sale['idCliente']?.toString() ??
        '';
    return v.trim();
  }

  String _clienteName() {
    final n = _getClienteNombre();
    final id = _getClienteIdentificacion();
    if (n.isNotEmpty && id.isNotEmpty) return '$n ($id)';
    if (n.isNotEmpty) return n;
    if (id.isNotEmpty) return id;
    return '\u2014';
  }

  String _clienteId() {
    return '';
  }

  Future<void> _printTicket(BuildContext context) async {
    final productos = (sale['productosVendidos'] as List<dynamic>?) ??
        (sale['detalles'] as List<dynamic>?) ??
        (sale['items'] as List<dynamic>?) ??
        [];

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll57.copyWith(marginBottom: 0, marginLeft: 3, marginRight: 3, marginTop: 0),
          build: (ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Center(
                  child: pw.Text('FarmaBook',
                      style: pw.TextStyle(
                          fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text('RECIBO DE VENTA',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.black)),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1, color: PdfColors.black),
                pw.SizedBox(height: 8),
                _receiptPdfRow('Factura #:', '#${sale['numeroFactura'] ?? sale['ventaId']}'),
                _receiptPdfRow('Fecha:', _formatDate(_getSafeDate(sale))),
                _receiptPdfRow('Hora:', _formatTime(_getSafeDate(sale))),
                _receiptPdfRow('Cliente:', _clienteName()),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1, color: PdfColors.black),
                pw.SizedBox(height: 6),
                pw.Text('PRODUCTOS',
                    style: pw.TextStyle(
                        fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.SizedBox(height: 6),
                ...productos.map((det) {
                  final d = det as Map<String, dynamic>;
                  final nombre = d['nombre'] ??
                      d['producto']?['nombre'] ??
                      d['nombreProducto'] ??
                      'Producto';
                  final qty = d['cantidadDeUnidades'] ?? d['cantidad'] ?? 1;
                  final price = double.tryParse(
                          d['subTotal']?.toString() ??
                              d['precioTotal']?.toString() ??
                              '0') ??
                      0.0;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text('$qty $nombre',
                              style: pw.TextStyle(fontSize: 8, color: PdfColors.black),
                              maxLines: 2),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text(formatCop(price),
                            style: pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                      ],
                    ),
                  );
                }),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 2, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL',
                        style: pw.TextStyle(
                            fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    pw.Text(
                        formatCop(double.tryParse(sale['total']?.toString() ?? '0') ?? 0.0),
                        style: pw.TextStyle(
                            fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Center(
                  child: pw.Text('Gracias por su compra!',
                      style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.black)),
                ),
                pw.SizedBox(height: 24),
                pw.Center(
                  child: pw.Text(
                      'Generado: ${DateTime.now().toString().substring(0, 16)}',
                      style: pw.TextStyle(fontSize: 6, color: PdfColors.black)),
                ),
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
          pw.Text(label,
              style: pw.TextStyle(fontSize: 8, color: PdfColors.black)),
          pw.Text(value,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ],
      ),
    );
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
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }

  String _getSafeDate(Map<String, dynamic> json) {
    if (json.isEmpty) return DateTime.now().toIso8601String();
    final fields = ['fechaDeVenta', 'fechaVenta', 'fecha_venta', 'fecha', 'createdAt', 'created_at', 'date', 'updatedAt'];
    for(var f in fields) {
       if(json[f] != null && json[f].toString().isNotEmpty) {
           return json[f].toString();
       }
    }
    return DateTime.now().toIso8601String();
  }
}
