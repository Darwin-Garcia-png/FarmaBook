import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/almacen_controller.dart';
import '../controllers/lotes_controller.dart';
import '../utils/inventory_dialogs.dart';
import '../widgets/almacen/product_card.dart';
import '../widgets/premium_header.dart';

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
          body: Column(
            children: [
              PremiumHeader(
                title: 'Almacén Central', 
                subtitle: 'Inventario general de medicamentos', 
                icon: Icons.inventory_2_rounded, 
                baseColor: AppTheme.ayanamiBlue,
                trailing: IconButton(
                  icon: Icon(Icons.refresh_rounded, size: 20, color: AppTheme.ayanamiBlue.withOpacity(0.7)),
                  onPressed: () => controller.init(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
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
              // De-duplicate items for UI safety
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
            : AppTheme.reiOrangeRed.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: AppTheme.reiOrangeRed.withOpacity(0.5))),
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
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (controller.error != null && controller.productos.isEmpty) {
      return Expanded(
          child: Center(
              child: Text(controller.error!,
                  style: const TextStyle(fontSize: 18, color: Colors.red))));
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
                childAspectRatio: 0.75,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24),
            itemCount: controller.productos.length,
            itemBuilder: (context, index) => ProductCard(
              p: controller.productos[index],
              controller: controller,
              lotesCtrl: lotesCtrl,
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
      ),
    );
  }
}
