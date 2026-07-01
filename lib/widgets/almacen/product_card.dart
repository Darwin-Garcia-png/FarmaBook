import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../controllers/almacen_controller.dart';
import '../../controllers/lotes_controller.dart';
import '../../services/api_service.dart';
import '../../utils/inventory_dialogs.dart';
import '../../utils/price_formatter.dart';
import '../animations.dart';
import '../../utils/user_session.dart';
import 'batch_details_modal.dart';

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> p;
  final AlmacenController controller;
  final LotesController lotesCtrl;

  const ProductCard({
    super.key,
    required this.p,
    required this.controller,
    required this.lotesCtrl,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  String? _casaNombre;
  String? _categoriaNombre;
  String? _presentacionNombre;
  bool _loadingDetail = false;
  int _stockFromBatches = -1;

  Map<String, dynamic> get p => widget.p;
  AlmacenController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    final pid = p['productoId']?.toString();
    if (pid == null || _loadingDetail) return;
    _loadingDetail = true;
    try {
      List<dynamic> batches;
      try {
        batches = await ApiService.getBatchesByProduct(pid);
      } catch (_) {
        batches = [];
      }
      int batchSum = 0;
      for (final b in batches) {
        batchSum += int.tryParse(b['cantidadDisponible']?.toString() ?? '0') ?? 0;
      }
      _stockFromBatches = batchSum;
      if (batches.isNotEmpty) p['lotes'] = batches;

      try {
        final detail = await ApiService.getProductByIdentifier(pid);
        if (detail != null && mounted) {
          final casaId = detail['casasId'] is List && (detail['casasId'] as List).isNotEmpty
              ? (detail['casasId'] as List).first?.toString()
              : null;
          final catId = detail['categoriaId']?.toString();
          final presId = detail['presentacionId']?.toString();

          if (detail['imagenUrl'] != null) p['imagenUrl'] = detail['imagenUrl'];
          _casaNombre = _findName(controller.casas, 'casaId', casaId);
          _categoriaNombre = _findName(controller.categorias, 'categoriaId', catId);
          _presentacionNombre = _findName(controller.presentaciones, 'presentacionId', presId);
        }
      } catch (_) {}

      if (mounted) setState(() {});
    } catch (_) {}
    if (mounted) setState(() => _loadingDetail = false);
  }

  String? _findName(List<dynamic> list, String idField, String? id) {
    if (id == null) return null;
    for (final item in list) {
      if (item is Map && item[idField]?.toString() == id) {
        return item['nombre']?.toString();
      }
    }
    return null;
  }

  int _totalStock() {
    if (_stockFromBatches >= 0) return _stockFromBatches;
    for (final f in ['cantidadDisponible', 'stock', 'existencia', 'cantidad', 'totalStock', 'total_stock']) {
      final v = int.tryParse(p[f]?.toString() ?? '');
      if (v != null) return v;
    }
    return 0;
  }

  String? _imageUrl() {
    return p['imagenUrl']?.toString() ??
        p['imagen']?.toString() ??
        p['secure_url']?.toString() ??
        p['imagen_url']?.toString() ??
        p['fotoUrl']?.toString();
  }

  DateTime? _nearestExpiry() {
    final lotes = p['lotes'] is List ? p['lotes'] as List : <dynamic>[];
    DateTime? nearest;
    for (final l in lotes) {
      final ds = l['fechaDeVencimiento'] ?? l['fechaVencimiento'];
      final d = DateTime.tryParse(ds?.toString() ?? '');
      if (d != null && (nearest == null || d.isBefore(nearest))) nearest = d;
    }
    return nearest;
  }

  @override
  Widget build(BuildContext context) {
    final stock = _totalStock();
    final lowStock = stock > 0 && stock < 30;
    final sinStock = stock == 0;
    final imageUrl = _imageUrl();
    final nearestExpiry = _nearestExpiry();
    final isExpired = nearestExpiry != null && nearestExpiry.isBefore(DateTime.now());
    final isNear = nearestExpiry != null && !isExpired && nearestExpiry.isBefore(DateTime.now().add(const Duration(days: 60)));
    final lotes = p['lotes'] is List ? p['lotes'] as List : <dynamic>[];

    Color statusColor = AppTheme.greenMetal;
    String statusText = 'DISPONIBLE';
    if (sinStock) { statusColor = Colors.grey; statusText = 'SIN STOCK'; }
    else if (lowStock) { statusColor = AppTheme.reiPurple; statusText = 'BAJO STOCK'; }
    if (isExpired) { statusColor = AppTheme.reiOrangeRed; statusText = 'VENCIDO'; }
    else if (isNear) { statusColor = Colors.orange; statusText = 'PRÓXIMO VENCER'; }

    final genericName = (p['nombreGenerico']?.toString() ?? '').isNotEmpty
        ? p['nombreGenerico'].toString()
        : null;
    final concentration = (p['concentracion']?.toString() ?? '').isNotEmpty
        ? p['concentracion'].toString()
        : null;

    return HoverScale(
      scale: 1.03,
      elevation: 18,
      glowColor: AppTheme.ayanamiBlue.withValues(alpha: 0.15),
      child: Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isExpired ? AppTheme.reiOrangeRed.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isExpired ? AppTheme.reiOrangeRed.withValues(alpha: 0.3) : Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showBatchPanel(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image at top
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(imageUrl, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) => _iconPlaceholder())
                          : _iconPlaceholder(),
                    ),
                  ),
                  if (UserSession.isDueno)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _actionIcon(Icons.edit_rounded, AppTheme.ayanamiBlue, () {
                            InventoryDialogs.showEditProduct(context, controller, prod: Map<String, dynamic>.from(p));
                          }),
                          const SizedBox(width: 6),
                          _actionIcon(Icons.delete_rounded, AppTheme.reiOrangeRed, () {
                            _confirmDelete(context);
                          }),
                        ],
                      ),
                    ),
                ],
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['nombre'] ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (genericName != null || concentration != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [if (genericName != null) genericName, if (concentration != null) concentration].join(' - '),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 14),
                    _stockBar(stock, statusColor, statusText),
                    const SizedBox(height: 10),
                    if (_categoriaNombre != null)
                      _infoRow(Icons.category_rounded, _categoriaNombre!),
                    if (_casaNombre != null)
                      _infoRow(Icons.business_rounded, _casaNombre!),
                    if (_presentacionNombre != null)
                      _infoRow(Icons.medication_liquid_rounded, _presentacionNombre!),
                    if (nearestExpiry != null)
                      _infoRow(
                        isExpired ? Icons.error_outline_rounded : Icons.event_rounded,
                        isExpired
                            ? 'Vencido ${nearestExpiry.day}/${nearestExpiry.month}/${nearestExpiry.year}'
                            : 'Vence ${nearestExpiry.day}/${nearestExpiry.month}/${nearestExpiry.year}',
                        color: isExpired ? AppTheme.reiOrangeRed : (isNear ? Colors.orange : Colors.grey.shade500),
                      ),
                    if (lotes.isNotEmpty)
                      _infoRow(Icons.layers_outlined, '${lotes.length} lote${lotes.length > 1 ? 's' : ''}'),
                    if (_loadingDetail)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.ayanamiBlue.withValues(alpha: 0.5)),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PRECIO UNIT.', style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.attach_money_rounded, size: 16, color: AppTheme.ayanamiBlue),
                            Text(
                              formatCop(_getSafePrice(p)),
                              style: const TextStyle(color: AppTheme.ayanamiBlue, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -1),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _showBatchPanel(BuildContext context) {
    final lotes = p['lotes'] is List ? p['lotes'] as List : <dynamic>[];
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black26,
      pageBuilder: (ctx, anim1, anim2) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 420,
              margin: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 40,
                    offset: const Offset(-10, 0),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBatchPanelHeader(context),
                    _buildBatchPanelContent(context, lotes),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (ctx, anim, secondaryAnim, child) => child,
    );
  }

  Widget _buildBatchPanelHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['nombre'] ?? 'Sin nombre',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text('Lotes registrados',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.ayanamiBlue),
            tooltip: 'Añadir Lote',
            onPressed: () {
              Navigator.pop(context);
              InventoryDialogs.showAddEditProduct(
                  context, controller, widget.lotesCtrl,
                  prod: Map<String, dynamic>.from(p), isNewBatchOnly: true);
            },
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchPanelContent(BuildContext context, List<dynamic> lotes) {
    return Expanded(
      child: lotes.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text('Sin lotes registrados', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lotes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _buildBatchDetailCard(lotes[i]),
            ),
    );
  }

  Widget _buildBatchDetailCard(dynamic l) {
    final batchName = l['nombreLote']?.toString() ?? l['batchName']?.toString() ?? 'Sin nombre';
    final qty = int.tryParse(l['cantidadDisponible']?.toString() ?? '0') ?? 0;
    final expiryStr = l['fechaDeVencimiento']?.toString() ?? l['fechaVencimiento']?.toString() ?? '';
    final expiry = DateTime.tryParse(expiryStr);
    final isBatchExpired = expiry != null && expiry.isBefore(DateTime.now());
    final batchPrice = _parsePrice(l);
    final batchCost = _parseCost(l);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isBatchExpired ? AppTheme.reiOrangeRed.withValues(alpha: 0.1) : AppTheme.ayanamiBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isBatchExpired ? Icons.warning_amber_rounded : Icons.inventory_rounded,
                  size: 16, color: isBatchExpired ? AppTheme.reiOrangeRed : AppTheme.ayanamiBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(batchName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
              if (UserSession.isDueno)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      InventoryDialogs.showAddEditProduct(
                        context, controller, widget.lotesCtrl,
                        prod: Map<String, dynamic>.from(p), prefillBatch: Map<String, dynamic>.from(l),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.ayanamiBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.edit_rounded, size: 16, color: AppTheme.ayanamiBlue),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _confirmarDesactivarLote(context, l, widget.lotesCtrl, controller),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.toggle_off_outlined, size: 16, color: Colors.orange),
                    ),
                  ),
                ]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _batchStat('Stock', '$qty', qty < 10 ? AppTheme.reiOrangeRed : Colors.black87),
              if (batchPrice > 0) _batchStat('Precio', formatCop(batchPrice), Colors.black87),
              if (batchCost > 0) _batchStat('Costo', formatCop(batchCost), Colors.grey.shade600),
            ],
          ),
          if (expiry != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(isBatchExpired ? Icons.error_outline_rounded : Icons.event_rounded,
                    size: 14, color: isBatchExpired ? AppTheme.reiOrangeRed : Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  isBatchExpired
                      ? 'Vencido el ${expiry.day}/${expiry.month}/${expiry.year}'
                      : 'Vence el ${expiry.day}/${expiry.month}/${expiry.year}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isBatchExpired ? AppTheme.reiOrangeRed : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _batchStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  double _parsePrice(dynamic l) {
    for (final f in ['precio', 'precioVenta', 'precio_venta', 'pvp']) {
      final v = double.tryParse(l[f]?.toString() ?? '');
      if (v != null && v > 0) return v;
    }
    return 0;
  }

  double _parseCost(dynamic l) {
    for (final f in ['costoDeCompra', 'costoCompra', 'costo', 'precioCompra']) {
      final v = double.tryParse(l[f]?.toString() ?? '');
      if (v != null && v > 0) return v;
    }
    return 0;
  }

  Widget _stockBar(int stock, Color color, String statusText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2_rounded, size: 14, color: color),
            const SizedBox(width: 6),
            Text('Stock: $stock',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color)),
            const Spacer(),
            _statusChip(statusText, color),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: stock > 0 ? (stock > 100 ? 1.0 : stock / 100.0) : 0.0,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _iconPlaceholder() {
    return Center(
      child: Icon(Icons.medication_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.5)),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey.shade400),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: color ?? Colors.grey.shade600, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Eliminar "${p['nombre']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.reiOrangeRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await controller.deleteProduct(p['productoId']);
    }
  }

  num _getSafePrice(dynamic p) {
    if (p == null) return 0.0;
    final List<String> fields = [
      'precioPorUnidad', 'precioVenta', 'precio_venta', 'pvp', 'precio_unidad', 'precioUnidad', 'precio', 'costoCompra', 'precioCompra'
    ];
    for (final f in fields) {
      final val = p[f];
      if (val != null) {
        final pVal = double.tryParse(val.toString()) ?? 0.0;
        if (pVal > 0) return pVal;
      }
    }
    return 0.0;
  }

  Future<void> _confirmarDesactivarLote(BuildContext context, dynamic batch,
      LotesController lotesCtrl, AlmacenController controller) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar Lote'),
        content: const Text('Se pondrá el stock a 0. El lote pasará al historial. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final id = (batch['loteId'] ?? batch['batchId'] ?? batch['id']).toString();
      await lotesCtrl.deactivateBatch(id);
      controller.fetchProducts(isRefresh: true);
    }
  }

}
