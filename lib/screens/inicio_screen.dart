import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../controllers/inicio_controller.dart';
import '../utils/price_formatter.dart';
import '../controllers/dashboard_controller.dart';
import '../theme/app_theme.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});
  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> with TickerProviderStateMixin {
  final InicioController _ctrl = InicioController();
  late AnimationController _pulse;
  late AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _ctrl.touch();
    _ctrl.addListener(() { if (mounted) setState(() {}); });
    _ctrl.init();
    _pulse = AnimationController(duration: const Duration(milliseconds: 1800), vsync: this)..repeat();
    _fade  = AnimationController(duration: const Duration(milliseconds: 700), vsync: this)..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose(); _pulse.dispose(); _fade.dispose();
    super.dispose();
  }

  void _go(int i) => Provider.of<DashboardController>(context, listen: false).onItemTapped(i);

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg    = Theme.of(context).scaffoldBackgroundColor;
    final card  = Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF1A1A1A) : Colors.white);
    final text  = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    if (_ctrl.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.ayanamiBlue)));
    if (_ctrl.error != null) return _errorView();

    return Scaffold(
      backgroundColor: bg,
      body: FadeTransition(
        opacity: _fade,
        child: Stack(children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(40, 116, 40, 60),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── GREETING ──────────────────────────────────────────
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_greet(), style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('FarmaBook Dashboard', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _dot(AppTheme.greenMetal),
                    const SizedBox(width: 8),
                    Text(DateFormat("EEEE d 'de' MMMM  •  HH:mm", 'es').format(DateTime.now()),
                      style: const TextStyle(color: AppTheme.greenMetal, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ]),
                ])),
                const SizedBox(width: 24),
                _quickActionBtn('Nueva Venta', Icons.point_of_sale_rounded, AppTheme.ayanamiBlue, () => _go(2)),
              ]),
              const SizedBox(height: 40),

              // ── KPIs ───────────────────────────────────────────────
              Row(children: [
                _kpi('Ingresos del Mes', formatCop(_ctrl.ingresos), Icons.trending_up_rounded, AppTheme.greenMetal, () => _go(4)),
                const SizedBox(width: 20),
                _kpi('Egresos Totales', formatCop(_ctrl.egresos), Icons.trending_down_rounded, AppTheme.reiOrangeRed, () => _go(4)),
                const SizedBox(width: 20),
                _kpi('Balance Neto', formatCop(_ctrl.ingresos - _ctrl.egresos), Icons.account_balance_wallet_rounded, const Color(0xFF8B5CF6), () => _go(4)),
                const SizedBox(width: 20),
                _kpi('Salud Inventario', '${(_ctrl.stockHealthPercent * 100).toInt()}%', Icons.inventory_2_rounded, AppTheme.ayanamiBlue, () => _go(1)),
              ]),
              const SizedBox(height: 32),

              // ── MAIN AREA ──────────────────────────────────────────
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Left: Chart + Ventas Recientes
                Expanded(flex: 3, child: Column(children: [
                  _chartCard(card, text),
                  const SizedBox(height: 24),
                  _recentSalesCard(card, text),
                ])),

                const SizedBox(width: 24),

                // Right: Alerts + Top Products
                Expanded(flex: 2, child: Column(children: [
                  _alertsCard(card, text),
                  const SizedBox(height: 24),
                  _topProductsCard(card, text),
                ])),
              ]),
              const SizedBox(height: 32),

              // ── MÓDULOS RÁPIDOS ────────────────────────────────────
              _moduleGrid(card, text),

            ]),
          ),
          _header(bg, text),
        ]),
      ),
    );
  }

  // ─────────────── WIDGETS ───────────────────────────────────────
  Widget _dot(Color c) => Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  Widget _pulseDot(Color c) => AnimatedBuilder(
    animation: _pulse,
    builder: (_, __) => SizedBox(width: 20, height: 20, child: Stack(alignment: Alignment.center, children: [
      Container(width: 20 * _pulse.value, height: 20 * _pulse.value,
        decoration: BoxDecoration(color: c.withOpacity(1 - _pulse.value), shape: BoxShape.circle)),
      Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    ])),
  );

  Widget _quickActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
      ),
      onPressed: onTap,
    );
  }

  Widget _kpi(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(child: InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5))),
          ])),
        ]),
      ),
    ));
  }

  Widget _chartCard(Color card, Color text) {
    final months = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    final cur = DateTime.now().month - 1;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _boxDeco(card),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Flujo Financiero', style: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w900)),
            Text('Comparativa ingresos vs egresos mensual', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ]),
          Row(children: [
            _legendDot('Ingresos', AppTheme.greenMetal),
            const SizedBox(width: 20),
            _legendDot('Egresos', AppTheme.reiOrangeRed),
          ]),
        ]),
        const SizedBox(height: 24),
        SizedBox(height: 260, child: BarChart(BarChartData(
          gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.06), strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44,
              getTitlesWidget: (v, _) => Text('\$${v.toInt()}', style: TextStyle(fontSize: 9, color: Colors.grey.shade400, fontWeight: FontWeight.w700)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i >= months.length) return const SizedBox();
                return Padding(padding: const EdgeInsets.only(top: 10),
                  child: Text(months[i], style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                    color: i == cur ? AppTheme.ayanamiBlue : Colors.grey.withOpacity(0.4))));
              })),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: List.generate(12, (i) {
            final ing = i == cur ? _ctrl.ingresos : 0.0;
            final egr = i == cur ? _ctrl.egresos : 0.0;
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(toY: ing > 0 ? ing : 0.5, color: i == cur ? AppTheme.greenMetal : AppTheme.greenMetal.withOpacity(0.12), width: 16, borderRadius: BorderRadius.circular(6)),
              BarChartRodData(toY: egr > 0 ? egr : 0.5, color: i == cur ? AppTheme.reiOrangeRed : AppTheme.reiOrangeRed.withOpacity(0.12), width: 16, borderRadius: BorderRadius.circular(6)),
            ]);
          }),
        ))),
      ]),
    );
  }

  Widget _recentSalesCard(Color card, Color text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _boxDeco(card),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            const Icon(Icons.receipt_long_rounded, color: AppTheme.ayanamiBlue, size: 20),
            const SizedBox(width: 12),
            Text('Ventas Recientes', style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox.shrink(),
        ]),
        const Divider(height: 24),
        if (_ctrl.recentSales.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('Sin ventas registradas hoy', style: TextStyle(color: Colors.grey, fontSize: 13)))
        else
          ..._ctrl.recentSales.take(5).map((s) {
            final total = double.tryParse(s['total']?.toString() ?? '0') ?? 0;
            final id = s['ventaId']?.toString() ?? '';
            final shortId = id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
            final items = (s['productosVendidos'] as List? ?? []);
            final desc = items.isEmpty ? 'Sin detalle' : items.map((i) => i['nombre']).take(2).join(', ');
            return Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.greenMetal.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.greenMetal, size: 18)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('#$shortId', style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.w900)),
                Text(desc, style: TextStyle(color: Colors.grey.shade500, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Text(formatCop(total), style: const TextStyle(color: AppTheme.greenMetal, fontWeight: FontWeight.w900, fontSize: 15)),
            ]));
          }),
      ]),
    );
  }

  Widget _alertsCard(Color card, Color text) {
    final totalAlerts = _ctrl.alertsStock.length + _ctrl.alertsVencimiento.length;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: card, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: totalAlerts > 0 ? AppTheme.reiOrangeRed.withOpacity(0.25) : Colors.transparent),
        boxShadow: [BoxShadow(color: totalAlerts > 0 ? AppTheme.reiOrangeRed.withOpacity(0.06) : Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _pulseDot(totalAlerts > 0 ? AppTheme.reiOrangeRed : AppTheme.greenMetal),
          const SizedBox(width: 12),
          Expanded(child: Text(totalAlerts > 0 ? '$totalAlerts Alertas Activas' : 'Sin Alertas', style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w900))),
          const SizedBox.shrink(),
        ]),
        const Divider(height: 20),
        if (totalAlerts == 0)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Row(children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.greenMetal, size: 18),
            SizedBox(width: 10),
            Text('Sistemas operando sin novedad', style: TextStyle(color: AppTheme.greenMetal, fontWeight: FontWeight.w800, fontSize: 12)),
          ]))
        else ...[
          ..._ctrl.alertsStock.take(3).map((a) => _alertRow(a['nombre'] ?? 'Producto', 'Stock crítico — baja disponibilidad', AppTheme.reiOrangeRed)),
          ..._ctrl.alertsVencimiento.take(3).map((a) => _alertRow(a['productoNombre'] ?? 'Lote', 'Próximo a vencer', Colors.orange)),
        ],
      ]),
    );
  }

  Widget _alertRow(String name, String subtitle, Color color) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.warning_amber_rounded, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(subtitle, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
      ])),
    ]));
  }

  Widget _topProductsCard(Color card, Color text) {
    final tops = _ctrl.topProducts;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _boxDeco(card),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 12),
          Text('Top Productos', style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w900)),
        ]),
        const Divider(height: 24),
        if (tops.isEmpty) const Text('Sin datos', style: TextStyle(color: Colors.grey, fontSize: 12))
        else ...tops.take(5).toList().asMap().entries.map((entry) {
          final i = entry.key; final p = entry.value;
          const colors = [Color(0xFFF59E0B), Color(0xFF94A3B8), Color(0xFFB45309), AppTheme.ayanamiBlue, AppTheme.greenMetal];
          return Padding(padding: const EdgeInsets.only(bottom: 14), child: Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: colors[i % colors.length].withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: colors[i % colors.length])))),
            const SizedBox(width: 12),
            Expanded(child: Text(p['nombre'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text(formatCop((p['ingresosGenerados'] as num? ?? 0)), style: TextStyle(color: colors[i % colors.length], fontWeight: FontWeight.w900, fontSize: 14)),
          ]));
        }),
      ]),
    );
  }

  Widget _moduleGrid(Color card, Color text) {
    final modules = [
      ('Almacén Central', Icons.inventory_2_rounded, AppTheme.ayanamiBlue, 1),
      ('Punto de Venta', Icons.point_of_sale_rounded, AppTheme.greenMetal, 2),
      ('Gestión de Lotes', Icons.layers_rounded, AppTheme.reiOrangeRed, 3),
      ('Estadísticas', Icons.insights_rounded, const Color(0xFF8B5CF6), 4),
      ('Manual de Ayuda', Icons.menu_book_rounded, AppTheme.ayanamiBlue, 11),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('ACCESO RÁPIDO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
        const SizedBox(width: 16),
        Expanded(child: Divider(color: Colors.grey.withOpacity(0.15))),
      ]),
      const SizedBox(height: 20),
      Row(children: modules.map((m) => Expanded(child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: InkWell(
          onTap: () => _go(m.$4), borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: card, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: m.$3.withOpacity(0.1)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: m.$3.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(m.$2, color: m.$3, size: 22)),
              const SizedBox(height: 10),
              Text(m.$1, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.w800), textAlign: TextAlign.center, maxLines: 2),
            ]),
          ),
        ),
      ))).toList()),
    ]);
  }

  Widget _legendDot(String label, Color c) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w700)),
  ]);

  BoxDecoration _boxDeco(Color card) => BoxDecoration(
    color: card, borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.grey.withOpacity(0.08)),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.025), blurRadius: 20, offset: const Offset(0, 6))],
  );

  // ─────────────── HEADER ─────────────────────────────────────────
  Widget _header(Color bg, Color text) {
    return Positioned(top: 0, left: 0, right: 0,
      child: ClipRRect(child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: bg.withOpacity(0.78),
            border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              IconButton(
                icon: Icon(Icons.menu_rounded, color: text, size: 26),
                onPressed: () {
                  ScaffoldState? s = Scaffold.maybeOf(context);
                  while (s != null && !s.hasDrawer) s = s.context.findAncestorStateOfType<ScaffoldState>();
                  s?.openDrawer();
                },
              ),
              const SizedBox(width: 16),
              Row(children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.ayanamiBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.local_pharmacy_rounded, color: AppTheme.ayanamiBlue, size: 22)),
                const SizedBox(width: 12),
                Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('FARMABOOK', style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  Row(children: [_pulseDot(AppTheme.greenMetal), const SizedBox(width: 6), const Text('SISTEMA EN LÍNEA', style: TextStyle(color: AppTheme.greenMetal, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5))]),
                ]),
              ]),
            ]),
            Row(children: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, size: 20, color: text.withOpacity(0.7)),
                onPressed: () => _ctrl.cargarDatos(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(icon: Icon(Icons.settings_outlined, color: text), onPressed: () => GoRouter.of(context).push('/configuracion')),
            ]),
          ]),
        ),
      )),
    );
  }

  Widget _errorView() => Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.cloud_off_rounded, size: 80, color: AppTheme.reiOrangeRed),
    const SizedBox(height: 16),
    Text(_ctrl.error!, style: const TextStyle(color: AppTheme.reiOrangeRed, fontWeight: FontWeight.bold)),
    const SizedBox(height: 24),
    ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Reintentar'), onPressed: _ctrl.cargarDatos,
      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.ayanamiBlue, foregroundColor: Colors.white)),
  ])));
}
