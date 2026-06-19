import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/ventas_controller.dart';
import '../widgets/ventas/cart_section.dart';
import '../widgets/ventas/sales_results_grid.dart';
import '../widgets/ventas/sales_search_section.dart';
import '../widgets/ventas/receipt_dialog.dart';
import '../widgets/premium_header.dart';
import '../widgets/error_display.dart';
import '../utils/price_formatter.dart';
import '../widgets/shimmer_loading.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final VentasController _controller = VentasController();

  @override
  void initState() {
    super.initState();
    _controller.touch();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VentasController>.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: PremiumHeader(
            title: 'Punto de Venta',
            subtitle: 'Atención y Cobro',
            icon: Icons.shopping_cart_rounded,
            baseColor: AppTheme.greenMetal,
            trailing: IconButton(
              icon: Icon(Icons.refresh_rounded, size: 20, color: AppTheme.greenMetal.withValues(alpha: 0.7)),
              onPressed: () => _controller.cargarHistorialVentas(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Row(
      children: [
        _buildSidebar(),
        Expanded(
          flex: 5,
          child: Consumer<VentasController>(
            builder: (context, controller, child) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  key: ValueKey(controller.vistaActual),
                  children: [
                    if (controller.vistaActual == VentasView.search) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(32, 32, 32, 16),
                        child: SalesSearchSection(),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: SalesResultsGrid(),
                        ),
                      ),
                    ] else if (controller.vistaActual == VentasView.history) ...[
                      _buildHeader(context, 'Historial de Ventas', Icons.history_edu_rounded),
                      Expanded(child: _buildSalesHistoryList(context, controller)),
                    ] else if (controller.vistaActual == VentasView.receipts) ...[
                      _buildHeader(context, 'Archivo de Comprobantes', Icons.receipt_long_rounded),
                      Expanded(child: _buildReceiptsCardsList(context, controller)),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        const CartSection(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.ayanamiBlue, size: 28),
          const SizedBox(width: 12),
          Text(title,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).textTheme.titleLarge?.color)),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Consumer<VentasController>(
      builder: (context, controller, child) {
        return Container(
          width: 100,
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 30,
                offset: const Offset(10, 0),
              )
            ],
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 32),
              _navButton(
                icon: Icons.add_shopping_cart_rounded,
                label: 'Vender',
                isSelected: controller.vistaActual == VentasView.search,
                onTap: () => controller.setVista(VentasView.search),
              ),
              _navButton(
                icon: Icons.history_rounded,
                label: 'Historial',
                isSelected: controller.vistaActual == VentasView.history,
                onTap: () => controller.setVista(VentasView.history),
              ),
              _navButton(
                icon: Icons.receipt_long_rounded,
                label: 'Recibos',
                isSelected: controller.vistaActual == VentasView.receipts,
                onTap: () => controller.setVista(VentasView.receipts),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 20),
                    const SizedBox(height: 12),
                    Text('v1.0', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _navButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.ayanamiBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected ? [
              BoxShadow(color: AppTheme.ayanamiBlue.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
            ] : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 28),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesHistoryList(BuildContext context, VentasController controller) {
    if (controller.isLoadingHistorial) return const ShimmerList(itemCount: 5, itemHeight: 90);
    if (controller.ventasHistorial.isEmpty) return const Center(child: Text('No hay ventas registradas', style: TextStyle(color: Colors.grey)));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: controller.ventasHistorial.length,
      separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor),
      itemBuilder: (context, index) {
        final sale = controller.ventasHistorial[index];
        return ListTile(
          onTap: () => _showReceipt(context, sale),
          leading: CircleAvatar(
              backgroundColor: AppTheme.ayanamiBlue.withValues(alpha: 0.1),
              child: const Icon(Icons.shopping_cart, color: AppTheme.ayanamiBlue)),
          title: Text('Venta #${sale['numeroFactura'] ?? sale['ventaId']}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatDate(_getSafeDate(sale))} ${_formatTime(_getSafeDate(sale))}',
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                _clienteDisplay(sale),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('\$${sale['total']}',
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.greenMetal)),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _confirmCancelSale(context, controller, sale),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppTheme.reiOrangeRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.cancel_outlined, size: 18, color: AppTheme.reiOrangeRed),
              ),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _confirmCancelSale(BuildContext context, VentasController controller, Map<String, dynamic> sale) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Anular Venta', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('¿Deseas anular la venta #${sale['numeroFactura'] ?? sale['ventaId']}?\nEl stock se restaurará automáticamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.reiOrangeRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Anular', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final saleId = sale['ventaId']?.toString() ?? sale['id']?.toString();
      if (saleId != null) {
        final ok = await controller.cancelSale(saleId);
        if (mounted) {
          if (ok) {
            ErrorDisplay.successSnackBar(context: context, message: 'Venta anulada correctamente');
          } else {
            ErrorDisplay.snackBar(context: context, message: controller.error ?? 'Error al anular');
          }
        }
      }
    }
  }

  Widget _buildReceiptsCardsList(BuildContext context, VentasController controller) {
    if (controller.isLoadingHistorial) return const ShimmerList(itemCount: 4, itemHeight: 200);
    if (controller.ventasHistorial.isEmpty) return const Center(child: Text('No hay recibos disponibles', style: TextStyle(color: Colors.grey)));

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: controller.ventasHistorial.length,
      itemBuilder: (context, index) {
        final sale = controller.ventasHistorial[index];
        return _buildReceiptCard(context, sale);
      },
    );
  }

  Widget _buildReceiptCard(BuildContext context, Map<String, dynamic> sale) {
    final productos = (sale['productosVendidos'] as List<dynamic>?) ??
        (sale['detalles'] as List<dynamic>?) ??
        (sale['items'] as List<dynamic>?) ??
        [];
    final total = double.tryParse(sale['total']?.toString() ?? '0') ?? 0.0;
    final fecha = _formatDate(_getSafeDate(sale));
    final numFactura = '#${sale['numeroFactura'] ?? sale['ventaId']}';

    return InkWell(
      onTap: () => _showReceipt(context, sale),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.ayanamiBlue.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.ayanamiBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: AppTheme.ayanamiBlue, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(numFactura,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 10, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(fecha, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(_clienteDisplay(sale),
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (productos.isNotEmpty)
                      ...productos.take(3).map((det) {
                        final d = det as Map<String, dynamic>;
                        final nom = d['nombre'] ?? d['nombreProducto'] ?? 'Prod';
                        final qty = d['cantidadDeUnidades'] ?? d['cantidad'] ?? 1;
                        final sub = double.tryParse(d['subTotal']?.toString() ?? d['precioTotal']?.toString() ?? '0') ?? 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Text('${qty}x ', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                              Expanded(child: Text(nom, style: TextStyle(fontSize: 10, color: Colors.grey.shade700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Text(formatCop(sub), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                            ],
                          ),
                        );
                      }),
                    if (productos.length > 3)
                      Text('+${productos.length - 3} más',
                        style: TextStyle(fontSize: 9, color: AppTheme.ayanamiBlue, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                  Text(formatCop(total),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.greenMetal)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReceipt(BuildContext context, Map<String, dynamic> sale) {
    showDialog(context: context, builder: (ctx) => ReceiptDialog(sale: sale));
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

  String _getSafeDate(Map<String, dynamic> json) {
    if (json.isEmpty) return DateTime.now().toIso8601String();
    final fields = ['fechaDeVenta', 'fechaVenta', 'fecha_venta', 'fecha', 'createdAt', 'created_at', 'date', 'updatedAt'];
    for(var f in fields) {
       if(json[f] != null && json[f].toString().isNotEmpty) return json[f].toString();
    }
    for (var value in json.values) {
      if (value is Map<String, dynamic>) {
        for (var f in fields) {
          if (value[f] != null && value[f].toString().isNotEmpty) return value[f].toString();
        }
      }
    }
    return "2000-01-01T00:00:00Z"; 
  }

  String _clienteDisplay(Map<String, dynamic> sale) {
    String get(String k) => sale[k]?.toString()?.trim() ?? '';
    final n = get('clienteNombre') ?? get('nombreCliente') ?? sale['cliente']?['nombre']?.toString()?.trim() ?? '';
    final id = get('clienteIdentificacion') ?? get('identificacionCliente') ?? sale['cliente']?['identificacion']?.toString()?.trim() ?? get('clienteId') ?? '';
    if (n.isNotEmpty && id.isNotEmpty) return 'Cliente: $n ($id)';
    if (n.isNotEmpty) return 'Cliente: $n';
    if (id.isNotEmpty) return 'Cliente: $id';
    return 'Cliente: Consumidor Final';
  }
}
