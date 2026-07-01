import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/almacen_controller.dart';
import '../controllers/lotes_controller.dart';
import '../utils/inventory_dialogs.dart';
import '../utils/price_formatter.dart';
import '../widgets/almacen/product_card.dart';
import '../widgets/premium_header.dart';
import '../widgets/error_display.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/animations.dart';
import '../utils/user_session.dart';

class AlmacenScreen extends StatefulWidget {
  const AlmacenScreen({super.key});

  @override
  State<AlmacenScreen> createState() => _AlmacenScreenState();
}

class _AlmacenScreenState extends State<AlmacenScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: UserSession.isDueno ? 2 : 1, vsync: this);
    context.read<AlmacenController>().touch();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<AlmacenController>().fetchProducts(isRefresh: false);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AlmacenController, LotesController>(
      builder: (context, controller, lotesCtrl, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PremiumHeader(
            title: 'Almacén Central', 
            subtitle: 'Inventario general de medicamentos', 
            icon: Icons.inventory_2_rounded, 
            baseColor: AppTheme.ayanamiBlue,
            trailing: IconButton(
              icon: Icon(Icons.refresh_rounded, size: 20, color: AppTheme.ayanamiBlue.withValues(alpha: 0.7)),
              onPressed: () => controller.init(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          body: UserSession.isDueno
              ? Column(
                  children: [
                    _buildHeader(context, controller),
                    _buildTabBar(lotesCtrl),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildMainContent(context, controller, lotesCtrl),
                          _buildArchivedContent(lotesCtrl, controller),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildHeader(context, controller),
                    Expanded(
                      child: _buildMainContent(context, controller, lotesCtrl),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildTabBar(LotesController lotesCtrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.ayanamiBlue,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.ayanamiBlue,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        tabs: [
          const Tab(text: 'PRODUCTOS'),
          Tab(text: 'PRECIOS HISTÓRICOS (${lotesCtrl.archivedBatches.length})'),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AlmacenController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: controller.searchCtrl,
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: 'Buscar medicamentos por nombre o código...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: controller.searchCtrl.text.isNotEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.search, color: AppTheme.ayanamiBlue),
                                onPressed: () => controller.search()),
                              IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  controller.searchCtrl.clear();
                                  controller.search();
                                }),
                            ],
                          )
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  ),
                  onSubmitted: (_) => controller.search(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: (() {
                  final seen = <String>{};
                  final List<Map<String, String>> uniqueCats = [];
                  for (var cat in controller.categorias) {
                    final id = cat['categoriaId']?.toString() ?? '';
                    if (!seen.contains(id)) {
                      seen.add(id);
                      uniqueCats.add({
                        'id': id,
                        'nombre': (cat['nombre'] ?? 'Sin nombre').toString()
                      });
                    }
                  }

                  final bool exists = controller.categoriaSeleccionada == null ||
                      uniqueCats.any(
                          (it) => it['id'] == controller.categoriaSeleccionada);
                  final String? safeValue =
                      exists ? controller.categoriaSeleccionada : null;

                  return DropdownButtonFormField<String>(
                    value: safeValue,
                    dropdownColor: Theme.of(context).cardTheme.color,
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        hintText: 'Todas las categorías',
                        hintStyle: const TextStyle(color: Colors.grey)),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Todas las categorías')),
                      ...uniqueCats.map((it) => DropdownMenuItem(
                          value: it['id'], child: Text(it['nombre']!))),
                    ],
                    onChanged: controller.updateCategoriaSeleccionada,
                  );
                })(),
              ),
              const SizedBox(width: 24),
              _buildLowStockButton(controller),
              if (UserSession.isDueno) const SizedBox(width: 16),
              if (UserSession.isDueno) _buildAddButton(context, controller),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown<String>(
                  context: context,
                  value: controller.casaSeleccionada,
                  hint: 'Todas las casas',
                  items: controller.casas.map((c) {
                    final id = c['casaId']?.toString() ?? '';
                    return DropdownMenuItem(
                      value: id,
                      child: Text(c['nombre']?.toString() ?? 'Sin nombre', style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: controller.updateCasaSeleccionada,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown<String>(
                  context: context,
                  value: controller.proveedorSeleccionada,
                  hint: 'Todos los proveedores',
                  items: controller.proveedores.map((p) {
                    final id = p['proveedorId']?.toString() ?? p['supplierId']?.toString() ?? '';
                    return DropdownMenuItem(
                      value: id,
                      child: Text(p['nombreComercial']?.toString() ?? p['nombre']?.toString() ?? 'Sin nombre', style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: controller.updateProveedorSeleccionada,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown<String>(
                  context: context,
                  value: controller.presentacionSeleccionada,
                  hint: 'Todas las presentaciones',
                  items: controller.presentaciones.map((p) {
                    final id = p['presentacionId']?.toString() ?? '';
                    return DropdownMenuItem(
                      value: id,
                      child: Text(p['nombre']?.toString() ?? 'Sin nombre', style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: controller.updatePresentacionSeleccionada,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: Theme.of(context).cardTheme.color,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      ),
      items: [
        DropdownMenuItem<T>(value: null, child: Text(hint, style: const TextStyle(fontSize: 13))),
        ...items,
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildLowStockButton(AlmacenController controller) {
    return ElevatedButton.icon(
      icon: Icon(Icons.warning_amber_rounded,
          color: controller.showLowStockOnly
              ? Colors.white
              : AppTheme.reiOrangeRed),
      label: Text('Bajo Stock',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: controller.showLowStockOnly
                  ? Colors.white
                  : AppTheme.reiOrangeRed)),
      style: ElevatedButton.styleFrom(
        backgroundColor: controller.showLowStockOnly
            ? AppTheme.reiOrangeRed
            : AppTheme.reiOrangeRed.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: AppTheme.reiOrangeRed.withValues(alpha: 0.5))),
        elevation: 0,
      ),
      onPressed: controller.toggleLowStockFilter,
    );
  }

  Widget _buildAddButton(BuildContext context, AlmacenController controller) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.add_box),
      label: const Text('Nuevo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.ayanamiBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 2,
      ),
      onPressed: () => InventoryDialogs.showAddEditProduct(context, controller,
          Provider.of<LotesController>(context, listen: false)),
    );
  }

  Widget _buildMainContent(BuildContext context, AlmacenController controller,
      LotesController lotesCtrl) {
    if (controller.isLoadingInitial) {
      return ShimmerList(itemCount: 6, itemHeight: 220, padding: const EdgeInsets.fromLTRB(32, 32, 32, 0));
    }

    if (controller.error != null && controller.productos.isEmpty) {
      return ErrorDisplay.inline(title: 'Carga fallida', message: controller.error!, onDismiss: () => controller.error = null);
    }

    if (controller.productos.isEmpty) {
      return const Center(
          child: Text('No hay productos encontrados',
              style: TextStyle(fontSize: 18, color: Colors.grey)));
    }

    return Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(left: 32, right: 32, top: 32, bottom: 80),
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              children: controller.productos.map((p) => SizedBox(
                key: ValueKey(p['productoId']),
                width: 300,
                child: AnimatedEntry(
                  child: ProductCard(
                    p: p,
                    controller: controller,
                    lotesCtrl: lotesCtrl,
                  ),
                ),
              )).toList(),
            ),
          ),
          if (controller.isFetchingMore)
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
    );
  }

  Widget _buildArchivedContent(LotesController lotesCtrl, AlmacenController almacenCtrl) {
    // Load deleted products lazily (only for dueño)
    if (UserSession.isDueno && almacenCtrl.deletedProducts.isEmpty && !almacenCtrl.isLoadingDeleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => almacenCtrl.fetchDeletedProducts());
    }

    final batches = lotesCtrl.archivedBatches;
    final showDeleted = UserSession.isDueno && almacenCtrl.deletedProducts.isNotEmpty;
    final hasBatches = batches.isNotEmpty;

    if (!showDeleted && !hasBatches) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No hay precios históricos', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

    // Combine deleted products and archived batches
    final totalItems = (showDeleted ? almacenCtrl.deletedProducts.length + 1 : 0) + (hasBatches ? batches.length : 0);

    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: totalItems,
      itemBuilder: (ctx, i) {
        // Deleted products section header
        if (showDeleted && i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text('PRODUCTOS ELIMINADOS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.reiOrangeRed, letterSpacing: 1)),
          );
        }

        int deletedIdx;
        if (showDeleted) {
          deletedIdx = i - 1;
          if (deletedIdx < almacenCtrl.deletedProducts.length) {
            return _buildDeletedProductCard(almacenCtrl.deletedProducts[deletedIdx], almacenCtrl);
          }
        }

        // Archived batches
        final batchIdx = showDeleted ? i - almacenCtrl.deletedProducts.length - 1 : i;
        final b = batches[batchIdx];
        final expDate = DateTime.tryParse(b['fechaDeVencimiento']?.toString() ?? b['fechaVencimiento']?.toString() ?? '');
        final stock = int.tryParse(b['cantidadDisponible'].toString()) ?? 0;
        final precio = _batchPrice(b);

        String reason = 'ARCHIVADO';
        Color reasonColor = Colors.grey;
        if (stock <= 0) {
          reason = 'SIN STOCK';
          reasonColor = AppTheme.reiPurple;
        } else if (expDate != null && expDate.isBefore(DateTime.now())) {
          reason = 'VENCIDO';
          reasonColor = AppTheme.reiOrangeRed;
        }

        return AnimatedEntry(
          index: i,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
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
                    child: Icon(
                      stock <= 0 ? Icons.inventory_2_rounded : Icons.error_outline_rounded,
                      color: reasonColor, size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b['nombreLote'] ?? 'Lote',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(b['productoNombre'] ?? b['productName'] ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8, runSpacing: 4,
                          children: [
                            _archivedBadge(reason, reasonColor),
                            _archivedBadge(
                              expDate == null ? 'Sin fecha' : 'Vence: ${expDate.day}/${expDate.month}/${expDate.year}',
                              Colors.grey,
                            ),
                            _archivedBadge('Stock: $stock', stock <= 0 ? Colors.grey : AppTheme.reiOrangeRed),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.greenMetal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.greenMetal.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        const Text('PRECIO', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text(
                          formatCop(precio),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.greenMetal),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeletedProductCard(Map<String, dynamic> p, AlmacenController almacenCtrl) {
    final prodId = p['productoId'] ?? p['id'] ?? '';
    return AnimatedEntry(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.reiOrangeRed.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.reiOrangeRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_forever_rounded, color: AppTheme.reiOrangeRed, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['nombre'] ?? p['productoNombre'] ?? 'Producto',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Código: ${p['codigoBarras'] ?? p['codigo'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    _archivedBadge('ELIMINADO', AppTheme.reiOrangeRed),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.restore_from_trash_rounded, color: AppTheme.greenMetal),
                tooltip: 'Restaurar producto',
                onPressed: () async {
                  try {
                    await almacenCtrl.restoreProduct(prodId);
                    if (context.mounted) {
                      ErrorDisplay.successSnackBar(context: context, message: 'Producto restaurado exitosamente.');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ErrorDisplay.snackBar(context: context, message: ErrorDisplay.cleanMessage(e));
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _archivedBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w800)),
    );
  }

  num _batchPrice(Map<String, dynamic> b) {
    for (final f in ['precioPorUnidad', 'costoDeCompra', 'precioVenta', 'precio', 'precioCompra', 'precio_unitario', 'pvp']) {
      final v = double.tryParse((b[f] ?? '').toString());
      if (v != null && v > 0) return v;
    }
    return 0;
  }
}
