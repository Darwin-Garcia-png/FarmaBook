import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../controllers/ventas_controller.dart';

class SalesSearchSection extends StatelessWidget {
  const SalesSearchSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VentasController>();

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 30,
              offset: const Offset(0, 10)),
        ],
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller.barcodeController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Escanear Código de Barras...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon:
                  const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.ayanamiBlue),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(22),
            ),
            onSubmitted: (_) => controller.buscarPorCodigo(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre de medicamento...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: AppTheme.ayanamiBlue),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(22),
                  ),
                  onSubmitted: (_) => controller.buscarPorNombre(),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: controller.buscarPorNombre,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.ayanamiBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  shadowColor: AppTheme.ayanamiBlue.withValues(alpha: 0.3),
                ),
                child: const Icon(Icons.search_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
