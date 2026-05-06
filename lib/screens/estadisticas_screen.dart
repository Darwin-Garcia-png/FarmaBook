import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/estadisticas_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_header.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});
  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  final EstadisticasController _c = EstadisticasController();
  bool _isPdf = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(() { if (mounted) setState(() {}); });
    _c.init();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  // ─────────────── HELPERS ────────────────────────────────────────
  static const _colors = [AppTheme.ayanamiBlue, AppTheme.greenMetal, Color(0xFFF59E0B), AppTheme.reiOrangeRed, Color(0xFF8B5CF6)];

  String _fmt(double v) => '\$${v.toStringAsFixed(2)}';

  Widget _card({required Widget child, Color? accent}) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: (accent ?? Colors.grey).withOpacity(0.12)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 24, offset: const Offset(0, 8))],
    ),
    child: child,
  );

  Widget _kpi(String label, String value, IconData icon, Color color, {String? sub}) => _card(
    accent: color,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 24)),
      const SizedBox(height: 20),
      Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1)),
      if (sub != null) ...[const SizedBox(height: 4), Text(sub, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700))],
    ]),
  );

  Widget _section(String label, {required Widget child}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
      const SizedBox(width: 16),
      Expanded(child: Divider(color: Colors.grey.withOpacity(0.15))),
    ]),
    const SizedBox(height: 20),
    child,
  ]);

  // ─────────────── BUILD ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumHeader(
        title: 'Análisis Estratégico',
        subtitle: 'Inteligencia de negocio en tiempo real',
        icon: Icons.insights_rounded,
        baseColor: AppTheme.ayanamiBlue,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton.icon(
            icon: _isPdf ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.picture_as_pdf_rounded, size: 16),
            label: const Text('PDF', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.reiOrangeRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            onPressed: _isPdf ? null : () async {
              setState(() => _isPdf = true);
              try { await _c.downloadPdfReport(); } catch (_) {} finally { if (mounted) setState(() => _isPdf = false); }
            },
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.summarize_rounded, size: 16),
            label: const Text('RESUMEN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.ayanamiBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
            onPressed: () => _showSummary(),
          ),
          const SizedBox(width: 10),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppTheme.ayanamiBlue), onPressed: _c.cargarEstadisticas),
        ]),
      ),
      body: _c.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(32),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  if (_c.error != null) _errorBanner(),
                  _section('MÉTRICAS DE HOY', child: _todayGrid()),
                  const SizedBox(height: 40),
                  _section('INGRESOS POR HORA — HOY', child: _hourlyChart()),
                  const SizedBox(height: 40),
                  _section('RENDIMIENTO MENSUAL', child: _monthlyGrid()),
                  const SizedBox(height: 40),
                  _section('TENDENCIA DIARIA DEL MES', child: _trendChart()),
                  const SizedBox(height: 40),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 3, child: _section('RANKINGS DE PRODUCTOS', child: _rankingsRow())),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _section('VENTAS POR CATEGORÍA', child: _donut())),
                  ]),
                  const SizedBox(height: 60),
                ])),
              ),
            ]),
    );
  }

  // ─────────────── SECCIONES ──────────────────────────────────────
  Widget _todayGrid() => GridView.count(
    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 4, childAspectRatio: 1.5, mainAxisSpacing: 20, crossAxisSpacing: 20,
    children: [
      _kpi('Ingresos Hoy', _fmt(_c.ingresosHoy), Icons.payments_rounded, AppTheme.ayanamiBlue),
      _kpi('Ventas Realizadas', '${_c.ventasHoy} facturas', Icons.receipt_long_rounded, AppTheme.greenMetal),
      _kpi('Ticket Promedio', _fmt(_c.averageTicket), Icons.analytics_rounded, const Color(0xFF8B5CF6)),
      _kpi('Ticket Máximo', _fmt(_c.ticketMaximo), Icons.arrow_upward_rounded, AppTheme.greenMetal, sub: 'Venta más grande del día'),
      _kpi('Ticket Mínimo', _fmt(_c.ticketMinimo), Icons.arrow_downward_rounded, Colors.orange, sub: 'Venta más pequeña del día'),
      _kpi('Unidades Vendidas', '${_c.totalUnidadesHoy} uds', Icons.inventory_2_rounded, AppTheme.reiOrangeRed),
      _kpi('Hora Pico', '${_c.peakHour.toString().padLeft(2,'0')}:00', Icons.schedule_rounded, AppTheme.ayanamiBlue, sub: '${_c.peakHourCount} ventas esa hora'),
      _kpi('Horario Activo', '${_c.primeraVentaHora} – ${_c.ultimaVentaHora}', Icons.access_time_filled_rounded, Colors.blueGrey, sub: 'Primera → Última venta'),
    ],
  );

  Widget _hourlyChart() {
    final hours = List.generate(24, (i) => i);
    final maxVal = _c.ingresosPorHora.values.fold(0.0, (m, v) => v > m ? v : m);

    return _card(child: SizedBox(
      height: 200,
      child: BarChart(BarChartData(
        maxY: maxVal > 0 ? maxVal * 1.2 : 10,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 2, getTitlesWidget: (v, _) => Text('${v.toInt()}h', style: const TextStyle(fontSize: 9, color: Colors.grey)))),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: hours.map((h) {
          final val = _c.ingresosPorHora[h] ?? 0;
          final isPeak = h == _c.peakHour && val > 0;
          return BarChartGroupData(x: h, barRods: [
            BarChartRodData(toY: val, width: 12, borderRadius: BorderRadius.circular(4),
              color: isPeak ? AppTheme.ayanamiBlue : AppTheme.ayanamiBlue.withOpacity(0.25)),
          ]);
        }).toList(),
      )),
    ));
  }

  Widget _monthlyGrid() => GridView.count(
    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 4, childAspectRatio: 1.5, mainAxisSpacing: 20, crossAxisSpacing: 20,
    children: [
      _kpi('Ingresos del Mes', _fmt(_c.ingresosMes), Icons.calendar_month_rounded, AppTheme.ayanamiBlue),
      _kpi('Ventas del Mes', '${_c.ventasMes} facturas', Icons.shopping_bag_rounded, AppTheme.greenMetal),
      _kpi('Egresos (Inventario)', _fmt(_c.egresosMes), Icons.trending_down_rounded, AppTheme.reiOrangeRed),
      _kpi('Balance Neto', _fmt(_c.balanceMes), Icons.account_balance_wallet_rounded, const Color(0xFF8B5CF6)),
      _kpi('Promedio Diario', _fmt(_c.promedioVentaDiaria), Icons.bar_chart_rounded, Colors.orange, sub: 'Ingreso medio por día'),
      _kpi('Mejor Día del Mes', 'Día ${_c.mejorDiaMes}', Icons.workspace_premium_rounded, AppTheme.greenMetal, sub: _fmt(_c.mejorDiaIngresos)),
      _kpi('Días con Ventas', '${_c.diasConVentas} días', Icons.event_available_rounded, AppTheme.ayanamiBlue),
      _kpi('Margen Operativo', _c.ingresosMes > 0 ? '${((_c.balanceMes / _c.ingresosMes) * 100).toStringAsFixed(1)}%' : '--%', Icons.percent_rounded, const Color(0xFF8B5CF6), sub: 'Balance / Ingresos mes'),
    ],
  );

  Widget _trendChart() => _card(child: SizedBox(
    height: 280,
    child: LineChart(LineChartData(
      gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.06), strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 5, getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 8), child: Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey))))),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 48, getTitlesWidget: (v, _) => Text('\$${v.toInt()}', style: const TextStyle(fontSize: 9, color: Colors.grey)))),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [LineChartBarData(
        spots: _c.dailyTrend.map((e) => FlSpot(e['day'].toDouble(), e['total'] as double)).toList(),
        isCurved: true, color: AppTheme.ayanamiBlue, barWidth: 5, isStrokeCapRound: true,
        dotData: FlDotData(show: true, getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(radius: spot.y > 0 ? 3 : 0, color: AppTheme.ayanamiBlue, strokeWidth: 0)),
        belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.ayanamiBlue.withOpacity(0.18), Colors.transparent])),
      )],
    )),
  ));

  Widget _rankingsRow() => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child: _rankList('Top Hoy', _c.topProductosHoy, Icons.bolt_rounded)),
    const SizedBox(width: 16),
    Expanded(child: _rankList('Top Mes', _c.topProductosMes, Icons.calendar_today_rounded)),
    const SizedBox(width: 16),
    Expanded(child: _rankList('Top Global', _c.topProductosGlobal, Icons.workspace_premium_rounded)),
  ]);

  Widget _rankList(String title, List items, IconData icon) => _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(icon, color: AppTheme.ayanamiBlue, size: 16), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5))]),
    const SizedBox(height: 16),
    if (items.isEmpty) const Text('Sin datos', style: TextStyle(color: Colors.grey, fontSize: 12))
    else ...items.take(5).toList().asMap().entries.map((entry) {
      final i = entry.key; final p = entry.value;
      return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
        Container(width: 24, height: 24, decoration: BoxDecoration(color: _colors[i % _colors.length].withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _colors[i % _colors.length])))),
        const SizedBox(width: 10),
        Expanded(child: Text(p['nombre'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Text('${p['unidadesVendidas']} u', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
      ]));
    }),
  ]));

  Widget _donut() {
    final entries = _c.categoryData.entries.take(5).toList();
    final total = entries.fold(0.0, (s, e) => s + e.value);
    final sections = entries.indexed.map(((int, MapEntry<String, double>) rec) {
      final (i, e) = rec;
      return PieChartSectionData(color: _colors[i % _colors.length], value: e.value, title: '', radius: 28);
    }).toList();

    return _card(child: Column(children: [
      SizedBox(height: 180, child: PieChart(PieChartData(sections: sections.isEmpty ? [PieChartSectionData(color: Colors.grey.shade200, value: 1, title: '')] : sections, centerSpaceRadius: 45, sectionsSpace: 2))),
      const SizedBox(height: 20),
      if (entries.isEmpty) const Text('Sin datos de categorías', style: TextStyle(color: Colors.grey, fontSize: 12))
      else ...entries.indexed.map(((int, MapEntry<String, double>) rec) {
        final (i, e) = rec;
        final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0';
        return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: _colors[i % _colors.length], borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Expanded(child: Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          Text('$pct%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _colors[i % _colors.length])),
        ]));
      }),
    ]));
  }

  Widget _errorBanner() => Container(
    padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 24),
    decoration: BoxDecoration(color: AppTheme.reiOrangeRed.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.reiOrangeRed.withOpacity(0.3))),
    child: Row(children: [const Icon(Icons.warning_amber_rounded, color: AppTheme.reiOrangeRed), const SizedBox(width: 12), Expanded(child: Text(_c.error!, style: const TextStyle(color: AppTheme.reiOrangeRed)))]),
  );

  // ─────────────── MODAL RESUMEN DEL DÍA ──────────────────────────
  void _showSummary() {
    final s = _c.dailySummary;
    if (s.isEmpty) return;

    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 580,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(32)),
        child: Column(children: [
          // Header
          Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.ayanamiBlue, AppTheme.ayanamiBlue.withOpacity(0.8)]), borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
            child: Row(children: [
              const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('CIERRE DE CAJA', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                Text('${s['fecha']}  •  Generado: ${s['hora']} hrs', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ])),
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
            ]),
          ),
          // Content
          Flexible(child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            _modalSection('💰 RESUMEN FINANCIERO', [
              _modalRow('Ingresos Brutos', _fmt(s['ingresos']), bold: true, color: AppTheme.greenMetal),
              _modalRow('Ventas Totales', '${s['ventas']} facturas emitidas'),
              _modalRow('Ticket Promedio', _fmt(s['ticketPromedio'])),
              _modalRow('Ticket Más Alto', _fmt(s['ticketMaximo']), color: AppTheme.greenMetal),
              _modalRow('Ticket Más Bajo', _fmt(s['ticketMinimo']), color: Colors.orange),
            ]),
            const SizedBox(height: 20),

            _modalSection('📦 ACTIVIDAD OPERATIVA', [
              _modalRow('Unidades Despachadas', '${s['totalUnidades']} unidades en total'),
              _modalRow('Primera Venta del Día', '${s['primeraVenta']} hrs'),
              _modalRow('Última Venta del Día', '${s['ultimaVenta']} hrs'),
              _modalRow('Hora Pico', '${s['horaPico']}  (${s['horaPicoVentas']} ventas)'),
              _modalRow('Producto Estrella', '${s['productoEstrella']} — ${s['unidadesEstrella']} uds'),
            ]),
            const SizedBox(height: 20),

            if ((s['top5Hoy'] as List).isNotEmpty) ...[
              _modalSection('🏆 TOP 5 PRODUCTOS HOY', (s['top5Hoy'] as List).map<Widget>((p) =>
                Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
                  const Icon(Icons.fiber_manual_record, size: 8, color: AppTheme.ayanamiBlue),
                  const SizedBox(width: 10),
                  Expanded(child: Text(p['nombre'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  Text('${p['unidades']} unidades', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.ayanamiBlue)),
                ])),
              ).toList()),
              const SizedBox(height: 20),
            ],

            _modalSection('📅 CONTEXTO MENSUAL', [
              _modalRow('Ingresos del Mes', _fmt(s['ingresosMes']), bold: true),
              _modalRow('Ventas del Mes', '${s['ventasMes']} facturas'),
              _modalRow('Promedio Diario', _fmt(s['promedioDiario'])),
              _modalRow('Mejor Día del Mes', 'Día ${s['mejorDia']}  →  ${_fmt(s['mejorDiaTotal'])}', color: AppTheme.greenMetal),
              _modalRow('Días con Actividad', '${s['diasConVentas']} días con ventas'),
              _modalRow('Egresos (Inventario)', _fmt(s['egresosMes']), color: AppTheme.reiOrangeRed),
              _modalRow('Balance Neto', _fmt(s['balanceMes']), bold: true, color: s['balanceMes'] >= 0 ? AppTheme.greenMetal : AppTheme.reiOrangeRed),
            ]),
          ]))),
        ]),
      ),
    ));
  }

  Widget _modalSection(String title, List<Widget> rows) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
    const SizedBox(height: 12),
    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(16)), child: Column(children: rows)),
  ]);

  Widget _modalRow(String label, String value, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500))),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w900 : FontWeight.w700, color: color)),
    ]),
  );
}

extension IndexedIterable<T> on Iterable<T> {
  Iterable<(int, T)> get indexed sync* {
    int i = 0;
    for (final v in this) yield (i++, v);
  }
}