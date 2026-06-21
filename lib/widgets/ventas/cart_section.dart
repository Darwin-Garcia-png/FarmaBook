import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../controllers/ventas_controller.dart';
import '../../utils/price_formatter.dart';
import 'receipt_dialog.dart';
import '../../widgets/animations.dart';

class CartSection extends StatelessWidget {
  final FocusNode? nombreFocusNode;
  final FocusNode? cedulaFocusNode;
  const CartSection({super.key, this.nombreFocusNode, this.cedulaFocusNode});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VentasController>();

    return Container(
      width: 320,
      margin: const EdgeInsets.fromLTRB(0, 24, 24, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 30,
              offset: const Offset(-10, 0))
        ],
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _buildHeader(context, controller),
            Expanded(child: _buildItemsList(context, controller)),
            _buildSummarySection(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, VentasController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.ayanamiBlue.withValues(alpha: 0.05),
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.ayanamiBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shopping_bag_rounded, color: AppTheme.ayanamiBlue, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Carrito',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
              Text('${controller.carrito.length} items',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, VentasController controller) {
    if (controller.carrito.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_shopping_cart_outlined,
                size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('Carrito vacío',
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: controller.carrito.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final id = controller.carrito.keys.elementAt(index);
        final qty = controller.carrito[id]!;
        final prod = controller.cacheProductos[id]!;
        return AnimatedEntry(
          index: index,
          child: HoverScale(
            scale: 1.02,
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
              ),
              child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.ayanamiBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.medication_rounded, color: AppTheme.ayanamiBlue, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(prod.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${formatCop(prod.precioPorUnidad)} u.',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _qtyBtn(context, Icons.remove_rounded, () => controller.quitarDeCarrito(id)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                    _qtyBtn(context, Icons.add_rounded, () => controller.agregarAlCarrito(prod)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatCop(prod.precioPorUnidad * qty),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.ayanamiBlue)),
                  InkWell(
                    onTap: () => controller.eliminarDelCarrito(id),
                    child: Icon(Icons.close_rounded, size: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _qtyBtn(BuildContext context, IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 16, color: AppTheme.ayanamiBlue),
      onPressed: onPressed,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
      splashRadius: 16,
    );
  }

  Widget _buildSummarySection(BuildContext context, VentasController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildConsumidorField(context, controller),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1)),
              Text(formatCop(controller.total),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.ayanamiBlue,
                      letterSpacing: -0.5)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: controller.carrito.isEmpty || controller.isLoading
                  ? null
                  : () async {
                      final result = await controller.registrarVenta();
                      if (result != null && context.mounted) {
                        showDialog(
                          context: context,
                          builder: (ctx) => ReceiptDialog(sale: controller.ultimaVenta ?? result['data']),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.greenMetal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppTheme.greenMetal.withValues(alpha: 0.3),
              ),
              child: controller.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('COBRAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumidorField(BuildContext context, VentasController controller) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.ayanamiBlue.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, color: AppTheme.ayanamiBlue.withValues(alpha: 0.7), size: 16),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                  controller: controller.clienteIdController,
                  focusNode: nombreFocusNode,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    hintText: 'Nombre del Cliente',
                    hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                  ),
                  onSubmitted: (_) => cedulaFocusNode?.requestFocus(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.ayanamiBlue.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.badge_outlined, color: AppTheme.ayanamiBlue.withValues(alpha: 0.7), size: 16),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                  controller: controller.clienteIdentificacionController,
                  focusNode: cedulaFocusNode,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Cédula / ID del Cliente',
                    hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
