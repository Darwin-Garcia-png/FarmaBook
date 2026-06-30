import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/lotes_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_header.dart';
import '../widgets/shimmer_loading.dart';
import '../utils/price_formatter.dart';
import '../widgets/animations.dart';

class HistorialAlmacenScreen extends StatefulWidget {
  const HistorialAlmacenScreen({super.key});

  @override
  State<HistorialAlmacenScreen> createState() => _HistorialAlmacenScreenState();
}

class _HistorialAlmacenScreenState extends State<HistorialAlmacenScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LotesController>().touch();
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
    return Consumer<LotesController>(
      builder: (context, lotesCtrl, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PremiumHeader(
            title: 'Historial de Almacén',
            subtitle: 'Lotes desactivados y precios históricos',
            icon: Icons.history_rounded,
            baseColor: AppTheme.reiPurple,
            trailing: IconButton(
              icon: Icon(Icons.refresh_rounded, size: 20,
                  color: AppTheme.reiPurple.withValues(alpha: 0.7)),
              onPressed: () => lotesCtrl.refresh(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          body: lotesCtrl.isLoading
              ? const ShimmerList(itemCount: 6, itemHeight: 90)
              : Column(
                  children: [
                    _buildSearchBar(),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorWeight: 4,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicatorColor: AppTheme.reiPurple,
                        labelColor: AppTheme.reiPurple,
                        unselectedLabelColor: Colors.grey,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 13),
                        tabs: [
                          Tab(text: 'Desactivados (${lotesCtrl.archivedBatches.length})'),
                          Tab(text: 'Precio Histórico (${_uniqueProducts(lotesCtrl)})'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildArchivedList(lotesCtrl),
                          _buildPriceHistory(lotesCtrl),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Buscar por producto o lote...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.reiPurple),
          filled: true,
          fillColor: Theme.of(context).cardTheme.color,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  int _uniqueProducts(LotesController lotesCtrl) {
    final seen = <String>{};
    for (final b in lotesCtrl.allBatches) {
      final id = b['productoId']?.toString() ?? '';
      if (id.isNotEmpty) seen.add(id);
    }
    return seen.length;
  }

  Widget _buildArchivedList(LotesController lotesCtrl) {
    final filtered = lotesCtrl.archivedBatches.where((b) {
      final name = b['nombreLote']?.toString().toLowerCase() ?? '';
      final prod = b['productoNombre']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery) || prod.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No hay lotes desactivados', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => AnimatedEntry(
        index: i,
        child: _buildArchivedCard(filtered[i]),
      ),
    );
  }

  Widget _buildArchivedCard(Map<String, dynamic> b) {
    final expDate = DateTime.tryParse(
        b['fechaDeVencimiento']?.toString() ?? b['fechaVencimiento']?.toString() ?? '');
    final stock = int.tryParse(b['cantidadDisponible'].toString()) ?? 0;
    final precio = _batchPrice(b);

    String reason = 'SIN STOCK';
    Color reasonColor = AppTheme.reiPurple;
    if (expDate != null && expDate.isBefore(DateTime.now())) {
      reason = 'VENCIDO';
      reasonColor = AppTheme.reiOrangeRed;
    } else if (stock > 0) {
      reason = 'ARCHIVADO';
      reasonColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: reasonColor.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: reasonColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.inventory_2_outlined, color: reasonColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b['nombreLote'] ?? 'Lote',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('${b['productoNombre'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _miniBadge(reason, reasonColor),
                      if (expDate != null) ...[
                        const SizedBox(width: 8),
                        _miniBadge('${expDate.day}/${expDate.month}/${expDate.year}',
                            Colors.grey),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Stock: $stock',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: reasonColor)),
                const SizedBox(height: 4),
                Text(formatCop(precio),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.reiPurple)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _buildPriceHistory(LotesController lotesCtrl) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final b in lotesCtrl.allBatches) {
      final pid = b['productoId']?.toString() ?? '';
      if (pid.isEmpty) continue;
      grouped.putIfAbsent(pid, () => []);
      grouped[pid]!.add(b);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      final nameA = grouped[a]!.first['productoNombre']?.toString() ?? '';
      final nameB = grouped[b]!.first['productoNombre']?.toString() ?? '';
      return nameA.compareTo(nameB);
    });

    if (sortedKeys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up_rounded, size: 48,
                color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No hay datos de precio histórico',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: sortedKeys.length,
      itemBuilder: (ctx, i) {
        final pid = sortedKeys[i];
        final batches = grouped[pid]!;
        final prodName = batches.first['productoNombre']?.toString() ?? 'Producto';
        final codigo = batches.first['productoCodigo']?.toString() ?? '';

        batches.sort((a, b) {
          final da = DateTime.tryParse(
              a['fechaDeVencimiento']?.toString() ?? a['fechaVencimiento']?.toString() ?? '');
          final db = DateTime.tryParse(
              b['fechaDeVencimiento']?.toString() ?? b['fechaVencimiento']?.toString() ?? '');
          return (db ?? DateTime(9999)).compareTo(da ?? DateTime(9999));
        });

        return AnimatedEntry(
          index: i,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.ayanamiBlue.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.ayanamiBlue.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.ayanamiBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.medication_rounded,
                            color: AppTheme.ayanamiBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(prodName,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w900)),
                            if (codigo.isNotEmpty)
                              Text('SKU: $codigo',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.ayanamiBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${batches.length} lotes',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w800,
                                color: AppTheme.ayanamiBlue)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trending_up_rounded, size: 14,
                              color: AppTheme.greenMetal),
                          const SizedBox(width: 6),
                          Text('PRECIO',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w900,
                                  color: Colors.grey.shade500, letterSpacing: 1)),
                          const SizedBox(width: 16),
                          Text('LOTE',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w900,
                                  color: Colors.grey.shade500, letterSpacing: 1)),
                          const SizedBox(width: 16),
                          Text('VENCIMIENTO',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w900,
                                  color: Colors.grey.shade500, letterSpacing: 1)),
                          const Spacer(),
                          Text('STOCK',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w900,
                                  color: Colors.grey.shade500, letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...batches.map((b) {
                        final p = _batchPrice(b);
                        final exp = DateTime.tryParse(
                            b['fechaDeVencimiento']?.toString() ??
                            b['fechaVencimiento']?.toString() ?? '');
                        final st = int.tryParse(
                            b['cantidadDisponible'].toString()) ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Text(formatCop(p),
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w900,
                                      color: AppTheme.greenMetal)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(b['nombreLote'] ?? '',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  exp != null
                                      ? '${exp.day}/${exp.month}/${exp.year}'
                                      : 'N/A',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: Text('$st',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w700,
                                        color: st <= 0
                                            ? AppTheme.reiOrangeRed
                                            : Colors.grey.shade800)),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  num _batchPrice(Map<String, dynamic> b) {
    for (final f in [
      'precioPorUnidad', 'costoDeCompra', 'precioVenta',
      'precio', 'precioCompra', 'precio_unitario', 'pvp'
    ]) {
      final v = double.tryParse((b[f] ?? '').toString());
      if (v != null && v > 0) return v;
    }
    return 0;
  }
}
