import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/lotes_controller.dart';
import '../controllers/almacen_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_header.dart';
import '../widgets/shimmer_loading.dart';
import '../utils/price_formatter.dart';
import '../utils/user_session.dart';
import '../widgets/animations.dart';
import '../widgets/error_display.dart';

class LotesScreen extends StatefulWidget {
  const LotesScreen({super.key});

  @override
  State<LotesScreen> createState() => _LotesScreenState();
}

class _LotesScreenState extends State<LotesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _showFilters = false;

  String? _filterProductoId;
  DateTime? _filterDesde;
  DateTime? _filterHasta;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final lotesCtrl = context.read<LotesController>();
        lotesCtrl.touch();
        lotesCtrl.ensureLoaded();
        // Safety: force stop loading after 30s
        Future.delayed(const Duration(seconds: 30), () {
          if (mounted && lotesCtrl.isLoading) {
            lotesCtrl.isLoading = false;
            lotesCtrl.notifyListeners();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LotesController, AlmacenController>(
      builder: (context, lotesCtrl, almacenCtrl, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PremiumHeader(
            title: 'Gestión de Lotes',
            subtitle: 'Control de caducidad y trazabilidad',
            icon: Icons.layers_outlined,
            baseColor: AppTheme.ayanamiBlue,
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, size: 20, color: AppTheme.ayanamiBlue.withValues(alpha: 0.7)),
                onPressed: () => lotesCtrl.refresh(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showAddBatch(almacenCtrl, lotesCtrl),
                icon: const Icon(Icons.add_box_rounded),
                label: const Text('Nuevo Lote', style: TextStyle(fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.ayanamiBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  shadowColor: AppTheme.ayanamiBlue.withValues(alpha: 0.4),
                ),
              ),
            ]),
          ),
          body: lotesCtrl.isLoading
              ? const ShimmerList(itemCount: 6, itemHeight: 90)
              : Column(
                  children: [
                    _buildMetricsRow(lotesCtrl),
                    _buildSearchBar(context, lotesCtrl),
                    if (_showFilters) _buildFilterPanel(context, lotesCtrl, almacenCtrl),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
                      ),
                      child: _buildTabs(context, lotesCtrl),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (!lotesCtrl.isFetchingMore &&
                                  scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                                lotesCtrl.fetchAllBatches(isRefresh: false);
                              }
                              return false;
                            },
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildBatchList(lotesCtrl.saludables, almacenCtrl, lotesCtrl),
                                _buildEnRiesgoList(lotesCtrl, almacenCtrl),
                                _buildArchivedList(lotesCtrl.archivedBatches, lotesCtrl, almacenCtrl),
                              ],
                            ),
                          ),
                          if (lotesCtrl.isFetchingMore)
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardTheme.color,
                                    shape: BoxShape.circle,
                                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                                  ),
                                  child: const CircularProgressIndicator(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
          );
      },
    );
  }

  Widget _buildMetricsRow(LotesController lotesCtrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
      child: Row(
        children: [
          Expanded(child: AnimatedEntry(index: 0, child: _buildMetricCard(title: 'LOTES ACTIVOS', value: lotesCtrl.saludables.length.toString(), icon: Icons.inventory_2_rounded, color: AppTheme.ayanamiBlue))),
          const SizedBox(width: 20),
          Expanded(child: AnimatedEntry(index: 1, child: _buildMetricCard(title: 'EN RIESGO', value: lotesCtrl.enRiesgo.length.toString(), icon: Icons.warning_amber_rounded, color: Colors.orange))),
          const SizedBox(width: 20),
          Expanded(child: AnimatedEntry(index: 2, child: _buildMetricCard(title: 'HISTORIAL', value: lotesCtrl.archivedBatches.length.toString(), icon: Icons.archive_rounded, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return HoverScale(
      scale: 1.015,
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: color.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.03), blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
                Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1, letterSpacing: -1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, LotesController lotesCtrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Buscar por producto, lote, SKU o código de barras...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.ayanamiBlue),
          suffixIcon: IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list_rounded,
              color: lotesCtrl.filtersActive ? AppTheme.reiOrangeRed : Colors.grey,
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          filled: true,
          fillColor: Theme.of(context).cardTheme.color,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context, LotesController lotesCtrl, AlmacenController almacenCtrl) {
    final productos = almacenCtrl.productos;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.ayanamiBlue.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_alt_rounded, size: 16, color: AppTheme.ayanamiBlue),
                const SizedBox(width: 8),
                Text('FILTROS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.grey.shade500)),
                const Spacer(),
                if (lotesCtrl.filtersActive)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterProductoId = null;
                        _filterDesde = null;
                        _filterHasta = null;
                      });
                      lotesCtrl.clearFilters();
                    },
                    child: const Text('Limpiar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Producto',
                labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              value: _filterProductoId,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos los productos', style: TextStyle(fontSize: 13))),
                ...productos.map((p) => DropdownMenuItem(
                  value: p['productoId'].toString(),
                  child: Text(p['nombre']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                )),
              ],
              onChanged: (v) => _filterProductoId = v,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(context, 'Vence desde', _filterDesde, (d) => _filterDesde = d),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateButton(context, 'Vence hasta', _filterHasta, (d) => _filterHasta = d),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  lotesCtrl.applyFilters(
                    productoId: _filterProductoId,
                    vencidosDesde: _filterDesde,
                    vencidosHasta: _filterHasta,
                  );
                  setState(() => _showFilters = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.ayanamiBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Aplicar Filtros', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(BuildContext context, String label, DateTime? value, ValueChanged<DateTime?> onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null ? '${value.day}/${value.month}/${value.year}' : label,
                style: TextStyle(fontSize: 12, color: value != null ? Colors.white : Colors.grey.shade500),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(Icons.close, size: 14, color: Colors.grey.shade500),
              ),
          ],
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
        Tab(text: 'Activos (${lotesCtrl.saludables.length})'),
        Tab(text: 'En Riesgo (${lotesCtrl.enRiesgo.length})'),
        Tab(text: 'Historial (${lotesCtrl.archivedBatches.length})'),
      ],
    );
  }

  Widget _buildBatchList(List<Map<String, dynamic>> batches, AlmacenController almacenCtrl, LotesController lotesCtrl) {
    final query = _searchQuery.toLowerCase();
    final filtered = batches.where((b) {
      final name = b['nombreLote']?.toString().toLowerCase() ?? '';
      final prod = b['productoNombre']?.toString().toLowerCase() ?? '';
      final sku = b['productoCodigo']?.toString().toLowerCase() ?? '';
      final bc = _batchBarcode(b)?.toLowerCase() ?? '';
      return name.contains(query) || prod.contains(query) || sku.contains(query) || bc.contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No se encontraron registros', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => AnimatedEntry(
        index: i,
        child: _buildBatchCard(filtered[i], almacenCtrl, lotesCtrl),
      ),
    );
  }

  Widget _buildEnRiesgoList(LotesController lotesCtrl, AlmacenController almacenCtrl) {
    final query = _searchQuery.toLowerCase();
    final seen = <String>{};
    final combined = <Map<String, dynamic>>[];
    for (final b in [...lotesCtrl.enRiesgo]) {
      final id = '${b['loteId'] ?? b['batchId'] ?? b['id'] ?? ''}';
      if (seen.add(id)) combined.add(b);
    }
    final filtered = combined.where((b) {
      final name = b['nombreLote']?.toString().toLowerCase() ?? '';
      final prod = b['productoNombre']?.toString().toLowerCase() ?? '';
      final sku = b['productoCodigo']?.toString().toLowerCase() ?? '';
      final bc = _batchBarcode(b)?.toLowerCase() ?? '';
      return name.contains(query) || prod.contains(query) || sku.contains(query) || bc.contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('Ningún lote en riesgo', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => AnimatedEntry(
        index: i,
        child: _buildBatchCard(filtered[i], almacenCtrl, lotesCtrl),
      ),
    );
  }

  Widget _buildArchivedList(List<Map<String, dynamic>> batches, LotesController lotesCtrl, AlmacenController almacenCtrl) {
    final query = _searchQuery.toLowerCase();
    final filtered = batches.where((b) {
      final name = b['nombreLote']?.toString().toLowerCase() ?? '';
      final prod = b['productoNombre']?.toString().toLowerCase() ?? '';
      final sku = b['productoCodigo']?.toString().toLowerCase() ?? '';
      final bc = _batchBarcode(b)?.toLowerCase() ?? '';
      return name.contains(query) || prod.contains(query) || sku.contains(query) || bc.contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No hay lotes en el historial', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => AnimatedEntry(
        index: i,
        child: _buildArchivedCard(filtered[i], lotesCtrl, almacenCtrl),
      ),
    );
  }

  Widget _buildArchivedCard(Map<String, dynamic> b, LotesController lotesCtrl, AlmacenController almacenCtrl) {
    final expDate = DateTime.tryParse(b['fechaDeVencimiento']?.toString() ?? b['fechaVencimiento']?.toString() ?? '');
    final stock = int.tryParse(b['cantidadDisponible'].toString()) ?? 0;
    final precio = _batchPrice(b);
    final codigoBarras = _batchBarcode(b);
    final isExpired = expDate != null && expDate.isBefore(DateTime.now());

    String archiveReason = 'ARCHIVADO';
    Color archiveColor = Colors.grey;
    if (stock <= 0) {
      archiveReason = 'SIN STOCK';
      archiveColor = AppTheme.reiPurple;
    } else if (isExpired) {
      archiveReason = 'VENCIDO';
      archiveColor = AppTheme.reiOrangeRed;
    }

    return HoverScale(
      scale: 1.01,
      elevation: 4,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))],
        ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: archiveColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Icon(Icons.archive_rounded, color: archiveColor, size: 14),
                const SizedBox(width: 8),
                Text(archiveReason, style: TextStyle(color: archiveColor, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)),
                const Spacer(),
                Text('${b['productoNombre']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey), maxLines: 1),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b['nombreLote'] ?? 'Lote', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              _badge(Icons.event_rounded, expDate == null ? 'N/A' : '${expDate.day}/${expDate.month}/${expDate.year}'),
                              _badge(Icons.qr_code_rounded, 'SKU: ${b['productoCodigo'] ?? 'N/A'}'),
                              if (codigoBarras != null)
                                _badge(Icons.apps_rounded, 'EAN: $codigoBarras'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: archiveColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Text('$stock', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: archiveColor, height: 1)),
                          const Text('UNDS', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ],
                      ),
                    ),
                    if (UserSession.isDueno) ...[
                      const SizedBox(width: 8),
                      if (!isExpired) ...[
                        _actionIcon(Icons.edit_rounded, AppTheme.ayanamiBlue, () => _showBatchEdit(b, lotesCtrl)),
                        const SizedBox(width: 8),
                      ],
                      if (!isExpired)
                        _actionIcon(
                          Icons.replay_rounded, AppTheme.greenMetal,
                          () => _confirmReactivate(b, lotesCtrl, almacenCtrl),
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.ayanamiBlue.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.ayanamiBlue.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_money_rounded, color: AppTheme.ayanamiBlue, size: 18),
                      const SizedBox(width: 8),
                      Text('Precio histórico:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text(formatCop(precio), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.ayanamiBlue, letterSpacing: -0.5)),
                      const Spacer(),
                      Text('Lote #${b['loteId'] ?? b['batchId'] ?? b['id'] ?? 'N/A'}', style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildBatchCard(Map<String, dynamic> b, AlmacenController almacenCtrl, LotesController lotesCtrl) {
    final expDate = DateTime.tryParse(b['fechaDeVencimiento']?.toString() ?? b['fechaVencimiento']?.toString() ?? '');
    final stock = int.tryParse(b['cantidadDisponible'].toString()) ?? 0;
    final precio = _batchPrice(b);
    final codigoBarras = _batchBarcode(b);
    
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

    return HoverScale(
      scale: 1.01,
      elevation: 4,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))],
        ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b['nombreLote'] ?? 'Lote', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              _badge(Icons.event_rounded, expDate == null ? 'N/A' : '${expDate.day}/${expDate.month}/${expDate.year}'),
                              _badge(Icons.qr_code_rounded, 'SKU: ${b['productoCodigo'] ?? 'N/A'}'),
                              if (codigoBarras != null)
                                _badge(Icons.apps_rounded, 'EAN: $codigoBarras'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: AppTheme.ayanamiBlue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
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
                        _actionIcon(Icons.edit_rounded, AppTheme.ayanamiBlue, () => _showBatchEdit(b, lotesCtrl)),
                        const SizedBox(height: 6),
                        _actionIcon(Icons.toggle_off_outlined, Colors.orange, () => _confirmDeactivate(b, lotesCtrl, almacenCtrl)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.ayanamiBlue.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.ayanamiBlue.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_money_rounded, color: AppTheme.ayanamiBlue, size: 18),
                      const SizedBox(width: 8),
                      Text('Precio histórico:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text(formatCop(precio), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.ayanamiBlue, letterSpacing: -0.5)),
                      const Spacer(),
                      Text('Lote #${b['loteId'] ?? b['batchId'] ?? b['id'] ?? 'N/A'}', style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
    );
  }

  Future<void> _confirmDeactivate(Map<String, dynamic> b, LotesController lotesCtrl, AlmacenController almacenCtrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Desactivar Lote'),
        content: const Text('Se pondrá el stock a 0. El lote pasará al historial. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), onPressed: () => Navigator.pop(ctx, true), child: const Text('Desactivar')),
        ],
      ),
    );
    if (confirm == true) {
      await lotesCtrl.deactivateBatch(b['loteId'] ?? b['batchId'] ?? b['id']);
      almacenCtrl.init();
    }
  }

  Future<void> _confirmReactivate(Map<String, dynamic> b, LotesController lotesCtrl, AlmacenController almacenCtrl) async {
    final id = b['loteId'] ?? b['batchId'] ?? b['id'] ?? '';
    final savedStock = lotesCtrl.getOriginalStock(id);

    if (savedStock != null && savedStock > 0) {
      await _doReactivate(context, id, savedStock, lotesCtrl, almacenCtrl);
      return;
    }

    // If original stock not saved (app restart), prompt user
    final stockCtrl = TextEditingController();
    final stock = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reactivar Lote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Stock original desconocido. Ingrese la cantidad a reactivar:'),
            const SizedBox(height: 12),
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock a reactivar',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenMetal, foregroundColor: Colors.white),
            onPressed: () {
              final v = int.tryParse(stockCtrl.text.trim());
              if (v == null || v <= 0) return;
              Navigator.pop(ctx, v);
            },
            child: const Text('Reactivar'),
          ),
        ],
      ),
    );
    stockCtrl.dispose();
    if (stock != null && stock > 0) {
      await _doReactivate(context, id, stock, lotesCtrl, almacenCtrl);
    }
  }

  Future<void> _doReactivate(BuildContext context, String id, int stock, LotesController lotesCtrl, AlmacenController almacenCtrl) async {
    try {
      await lotesCtrl.reactivateBatch(id, customStock: stock);
      almacenCtrl.init();
      if (context.mounted) {
        ErrorDisplay.successSnackBar(context: context, message: 'Lote reactivado exitosamente.');
      }
    } catch (e) {
      if (context.mounted) {
        ErrorDisplay.snackBar(context: context, message: ErrorDisplay.cleanMessage(e));
      }
    }
  }

  Future<void> _showBatchEdit(Map<String, dynamic> batch, LotesController lotesCtrl) async {
    final id = batch['loteId'] ?? batch['batchId'] ?? batch['id'];
    final nameCtrl = TextEditingController(text: batch['nombreLote']?.toString() ?? '');
    final stockCtrl = TextEditingController(text: batch['cantidadDisponible']?.toString() ?? '0');
    final priceCtrl = TextEditingController(text: _batchPrice(batch) > 0 ? _batchPrice(batch).toStringAsFixed(2) : '');
    final costCtrl = TextEditingController(text: (batch['costoCompra'] ?? batch['costoDeCompra'] ?? '').toString());
    DateTime? expDate = DateTime.tryParse(batch['fechaDeVencimiento']?.toString() ?? batch['fechaVencimiento']?.toString() ?? '');
    final fnName = FocusNode();
    final fnPrice = FocusNode();
    final fnCost = FocusNode();
    final fnStock = FocusNode();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.ayanamiBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_rounded, color: AppTheme.ayanamiBlue, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Text('Editar Lote', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.grey.shade400),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Producto: ${batch['productoNombre'] ?? 'N/A'}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                _field('Nombre del Lote', nameCtrl, Icons.tag_rounded, fnName, TextInputAction.next, () => fnPrice.requestFocus()),
                Row(children: [
                  Expanded(child: _field('Precio Venta', priceCtrl, Icons.sell_rounded, fnPrice, TextInputAction.next, () => fnCost.requestFocus(), keyboard: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Costo Compra', costCtrl, Icons.shopping_cart_rounded, fnCost, TextInputAction.next, () => fnStock.requestFocus(), keyboard: TextInputType.number)),
                ]),
                Row(children: [
                  Expanded(child: _field('Stock', stockCtrl, Icons.warehouse_rounded, fnStock, TextInputAction.done, null, keyboard: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final dt = await showDatePicker(
                          context: ctx,
                          initialDate: expDate ?? DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (dt != null) setD(() => expDate = dt);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.ayanamiBlue.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.ayanamiBlue.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.ayanamiBlue),
                            const SizedBox(width: 8),
                            Text(
                              expDate != null ? '${expDate!.day}/${expDate!.month}/${expDate!.year}' : 'Fecha vencimiento',
                              style: TextStyle(fontSize: 13, color: expDate != null ? Colors.black87 : Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.ayanamiBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final data = <String, dynamic>{
                          'nombreLote': nameCtrl.text.trim(),
                          'precioPorUnidad': double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0.0,
                          'costoDeCompra': double.tryParse(costCtrl.text.replaceAll(',', '.')) ?? 0.0,
                          'cantidadDisponible': int.tryParse(stockCtrl.text.trim()) ?? 0,
                          'fechaDeVencimiento': expDate?.toIso8601String().split('T')[0] ?? DateTime.now().add(const Duration(days: 365)).toIso8601String().split('T')[0],
                        };
                        Navigator.pop(ctx, data);
                      },
                      child: const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    nameCtrl.dispose();
    stockCtrl.dispose();
    priceCtrl.dispose();
    costCtrl.dispose();
    fnName.dispose();
    fnPrice.dispose();
    fnCost.dispose();
    fnStock.dispose();

    if (result != null) {
      await lotesCtrl.updateBatch(id, result);
    }
  }

  Future<void> _showAddBatch(AlmacenController almacenCtrl, LotesController lotesCtrl) async {
    String? selectedProductId;
    final nameCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    DateTime? expDate;
    final fnName = FocusNode();
    final fnPrice = FocusNode();
    final fnCost = FocusNode();
    final fnStock = FocusNode();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.greenMetal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_box_rounded, color: AppTheme.greenMetal, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Text('Nuevo Lote', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.grey.shade400),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: selectedProductId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Seleccionar Producto *',
                    prefixIcon: const Icon(Icons.medication_rounded, color: AppTheme.ayanamiBlue, size: 18),
                    filled: true,
                    fillColor: AppTheme.ayanamiBlue.withValues(alpha: 0.03),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  items: [
                    ...almacenCtrl.productos.map((p) => DropdownMenuItem(
                      value: p['productoId'].toString(),
                      child: Text(p['nombre']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                    )),
                  ],
                  onChanged: (v) => setD(() => selectedProductId = v),
                ),
                const SizedBox(height: 16),
                _field('Nombre del Lote *', nameCtrl, Icons.tag_rounded, fnName, TextInputAction.next, () => fnPrice.requestFocus()),
                Row(children: [
                  Expanded(child: _field('Precio Venta *', priceCtrl, Icons.sell_rounded, fnPrice, TextInputAction.next, () => fnCost.requestFocus(), keyboard: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Costo Compra *', costCtrl, Icons.shopping_cart_rounded, fnCost, TextInputAction.next, () => fnStock.requestFocus(), keyboard: TextInputType.number)),
                ]),
                Row(children: [
                  Expanded(child: _field('Stock *', stockCtrl, Icons.warehouse_rounded, fnStock, TextInputAction.done, null, keyboard: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final dt = await showDatePicker(
                          context: ctx,
                          initialDate: expDate ?? DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (dt != null) setD(() => expDate = dt);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.ayanamiBlue.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.ayanamiBlue.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.ayanamiBlue),
                            const SizedBox(width: 8),
                            Text(
                              expDate != null ? '${expDate!.day}/${expDate!.month}/${expDate!.year}' : 'Fecha vencimiento *',
                              style: TextStyle(fontSize: 13, color: expDate != null ? Colors.black87 : Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.greenMetal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (selectedProductId == null) return;
                        if (nameCtrl.text.trim().isEmpty) return;
                        if (expDate == null) return;
                        final data = <String, dynamic>{
                          'productoId': selectedProductId,
                          'nombreLote': nameCtrl.text.trim(),
                          'precioPorUnidad': double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0.0,
                          'costoDeCompra': double.tryParse(costCtrl.text.replaceAll(',', '.')) ?? 0.0,
                          'cantidadDisponible': int.tryParse(stockCtrl.text.trim()) ?? 0,
                          'fechaDeVencimiento': expDate!.toIso8601String().split('T')[0],
                        };
                        Navigator.pop(ctx, data);
                      },
                      child: const Text('CREAR LOTE', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    nameCtrl.dispose();
    stockCtrl.dispose();
    priceCtrl.dispose();
    costCtrl.dispose();
    fnName.dispose();
    fnPrice.dispose();
    fnCost.dispose();
    fnStock.dispose();

    if (result != null) {
      await lotesCtrl.createBatch(result);
    }
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, FocusNode fn, TextInputAction action, VoidCallback? onNext, {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        focusNode: fn,
        textInputAction: action,
        keyboardType: keyboard,
        onFieldSubmitted: (_) => onNext?.call(),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.ayanamiBlue, size: 18),
          filled: true,
          fillColor: AppTheme.ayanamiBlue.withValues(alpha: 0.03),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  num _batchPrice(Map<String, dynamic> b) {
    for (final f in ['precioPorUnidad', 'costoDeCompra', 'precioVenta', 'precio', 'precioCompra', 'precio_unitario', 'pvp']) {
      final v = double.tryParse((b[f] ?? '').toString());
      if (v != null && v > 0) return v;
    }
    return 0;
  }

  String? _batchBarcode(Map<String, dynamic> b) {
    for (final f in ['codigoBarras', 'codigo', 'barcode', 'ean', 'codigo_barra']) {
      final v = b[f]?.toString();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }
}
