import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../controllers/ventas_controller.dart';
import '../../utils/price_formatter.dart';
import '../../widgets/animations.dart';

Color _stockColor(int stock) {
  if (stock <= 0) return Colors.red;
  if (stock < 30) return Colors.orange;
  return Colors.green;
}

Color _stockBgColor(int stock) {
  if (stock <= 0) return Colors.red.withValues(alpha: 0.12);
  if (stock < 30) return Colors.orange.withValues(alpha: 0.12);
  return Colors.green.withValues(alpha: 0.10);
}

Color _priceColor(int stock) {
  if (stock <= 0) return Colors.grey;
  if (stock < 30) return Colors.orange.shade700;
  return AppTheme.greenMetal;
}

String? _expiryLabel(DateTime? expiry) {
  if (expiry == null) return null;
  final now = DateTime.now();
  if (expiry.isBefore(now)) return 'Vencido';
  if (expiry.difference(now).inDays <= 30) return 'Próx. vencer';
  return null;
}

Color _expiryLabelColor(DateTime? expiry) {
  if (expiry == null) return Colors.transparent;
  final now = DateTime.now();
  if (expiry.isBefore(now)) return Colors.red;
  if (expiry.difference(now).inDays <= 30) return Colors.orange;
  return Colors.transparent;
}

Color _expiryBgColor(DateTime? expiry) {
  if (expiry == null) return Colors.transparent;
  final now = DateTime.now();
  if (expiry.isBefore(now)) return Colors.red.withValues(alpha: 0.12);
  if (expiry.difference(now).inDays <= 30) return Colors.orange.withValues(alpha: 0.12);
  return Colors.transparent;
}

class SalesResultsGrid extends StatelessWidget {
  const SalesResultsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VentasController>();

    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.productosEncontrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)
                ],
              ),
              child: Icon(Icons.search_off_rounded,
                  size: 80, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text('No hay resultados',
                style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 18,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Intenta buscar por nombre o código',
                style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 130,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: controller.productosEncontrados.length,
      itemBuilder: (context, index) {
        final p = controller.productosEncontrados[index];
        final stock = p.cantidadDisponible;
        final expiryLabel = _expiryLabel(p.nearestExpiryDate);
        return AnimatedEntry(
          index: index,
          child: HoverScale(
            scale: 1.02,
            elevation: 6,
            child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: stock > 0 ? () => controller.agregarAlCarrito(p) : null,
              borderRadius: BorderRadius.circular(32),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppTheme.ayanamiBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.medication_rounded,
                          color: AppTheme.ayanamiBlue, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p.nombre,
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.2, color: stock <= 0 ? Colors.grey : null),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _stockBgColor(stock),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Stock: $stock',
                                    style: TextStyle(fontSize: 11, color: _stockColor(stock), fontWeight: FontWeight.w800)),
                              ),
                              if (expiryLabel != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _expiryBgColor(p.nearestExpiryDate),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(expiryLabel,
                                      style: TextStyle(fontSize: 11, color: _expiryLabelColor(p.nearestExpiryDate), fontWeight: FontWeight.w800)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                            formatCop(p.precioPorUnidad),
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: _priceColor(stock),
                                letterSpacing: -0.5)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: stock > 0
                                ? AppTheme.ayanamiBlue.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            stock > 0 ? Icons.add_rounded : Icons.block_rounded,
                            color: stock > 0 ? AppTheme.ayanamiBlue : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      );
      },
    );
  }
}
