import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/ventas_controller.dart';
import '../widgets/ventas/cart_section.dart';
import '../widgets/ventas/sales_results_grid.dart';
import '../widgets/ventas/sales_search_section.dart';
import '../widgets/ventas/receipt_dialog.dart';
import '../widgets/premium_header.dart';

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
    if (controller.isLoadingHistorial) return const Center(child: CircularProgressIndicator());
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
          trailing: Text('\$${sale['total']}',
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.greenMetal)),
        );
      },
    );
  }

  Widget _buildReceiptsCardsList(BuildContext context, VentasController controller) {
    if (controller.isLoadingHistorial) return const Center(child: CircularProgressIndicator());
    if (controller.ventasHistorial.isEmpty) return const Center(child: Text('No hay recibos disponibles', style: TextStyle(color: Colors.grey)));

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: controller.ventasHistorial.length,
      itemBuilder: (context, index) {
        final sale = controller.ventasHistorial[index];
        return InkWell(
          onTap: () => _showReceipt(context, sale),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.receipt, color: AppTheme.ayanamiBlue, size: 20),
                    Text('\$${sale['total']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.greenMetal)),
                  ],
                ),
                const Spacer(),
                Text('Factura #${sale['numeroFactura'] ?? sale['ventaId']}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color)),
                const SizedBox(height: 4),
                Text(_formatDate(_getSafeDate(sale)),
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text(
                  _clienteDisplay(sale),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
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
