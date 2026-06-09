import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../controllers/almacen_controller.dart';
import '../../controllers/lotes_controller.dart';
import '../../utils/inventory_dialogs.dart';
import '../../utils/price_formatter.dart';
import 'batch_details_modal.dart';

class ProductCard extends StatelessWidget {
  final dynamic p;
  final AlmacenController controller;
  final LotesController lotesCtrl;

  const ProductCard({
    super.key,
    required this.p,
    required this.controller,
    required this.lotesCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final int stock = p['cantidadDisponible'] ?? 0;
    final bool lowStock = stock < 30;
    final List lotes = p['lotes'] is List ? p['lotes'] : [];
    final String? imageUrl = p['imagenUrl'] ?? p['imagen'] ?? p['secure_url'];

    DateTime? nearestExpiry;
    for (var lote in lotes) {
      final dateStr = lote['fechaDeVencimiento'] ?? lote['fechaVencimiento'];
      final d = DateTime.tryParse(dateStr?.toString() ?? '');
      if (d != null) {
        if (nearestExpiry == null || d.isBefore(nearestExpiry)) {
          nearestExpiry = d;
        }
      }
    }
    
    bool isExpired = false;
    bool isNear = false;
    if (nearestExpiry != null) {
      isExpired = nearestExpiry.isBefore(DateTime.now());
      isNear = !isExpired && nearestExpiry.isBefore(DateTime.now().add(const Duration(days: 60)));
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: isExpired ? AppTheme.reiOrangeRed.withOpacity(0.08) : Colors.black.withOpacity(0.03),
              blurRadius: 30,
              offset: const Offset(0, 10)),
        ],
        border: Border.all(
          color: isExpired 
            ? AppTheme.reiOrangeRed.withOpacity(0.5) 
            : Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () {
            if (lotes.length > 1) {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (ctx) => BatchDetailsModal(
                  p: Map<String, dynamic>.from(p),
                  lotes: lotes,
                  controller: controller,
                  lotesCtrl: lotesCtrl,
                ),
              );
            } else {
              InventoryDialogs.showEditProduct(
                  context, controller,
                  prod: Map<String, dynamic>.from(p));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(20),
                          image: (imageUrl != null && imageUrl.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (imageUrl == null || imageUrl.isEmpty)
                            ? _buildIconPlaceholder(lowStock)
                            : null,
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: lowStock ? AppTheme.reiOrangeRed : AppTheme.greenMetal,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: (lowStock ? AppTheme.reiOrangeRed : AppTheme.greenMetal).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '$stock',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['nombre'] ?? 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text(p['descripcion'] ?? 'No hay descripción disponible para este producto.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      if (nearestExpiry != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isExpired ? AppTheme.reiOrangeRed.withOpacity(0.1) : (isNear ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.05)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isExpired ? Icons.warning_rounded : Icons.calendar_month_rounded, 
                                size: 12, 
                                color: isExpired ? AppTheme.reiOrangeRed : (isNear ? Colors.orange : Colors.grey)
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isExpired 
                                  ? 'Vencido el ${nearestExpiry.day}/${nearestExpiry.month}/${nearestExpiry.year}'
                                  : 'Vence: ${nearestExpiry.day}/${nearestExpiry.month}/${nearestExpiry.year}',
                                style: TextStyle(
                                  fontSize: 11, 
                                  fontWeight: FontWeight.w800,
                                  color: isExpired ? AppTheme.reiOrangeRed : (isNear ? Colors.orange : Colors.grey)
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3), width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PRECIO UNITARIO', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          Text(
                            formatCop(_getSafePrice(p)),
                            style: const TextStyle(
                                color: AppTheme.ayanamiBlue,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _actionButton(context, Icons.edit_rounded, AppTheme.ayanamiBlue, () {
                            InventoryDialogs.showEditProduct(context, controller, prod: Map<String, dynamic>.from(p));
                          }),
                          const SizedBox(width: 8),
                          _actionButton(context, Icons.delete_rounded, AppTheme.reiOrangeRed, () {
                            _confirmarBorrado(context);
                          }),
                        ],
                      )
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

  Widget _actionButton(BuildContext context, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildIconPlaceholder(bool lowStock) {
    return Center(
      child: Icon(
        Icons.medication_rounded,
        size: 40,
        color: lowStock ? AppTheme.reiOrangeRed.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
      ),
    );
  }

  Future<void> _confirmarBorrado(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Eliminar "${p['nombre']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.reiOrangeRed),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.white))),
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
      'precioVenta',
      'precio_venta',
      'precioPorUnidad',
      'pvp',
      'precio_unidad',
      'precioUnidad',
      'precio',
      'costoCompra',
      'precioCompra'
    ];
    for (var f in fields) {
      final val = p[f];
      if (val != null) {
        final pVal = double.tryParse(val.toString()) ?? 0.0;
        if (pVal > 0) return pVal;
      }
    }
    return 0.0;
  }
}
