import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/notificaciones_controller.dart';
import '../controllers/lotes_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_header.dart';

class AlertasScreen extends StatelessWidget {
  const AlertasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<NotificacionesController, LotesController, DashboardController>(
      builder: (context, notifCtrl, lotesCtrl, dashCtrl, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PremiumHeader(
            title: 'Centro de Monitoreo',
            subtitle: 'Alertas críticas de stock y vencimientos',
            icon: Icons.notifications_active_rounded,
            baseColor: AppTheme.ayanamiBlue,
            trailing: TextButton.icon(
              icon: const Icon(Icons.done_all_rounded, color: AppTheme.ayanamiBlue),
              label: const Text('Marcar Todo', style: TextStyle(color: AppTheme.ayanamiBlue, fontWeight: FontWeight.bold)),
              onPressed: notifCtrl.markAllAsRead,
            ),
          ),
          body: Column(
            children: [
              // Header para Control de Notificaciones Push
              _buildPushControlHeader(context, notifCtrl),
              
              Expanded(
                child: notifCtrl.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : notifCtrl.notificaciones.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: notifCtrl.notificaciones.length,
                            itemBuilder: (ctx, i) => _buildAlertCard(context, notifCtrl.notificaciones[i], lotesCtrl, dashCtrl),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPushControlHeader(BuildContext context, NotificacionesController notifCtrl) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: notifCtrl.isPushEnabled 
            ? AppTheme.ayanamiBlue.withOpacity(0.05) 
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: notifCtrl.isPushEnabled 
              ? AppTheme.ayanamiBlue.withOpacity(0.2) 
              : Colors.grey.withOpacity(0.2)
        ),
      ),
      child: Row(
        children: [
          Icon(
            notifCtrl.isPushEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
            color: notifCtrl.isPushEnabled ? AppTheme.ayanamiBlue : Colors.grey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notificaciones Flotantes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  notifCtrl.isPushEnabled 
                      ? 'Activadas (sonarán cada 45s si hay pendientes)' 
                      : 'Desactivadas (solo historial)', 
                  style: const TextStyle(fontSize: 11, color: Colors.grey)
                ),
              ],
            ),
          ),
          Switch(
            value: notifCtrl.isPushEnabled,
            onChanged: notifCtrl.togglePush,
            activeColor: AppTheme.ayanamiBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, Map<String, dynamic> n, LotesController lotesCtrl, DashboardController dashCtrl) {
    final tipo = n['tipo'] ?? 'aviso';
    final isUrgent = tipo == 'stock_bajo';
    final color = isUrgent ? AppTheme.reiPurple : AppTheme.ayanamiBlue;
    final msg = n['mensaje'] ?? 'Sin detalle';
    final fecha = n['fecha'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 10))
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: () {
            // Intentar detectar si es un lote o un producto
            final loteMatch = RegExp(r'(?:lote:|Lote:)\s*([a-zA-Z0-9_-]+)').firstMatch(msg);
            final prodMatch = RegExp(r'(?:producto:|Producto:)\s*([a-zA-Z0-9\s]+)').firstMatch(msg);

            if (loteMatch != null) {
                final loteNombre = loteMatch.group(1);
                lotesCtrl.setExternalSearch(loteNombre!);
                dashCtrl.onItemTapped(3); // Gestión de Lotes
            } else if (prodMatch != null) {
                dashCtrl.onItemTapped(1); // Almacén Central
            } else {
                // Fallback inteligente
                dashCtrl.onItemTapped(isUrgent ? 1 : 3);
            }
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(isUrgent ? Icons.inventory_2_rounded : Icons.event_busy_rounded, color: color, size: 28),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isUrgent ? 'STOCK CRÍTICO' : 'VENCIMIENTO PRÓXIMO',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: color, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text(msg, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 6),
                        Text(fecha, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Todo en orden por ahora', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
