import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../controllers/inicio_controller.dart';
import '../utils/price_formatter.dart';
import '../controllers/dashboard_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/error_display.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/animations.dart';
import '../utils/user_session.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});
  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final InicioController _ctrl = InicioController();

  @override
  void initState() {
    super.initState();
    _ctrl.touch();
    _ctrl.addListener(() { if (mounted) setState(() {}); });
    _ctrl.init();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _go(int i) => Provider.of<DashboardController>(context, listen: false).onItemTapped(i);

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final text = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final card = Theme.of(context).cardTheme.color ?? Colors.white;

    if (_ctrl.isLoading) return const Scaffold(body: ShimmerList(itemCount: 6, itemHeight: 100));
    if (_ctrl.error != null) return _errorView();

    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.08,
              child: const ParticleBackground(
                color: AppTheme.ayanamiBlue,
                particleCount: 18,
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 100, 40, 60),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── GREETING + SUMMARY ──
            AnimatedEntry(
              index: 0,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.ayanamiBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.wb_sunny_rounded, size: 12, color: AppTheme.ayanamiBlue),
                        const SizedBox(width: 6),
                        Text(_greet(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.ayanamiBlue)),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.greenMetal.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.today_rounded, size: 12, color: AppTheme.greenMetal),
                        const SizedBox(width: 6),
                        Text(DateFormat("d MMM yyyy", 'es').format(DateTime.now()).toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.greenMetal)),
                      ]),
                    ),
                  ]),
                  const SizedBox(width: 12),
                  Text('Panel de Control', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.5, color: text)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _ctrl.ingresos - _ctrl.egresos >= 0 ? AppTheme.greenMetal.withValues(alpha: 0.08) : AppTheme.reiOrangeRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.account_balance_wallet_rounded,
                      size: 16, color: _ctrl.ingresos - _ctrl.egresos >= 0 ? AppTheme.greenMetal : AppTheme.reiOrangeRed),
                    const SizedBox(width: 8),
                    Text('Balance ${formatCop(_ctrl.ingresos - _ctrl.egresos)}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
                        color: _ctrl.ingresos - _ctrl.egresos >= 0 ? AppTheme.greenMetal : AppTheme.reiOrangeRed)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 32),

            // ── KPIs ──
            Row(children: [
              _kpi('Ingresos', formatCop(_ctrl.ingresos), Icons.trending_up_rounded, AppTheme.greenMetal, _ctrl.ingresos, () => _go(4), index: 1),
              const SizedBox(width: 16),
              _kpi('Egresos', formatCop(_ctrl.egresos), Icons.trending_down_rounded, AppTheme.reiOrangeRed, _ctrl.egresos, () => _go(4), index: 2),
              const SizedBox(width: 16),
              _kpi('Balance', formatCop(_ctrl.ingresos - _ctrl.egresos), Icons.account_balance_rounded, const Color(0xFF8B5CF6),
                _ctrl.ingresos - _ctrl.egresos, () => _go(4), index: 3),
              const SizedBox(width: 16),
              _kpi('Stock', '${(_ctrl.stockHealthPercent * 100).toInt()}%', Icons.inventory_rounded, AppTheme.ayanamiBlue,
                _ctrl.stockHealthPercent, () => _go(1), isPct: true, index: 4),
            ]),
            const SizedBox(height: 32),

            // ── CONTENT ROW: Left (Sales + Products) | Right (Alerts + Quick) ──
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                flex: 3,
                child: AnimatedEntry(
                  index: 5,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── VENTAS RECIENTES ──
                _sectionH('VENTAS RECIENTES', Icons.receipt_long_rounded, AppTheme.greenMetal, _ctrl.recentSales.isNotEmpty
                  ? TextButton(onPressed: () => _go(2), child: const Text('Ver todas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))) : null),
                const SizedBox(height: 12),
                if (_ctrl.recentSales.isEmpty)
                  _emptyCard('Sin ventas hoy', Icons.receipt_long_rounded, Colors.grey)
                else
                  ..._ctrl.recentSales.take(5).map((s) {
                    final total = double.tryParse(s['total']?.toString() ?? '0') ?? 0;
                    final id = s['ventaId']?.toString() ?? '';
                    final shortId = id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
                    return HoverScale(
                      scale: 1.015,
                      elevation: 4,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14),
                          border: Border(left: BorderSide(color: AppTheme.greenMetal.withValues(alpha: 0.3), width: 3))),
                        child: Row(children: [
                          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.greenMetal.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.receipt_rounded, size: 16, color: AppTheme.greenMetal)),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(shortId, style: TextStyle(color: text, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
                            const SizedBox(height: 2),
                            Text('Factura #${s['numeroFactura'] ?? id}', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w600)),
                          ]),
                          const Spacer(),
                          Text(formatCop(total), style: const TextStyle(color: AppTheme.greenMetal, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3)),
                        ]),
                      ),
                    );
                  }),
                const SizedBox(height: 20),

                // ── TOP PRODUCTOS ──
                _sectionH('PRODUCTOS TOP', Icons.workspace_premium_rounded, const Color(0xFFF59E0B), null),
                const SizedBox(height: 12),
                if (_ctrl.topProducts.isEmpty)
                  _emptyCard('Sin ventas hoy', Icons.shopping_bag_rounded, Colors.grey)
                else
                  ..._ctrl.topProducts.take(3).toList().asMap().entries.map((e) {
                    final i = e.key; final p = e.value;
                    final name = p['nombre']?.toString() ?? 'Producto';
                    final qty = (p['unidadesVendidas'] as num? ?? 0).toInt();
                    final colors = [const Color(0xFFF59E0B), Colors.grey.shade400, const Color(0xFFCD7F32)];
                    return HoverScale(
                      scale: 1.015,
                      elevation: 4,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors[i].withValues(alpha: 0.15))),
                        child: Row(children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(color: colors[i].withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                            child: Center(child: Text('#${i + 1}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: colors[i]))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(name, style: TextStyle(color: text, fontWeight: FontWeight.w800, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            ClipRRect(borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(value: (3 - i) / 3, minHeight: 3,
                                backgroundColor: colors[i].withValues(alpha: 0.08), valueColor: AlwaysStoppedAnimation(colors[i]))),
                          ])),
                          const SizedBox(width: 12),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: colors[i].withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                            child: Text('$qty uds', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: colors[i]))),
                        ]),
                      ),
                    );
                  }),
              ])),
            ),

              const SizedBox(width: 24),

              // ── RIGHT COLUMN ──
              Expanded(
                flex: 2,
                child: AnimatedEntry(
                  index: 6,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── STOCK HEALTH ──
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.ayanamiBlue.withValues(alpha: 0.1))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.ayanamiBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.health_and_safety_rounded, color: AppTheme.ayanamiBlue, size: 18)),
                      const SizedBox(width: 12),
                      Text('SALUD DEL STOCK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1)),
                      const Spacer(),
                      Text('${(_ctrl.stockHealthPercent * 100).toInt()}%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                        color: _ctrl.stockHealthPercent >= 0.7 ? AppTheme.greenMetal : _ctrl.stockHealthPercent >= 0.4 ? const Color(0xFFF59E0B) : AppTheme.reiOrangeRed)),
                    ]),
                    const SizedBox(height: 16),
                    ClipRRect(borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: _ctrl.stockHealthPercent, minHeight: 8,
                        backgroundColor: Colors.grey.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(
                          _ctrl.stockHealthPercent >= 0.7 ? AppTheme.greenMetal : _ctrl.stockHealthPercent >= 0.4 ? const Color(0xFFF59E0B) : AppTheme.reiOrangeRed))),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── ALERTAS ──
                _sectionH('ALERTAS', Icons.notifications_active_rounded, AppTheme.reiOrangeRed, null),
                const SizedBox(height: 12),
                if (_ctrl.alertsStock.isEmpty && _ctrl.alertsVencimiento.isEmpty)
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.greenMetal.withValues(alpha: 0.1))),
                    child: Row(children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.greenMetal.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.check_circle_rounded, color: AppTheme.greenMetal, size: 18)),
                      const SizedBox(width: 12),
                      Text('Sin alertas activas', style: TextStyle(color: AppTheme.greenMetal, fontWeight: FontWeight.w800, fontSize: 13)),
                    ]))
                else ...[
                  if (_ctrl.alertsStock.isNotEmpty) ..._ctrl.alertsStock.take(3).map((a) => HoverScale(
                    scale: 1.015,
                    elevation: 4,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12),
                        border: Border(left: BorderSide(color: AppTheme.reiOrangeRed.withValues(alpha: 0.4), width: 3))),
                      child: Row(children: [
                        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.reiOrangeRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.inventory_rounded, color: AppTheme.reiOrangeRed, size: 14)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(a['nombre']?.toString() ?? 'Producto', style: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 12))),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.reiOrangeRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Stock bajo', style: TextStyle(color: AppTheme.reiOrangeRed, fontWeight: FontWeight.w800, fontSize: 9))),
                      ]),
                    ),
                  )),
                  if (_ctrl.alertsVencimiento.isNotEmpty) ..._ctrl.alertsVencimiento.take(3).map((a) => HoverScale(
                    scale: 1.015,
                    elevation: 4,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12),
                        border: Border(left: BorderSide(color: Colors.orange.withValues(alpha: 0.4), width: 3))),
                      child: Row(children: [
                        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.schedule_rounded, color: Colors.orange, size: 14)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(a['productoNombre']?.toString() ?? 'Lote', style: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 12))),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Por vencer', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w800, fontSize: 9))),
                      ]),
                    ),
                  )),
                ],
                const SizedBox(height: 20),

                // ── ACCESO RÁPIDO ──
                _sectionH('ACCESO RÁPIDO', Icons.flash_on_rounded, const Color(0xFF8B5CF6), null),
                const SizedBox(height: 12),
                Row(children: [
                  _moduleBtn('Venta', Icons.point_of_sale_rounded, AppTheme.greenMetal, () => _go(2)),
                  const SizedBox(width: 10),
                  _moduleBtn('Almacén', Icons.inventory_2_rounded, AppTheme.ayanamiBlue, () => _go(1)),
                ]),
                const SizedBox(height: 10),
                if (UserSession.isDueno) Row(children: [
                  _moduleBtn('Lotes', Icons.layers_rounded, AppTheme.reiOrangeRed, () => _go(3)),
                  const SizedBox(width: 10),
                  _moduleBtn('Stats', Icons.insights_rounded, const Color(0xFF8B5CF6), () => _go(4)),
                ]),
              ])),
            ),
          ]),
        ]),
        ),

        // ── HEADER ──
        Positioned(top: 0, left: 0, right: 0,
          child: Container(height: 80, padding: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(color: bg,
              border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.08)))),
            child: Row(children: [
              IconButton(icon: Icon(Icons.menu_rounded, color: text, size: 26),
                onPressed: () {
                  ScaffoldState? s = Scaffold.maybeOf(context);
                  while (s != null && !s.hasDrawer) s = s.context.findAncestorStateOfType<ScaffoldState>();
                  s?.openDrawer();
                }),
              const SizedBox(width: 12),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.ayanamiBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.local_pharmacy_rounded, color: AppTheme.ayanamiBlue, size: 22)),
              const SizedBox(width: 10),
              Text('FARMABOOK', style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const Spacer(),
              if (UserSession.role == null || UserSession.isDueno) IconButton(icon: Icon(Icons.settings_outlined, color: text.withValues(alpha: 0.5)), onPressed: () => GoRouter.of(context).push('/configuracion')),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _sectionH(String t, IconData ic, Color c, Widget? action) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Icon(ic, size: 14, color: c)),
      const SizedBox(width: 10),
      Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
      const Spacer(),
      if (action != null) action,
    ]);
  }

  Widget _kpi(String label, String value, IconData icon, Color color, double raw, VoidCallback onTap, {bool isPct = false, required int index}) {
    return Expanded(child: AnimatedEntry(
      index: index,
      child: HoverScale(
        scale: 1.015,
        elevation: 6,
        onTap: onTap,
        child: InkWell(
          onTap: onTap, borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.12)),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 18)),
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              ]),
              const SizedBox(height: 14),
              Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.8)),
              const SizedBox(height: 4),
              Row(children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (isPct)
                  ClipRRect(borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(value: raw.clamp(0, 1), minHeight: 3, backgroundColor: color.withValues(alpha: 0.08), valueColor: AlwaysStoppedAnimation(color))),
                if (!isPct && raw != 0)
                  Icon(Icons.arrow_forward_ios_rounded, size: 8, color: color.withValues(alpha: 0.3)),
              ]),
            ]),
          ),
        ),
      ),
    ));
  }

  Widget _moduleBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(child: HoverScale(
      scale: 1.03,
      elevation: 4,
      onTap: onTap,
      child: InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.12)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.03), blurRadius: 8)],
        ),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        ]),
      ),
    )));
  }

  Widget _emptyCard(String msg, IconData icon, Color c) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withValues(alpha: 0.06))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: c, size: 16), const SizedBox(width: 10),
        Text(msg, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }

  Widget _errorView() => Scaffold(body: ErrorDisplay.fullScreen(
    message: _ctrl.error!,
    onRetry: _ctrl.cargarDatos,
  ));
}
