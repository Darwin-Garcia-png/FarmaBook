import 'package:flutter/material.dart';
import '../controllers/lotes_controller.dart';
import '../controllers/almacen_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_header.dart';
import '../utils/inventory_dialogs.dart';

class LotesScreen extends StatefulWidget {
  const LotesScreen({super.key});

  @override
  State<LotesScreen> createState() => _LotesScreenState();
}

class _LotesScreenState extends State<LotesScreen> with SingleTickerProviderStateMixin {
  final LotesController _lotesCtrl = LotesController();
  final AlmacenController _almacenCtrl = AlmacenController();
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _lotesCtrl.addListener(_onControllerChanged);
    _lotesCtrl.init();
    _almacenCtrl.init();
  }

  @override
  void dispose() {
    _lotesCtrl.removeListener(_onControllerChanged);
    _tabController.dispose();
    _searchCtrl.dispose();
    _lotesCtrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumHeader(
        title: 'Gestión de Lotes',
        subtitle: 'Control de caducidad y trazabilidad',
        icon: Icons.layers_outlined,
        baseColor: AppTheme.ayanamiBlue,
        trailing: ElevatedButton.icon(
          onPressed: () => InventoryDialogs.showAddEditProduct(context, _almacenCtrl, _lotesCtrl),
          icon: const Icon(Icons.add_box_rounded),
          label: const Text('Entrada de Lote', style: TextStyle(fontWeight: FontWeight.w900)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.ayanamiBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: AppTheme.ayanamiBlue.withOpacity(0.4),
          ),
        ),
      ),
      body: _lotesCtrl.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.ayanamiBlue))
          : Column(
              children: [
                _buildMetricsRow(_lotesCtrl),
                _buildSearchBar(context),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
                  ),
                  child: _buildTabs(context, _lotesCtrl),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBatchList(_lotesCtrl.allBatches, _almacenCtrl, _lotesCtrl),
                      _buildBatchList(_lotesCtrl.porVencer, _almacenCtrl, _lotesCtrl),
                      _buildBatchList(_lotesCtrl.vencidos, _almacenCtrl, _lotesCtrl),
                      _buildBatchList(_lotesCtrl.bajoStock, _almacenCtrl, _lotesCtrl),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMetricsRow(LotesController lotesCtrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
      child: Row(
        children: [
          Expanded(child: _buildMetricCard(title: 'TOTAL LOTES', value: lotesCtrl.allBatches.length.toString(), icon: Icons.inventory_2_rounded, color: AppTheme.ayanamiBlue)),
          const SizedBox(width: 20),
          Expanded(child: _buildMetricCard(title: 'EN RIESGO', value: lotesCtrl.porVencer.length.toString(), icon: Icons.warning_amber_rounded, color: Colors.orange)),
          const SizedBox(width: 20),
          Expanded(child: _buildMetricCard(title: 'VENCIDOS', value: lotesCtrl.vencidos.length.toString(), icon: Icons.error_outline_rounded, color: AppTheme.reiOrangeRed)),
        ],
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
              Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1, letterSpacing: -1)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Buscar por producto o nombre de lote...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.ayanamiBlue),
          filled: true,
          fillColor: Theme.of(context).cardTheme.color,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, LotesController lotesCtrl) {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      indicatorWeight: 4,
      indicatorSize: TabBarIndicatorSize.label,
      indicatorColor: AppTheme.ayanamiBlue,
      labelColor: AppTheme.ayanamiBlue,
      unselectedLabelColor: Colors.grey,
      labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
      tabs: [
        Tab(text: 'Todos (${lotesCtrl.allBatches.length})'),
        Tab(text: 'Por Vencer (${lotesCtrl.porVencer.length})'),
        Tab(text: 'Vencidos (${lotesCtrl.vencidos.length})'),
        Tab(text: 'Bajo Stock (${lotesCtrl.bajoStock.length})'),
      ],
    );
  }

  Widget _buildBatchList(List<Map<String, dynamic>> batches, AlmacenController almacenCtrl, LotesController lotesCtrl) {
    final query = _searchQuery.toLowerCase();
    final filtered = batches.where((b) {
      final name = b['nombreLote']?.toString().toLowerCase() ?? '';
      final prod = b['productoNombre']?.toString().toLowerCase() ?? '';
      return name.contains(query) || prod.contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No se encontraron registros', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => _buildBatchCard(filtered[i], almacenCtrl, lotesCtrl),
    );
  }

  Widget _buildBatchCard(Map<String, dynamic> b, AlmacenController almacenCtrl, LotesController lotesCtrl) {
    final expDate = DateTime.tryParse(b['fechaDeVencimiento']?.toString() ?? b['fechaVencimiento']?.toString() ?? '');
    final stock = int.tryParse(b['cantidadDisponible'].toString()) ?? 0;
    
    int daysLeft = 9999;
    if (expDate != null) daysLeft = expDate.difference(DateTime.now()).inDays;

    Color statusColor = AppTheme.greenMetal;
    String statusText = 'SALUDABLE';
    IconData statusIcon = Icons.verified_rounded;

    if (daysLeft < 0) {
      statusColor = AppTheme.reiOrangeRed;
      statusText = 'VENCIDO';
      statusIcon = Icons.error_rounded;
    } else if (daysLeft <= 60) {
      statusColor = Colors.orange;
      statusText = 'POR VENCER';
      statusIcon = Icons.warning_rounded;
    } else if (stock < 30) {
      statusColor = AppTheme.reiPurple;
      statusText = 'BAJO STOCK';
      statusIcon = Icons.trending_down_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 14),
                const SizedBox(width: 8),
                Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)),
                const Spacer(),
                Text('${b['productoNombre']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey), maxLines: 1),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b['nombreLote'] ?? 'Lote', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _badge(Icons.event_rounded, expDate == null ? 'N/A' : '${expDate.day}/${expDate.month}/${expDate.year}'),
                          const SizedBox(width: 12),
                          _badge(Icons.qr_code_rounded, 'SKU: ${b['productoCodigo'] ?? 'N/A'}'),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: AppTheme.ayanamiBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Text('$stock', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: stock < 30 ? AppTheme.reiPurple : AppTheme.ayanamiBlue, height: 1)),
                      const Text('UNDS', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    _actionIcon(Icons.edit_rounded, AppTheme.ayanamiBlue, () => InventoryDialogs.showAddEditProduct(context, almacenCtrl, lotesCtrl, prod: b['originalProduct'], prefillBatch: b)),
                    const SizedBox(height: 6),
                    _actionIcon(Icons.delete_outline_rounded, AppTheme.reiOrangeRed, () => _confirmDelete(b, lotesCtrl, almacenCtrl)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> b, LotesController lotesCtrl, AlmacenController almacenCtrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar Lote'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.reiOrangeRed, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      await lotesCtrl.deleteBatch(b['loteId']);
      almacenCtrl.init(); 
    }
  }
}
