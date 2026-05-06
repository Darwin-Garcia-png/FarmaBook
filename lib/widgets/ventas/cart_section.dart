import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../controllers/ventas_controller.dart';
import 'receipt_dialog.dart';

class CartSection extends StatelessWidget {
  const CartSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VentasController>();
    
    return Container(
      width: 450,
      margin: const EdgeInsets.fromLTRB(0, 24, 24, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 30,
              offset: const Offset(-10, 0))
        ],
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      decoration: BoxDecoration(
        color: AppTheme.ayanamiBlue.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.ayanamiBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.shopping_bag_rounded, color: AppTheme.ayanamiBlue, size: 24),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pedido Actual',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              Text('Detalles del consumo', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: AppTheme.ayanamiBlue,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: AppTheme.ayanamiBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                ]
            ),
            child: Text('${controller.carrito.length} Items',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
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
                size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Carrito vacío',
                style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(32),
      itemCount: controller.carrito.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final id = controller.carrito.keys.elementAt(index);
        final qty = controller.carrito[id]!;
        final prod = controller.cacheProductos[id]!;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.ayanamiBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medication_rounded, color: AppTheme.ayanamiBlue, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(prod.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('\$${prod.precioPorUnidad.toStringAsFixed(2)} x unidad',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  _actionButton(Icons.delete_outline_rounded, AppTheme.reiOrangeRed, () => controller.eliminarDelCarrito(id)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        _qtyBtn(context, Icons.remove_rounded, () => controller.quitarDeCarrito(id)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                        _qtyBtn(context, Icons.add_rounded, () => controller.agregarAlCarrito(prod)),
                      ],
                    ),
                  ),
                  Text('\$${(prod.precioPorUnidad * qty).toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.ayanamiBlue)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _qtyBtn(BuildContext context, IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 18, color: AppTheme.ayanamiBlue),
      onPressed: onPressed,
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildSummarySection(BuildContext context, VentasController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          _buildConsumidorField(context, controller),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Bruto', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              Text('\$${controller.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Impuestos (0%)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              Text('\$0.00', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL A COBRAR',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1)),
              Text('\$${controller.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.ayanamiBlue,
                      letterSpacing: -1)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 75,
            child: ElevatedButton(
              onPressed: controller.carrito.isEmpty || controller.isLoading
                  ? null
                  : () async {
                      final result = await controller.registrarVenta();
                      if (result != null && context.mounted) {
                        showDialog(
                          context: context,
                          builder: (ctx) => ReceiptDialog(sale: result['data']),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.greenMetal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 8,
                shadowColor: AppTheme.greenMetal.withOpacity(0.4),
              ),
              child: controller.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded),
                        SizedBox(width: 12),
                        Text('FINALIZAR VENTA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumidorField(BuildContext context, VentasController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.ayanamiBlue.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.person_outline_rounded, color: AppTheme.ayanamiBlue.withOpacity(0.7), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller.consumidorController,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                hintText: 'Nombre del consumidor (opcional)',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
