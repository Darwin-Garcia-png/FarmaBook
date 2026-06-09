import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../controllers/almacen_controller.dart';
import '../../controllers/lotes_controller.dart';
import '../../utils/inventory_dialogs.dart';
import '../../utils/price_formatter.dart';

class BatchDetailsModal extends StatelessWidget {
  final Map<String, dynamic> p;
  final List lotes;
  final AlmacenController controller;
  final LotesController lotesCtrl;

  const BatchDetailsModal({
    super.key,
    required this.p,
    required this.lotes,
    required this.controller,
    required this.lotesCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                    backgroundColor: AppTheme.ayanamiBlue.withOpacity(0.1),
                    child: const Icon(Icons.layers_outlined,
                        color: AppTheme.ayanamiBlue)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lotes de ${p['nombre']}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${lotes.length} lotes registrados',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppTheme.ayanamiBlue),
                  onPressed: () {
                    Navigator.pop(context);
                    InventoryDialogs.showAddEditProduct(
                        context, controller, lotesCtrl,
                        prod: p, isNewBatchOnly: true);
                  },
                )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: lotes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (itemCtx, i) {
                final l = lotes[i];
                final expDate = DateTime.tryParse(l['fechaDeVencimiento']?.toString() ?? l['fechaVencimiento']?.toString() ?? '');
                final stock = int.tryParse(l['cantidadDisponible'].toString()) ?? 0;

                int daysLeft = 9999;
                if (expDate != null) {
                  daysLeft = expDate.difference(DateTime.now()).inDays;
                }

                Color statusColor = AppTheme.greenMetal;
                IconData statusIcon = Icons.check_circle_outline;

                if (daysLeft < 0) {
                  statusColor = AppTheme.reiOrangeRed;
                  statusIcon = Icons.error_outline_rounded;
                } else if (daysLeft <= 60) {
                  statusColor = Colors.orange;
                  statusIcon = Icons.warning_amber_rounded;
                } else if (stock < 30) {
                  statusColor = AppTheme.reiPurple;
                  statusIcon = Icons.trending_down_rounded;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l['nombreLote'] ?? 'Sin Nombre',
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.event_available, size: 14, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        expDate != null ? 'Vence: ${expDate.day}/${expDate.month}/${expDate.year}' : 'Sin fecha',
                                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                    Text(
                                    '${formatCop(double.tryParse((l['costoCompra'] ?? l['costoDeCompra'] ?? '0').toString()) ?? 0.0)} / ud',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$stock',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: stock < 30 ? AppTheme.reiPurple : AppTheme.ayanamiBlue, height: 1),
                                  ),
                                  const Text(
                                    'Uds',
                                    style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_note, color: AppTheme.ayanamiBlue, size: 20),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    InventoryDialogs.showAddEditProduct(context, controller, lotesCtrl, prod: p, prefillBatch: l);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.reiOrangeRed, size: 20),
                                  onPressed: () => _confirmarBorradoLote(context, l, lotesCtrl, controller),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarBorradoLote(BuildContext context, dynamic batch,
      LotesController lotesCtrl, AlmacenController controller) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Lote'),
        content: Text('¿Deseas eliminar el lote "${batch['nombreLote']}"?'),
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
      await lotesCtrl.deleteBatch((batch['loteId'] ?? batch['batchId'] ?? batch['id']).toString());
      controller.fetchProducts(isRefresh: true);
      if (context.mounted) Navigator.pop(context);
    }
  }
}
