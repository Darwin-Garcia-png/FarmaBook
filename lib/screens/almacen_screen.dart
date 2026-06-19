import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/almacen_controller.dart';
import '../controllers/lotes_controller.dart';
import '../utils/inventory_dialogs.dart';
import '../widgets/almacen/product_card.dart';
import '../widgets/premium_header.dart';
import '../widgets/error_display.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/animations.dart';

class AlmacenScreen extends StatefulWidget {
  const AlmacenScreen({super.key});

  @override
  State<AlmacenScreen> createState() => _AlmacenScreenState();
}

class _AlmacenScreenState extends State<AlmacenScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<AlmacenController>().touch();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        context.read<AlmacenController>().fetchProducts(isRefresh: false);
      }
    });
  }

  @override
  void dispose() {
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
          body: Column(
            children: [
              _buildHeader(context, controller),
              _buildMainContent(context, controller, lotesCtrl),
            ],
          ),
        );
      },
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
                    initialValue: safeValue,
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
              const SizedBox(width: 16),
              _buildAddButton(context, controller),
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
      return Expanded(child: ShimmerList(itemCount: 6, itemHeight: 220, padding: const EdgeInsets.fromLTRB(32, 32, 32, 0)));
    }

    if (controller.error != null && controller.productos.isEmpty) {
      return Expanded(child: ErrorDisplay.inline(message: controller.error!, onDismiss: () => controller.error = null));
    }

    if (controller.productos.isEmpty) {
      return const Expanded(
          child: Center(
              child: Text('No hay productos encontrados',
                  style: TextStyle(fontSize: 18, color: Colors.grey))));
    }

    return Expanded(
      child: Stack(
        children: [
          GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(left: 32, right: 32, top: 32, bottom: 80),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 0.58,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24),
            itemCount: controller.productos.length,
            itemBuilder: (context, index) => AnimatedEntry(
              index: index,
              child: ProductCard(
              p: controller.productos[index],
              controller: controller,
              lotesCtrl: lotesCtrl,
            )),
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
      ),
    );
  }
}
