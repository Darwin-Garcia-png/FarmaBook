import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/estadisticas_controller.dart';
import '../utils/price_formatter.dart';
import '../theme/app_theme.dart';
import '../widgets/error_display.dart';

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
    _c.touch();
    _c.addListener(() { if (mounted) setState(() {}); });
    _c.init();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  static const _colors = [AppTheme.ayanamiBlue, AppTheme.greenMetal, Color(0xFFF59E0B), AppTheme.reiOrangeRed, Color(0xFF8B5CF6)];

  String _fmt(double v) => formatCop(v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Estadísticas', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(_isPdf ? Icons.hourglass_top : Icons.picture_as_pdf_rounded, color: AppTheme.reiOrangeRed),
            onPressed: _isPdf ? null : () async {
              setState(() => _isPdf = true);
              try {
                await _c.downloadPdfReport();
                if (mounted) ErrorDisplay.successSnackBar(context: context, message: 'PDF guardado en Descargas');
              } catch (_) {
                if (mounted) ErrorDisplay.snackBar(context: context, message: 'Error al guardar PDF', hint: 'Verifica que la carpeta Descargas exista y tengas permisos de escritura.');
              } finally { if (mounted) setState(() => _isPdf = false); }
            }),
          IconButton(icon: const Icon(Icons.summarize_rounded, color: AppTheme.ayanamiBlue), onPressed: _showSummary),
          IconButton(icon: Icon(Icons.refresh_rounded, color: Colors.grey.shade500), onPressed: _c.cargarEstadisticas),
        ],
      ),
      body: _c.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.ayanamiBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_c.error != null) _errorBanner(),

                // ── HOY ──
                _sectionH('RESUMEN DEL DÍA'),
                const SizedBox(height: 16),
                _card(Column(children: [
                  _row2(
                    _kpi('Ingresos Hoy', _fmt(_c.ingresosHoy), Icons.payments_rounded, AppTheme.ayanamiBlue),
                    _kpi('Ventas Hoy', '${_c.ventasHoy} facturas', Icons.receipt_long_rounded, AppTheme.greenMetal),
                  ),
                  const SizedBox(height: 16),
                  _row2(
                    _kpi('Ticket Promedio', _fmt(_c.averageTicket), Icons.analytics_rounded, const Color(0xFF8B5CF6)),
                    _kpi('Unidades', '${_c.totalUnidadesHoy} uds', Icons.inventory_2_rounded, AppTheme.reiOrangeRed),
                  ),
                  const SizedBox(height: 16),
                  _row2(
                    _kpi('Ticket Máximo', _fmt(_c.ticketMaximo), Icons.arrow_upward_rounded, AppTheme.greenMetal, sub: 'Venta más alta'),
                    _kpi('Ticket Mínimo', _fmt(_c.ticketMinimo), Icons.arrow_downward_rounded, Colors.orange, sub: 'Venta más baja'),
                  ),
                  const SizedBox(height: 16),
                  _row2(
                    _kpi('Hora Pico', '${_c.peakHour.toString().padLeft(2, '0')}:00', Icons.schedule_rounded, AppTheme.ayanamiBlue, sub: '${_c.peakHourCount} ventas'),
                    _kpi('Horario', '${_c.primeraVentaHora} – ${_c.ultimaVentaHora}', Icons.access_time_filled_rounded, Colors.blueGrey, sub: 'Primera → Última'),
                  ),
                ])),
                const SizedBox(height: 28),

                // ── GRÁFICA POR HORA ──
                _sectionH('VENTAS POR HORA'),
                const SizedBox(height: 16),
                _card(
                  SizedBox(height: 220, child: _hourlyChart()),
                ),
                const SizedBox(height: 28),

                // ── MES ──
                _sectionH('RENDIMIENTO MENSUAL'),
                const SizedBox(height: 16),
                _card(Column(children: [
                  _row2(
                    _kpi('Ingresos del Mes', _fmt(_c.ingresosMes), Icons.calendar_month_rounded, AppTheme.ayanamiBlue),
                    _kpi('Ventas del Mes', '${_c.ventasMes} facturas', Icons.shopping_bag_rounded, AppTheme.greenMetal),
                  ),
                  const SizedBox(height: 16),
                  _row2(
                    _kpi('Egresos (Inv.)', _fmt(_c.egresosMes), Icons.trending_down_rounded, AppTheme.reiOrangeRed),
                    _kpi('Balance Neto', _fmt(_c.balanceMes), Icons.account_balance_wallet_rounded, const Color(0xFF8B5CF6)),
                  ),
                  const SizedBox(height: 16),
                  _row2(
                    _kpi('Promedio/día', _fmt(_c.promedioVentaDiaria), Icons.bar_chart_rounded, Colors.orange, sub: 'Ingreso diario medio'),
                    _kpi('Mejor Día', 'Día ${_c.mejorDiaMes}', Icons.workspace_premium_rounded, AppTheme.greenMetal, sub: _fmt(_c.mejorDiaIngresos)),
                  ),
                  const SizedBox(height: 16),
                  _row2(
                    _kpi('Días con Ventas', '${_c.diasConVentas} días', Icons.event_available_rounded, AppTheme.ayanamiBlue),
                    _kpi('Margen', _c.ingresosMes > 0 ? '${((_c.balanceMes / _c.ingresosMes) * 100).toStringAsFixed(1)}%' : '--', Icons.percent_rounded, const Color(0xFF8B5CF6), sub: 'Balance / Ingresos'),
                  ),
                ])),
                const SizedBox(height: 28),

                // ── TENDENCIA DIARIA ──
                if (_c.dailyTrend.isNotEmpty) ...[
                  _sectionH('TENDENCIA DIARIA DEL MES'),
                  const SizedBox(height: 16),
                  _card(
                    SizedBox(height: 260, child: _trendChart()),
                  ),
                  const SizedBox(height: 28),
                ],

                // ── RANKINGS + DONUT ──
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: Column(children: [
                    _sectionH('TOP PRODUCTOS'),
                    const SizedBox(height: 16),
                    _card(Column(children: [
                      _rankBlock('HOY', _c.topProductosHoy, Icons.bolt_rounded),
                      const Divider(height: 24),
                      _rankBlock('MES', _c.topProductosMes, Icons.calendar_today_rounded),
                      const Divider(height: 24),
                      _rankBlock('GLOBAL', _c.topProductosGlobal, Icons.workspace_premium_rounded),
                    ])),
                  ])),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: Column(children: [
                    _sectionH('CATEGORÍAS'),
                    const SizedBox(height: 16),
                    _donut(),
                  ])),
                ]),
                const SizedBox(height: 28),

                // ── SUPPLIER RANKING ──
                if (_c.supplierRanking.isNotEmpty) ...[
                  _sectionH('PROVEEDORES POR COSTO'),
                  const SizedBox(height: 16),
                  _card(Column(children: [
                    ..._c.supplierRanking.take(10).toList().asMap().entries.map((e) {
                      final i = e.key;
                      final s = e.value;
                      final cost = double.tryParse(s['costoPromedio']?.toString() ?? '0') ?? 0;
                      final color = i == 0 ? AppTheme.greenMetal : (i == _c.supplierRanking.length - 1 ? AppTheme.reiOrangeRed : Colors.blueGrey);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                            child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s['nombre'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Text('\$${cost.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
                        ]),
                      );
                    }),
                  ])),
                  const SizedBox(height: 40),
                ],
              ]),
            ),
    );
  }

  Widget _sectionH(String t) => Row(children: [
    Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
    const SizedBox(width: 16), Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.15))),
  ]);

  Widget _card(Widget c) => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.08))),
    child: c,
  );

  Widget _row2(Widget a, Widget b) => Row(children: [
    Expanded(child: a), const SizedBox(width: 16), Expanded(child: b),
  ]);

  Widget _kpi(String l, String v, IconData ic, Color c, {String? sub}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.1))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(ic, color: c, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: c, letterSpacing: -0.3)),
          Text(l, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
          if (sub != null) Text(sub, style: TextStyle(fontSize: 9, color: c.withValues(alpha: 0.7), fontWeight: FontWeight.w600, fontStyle: FontStyle.italic)),
        ])),
      ]),
    );
  }

  Widget _hourlyChart() {
    final maxVal = _c.ingresosPorHora.values.fold(0.0, (m, v) => v > m ? v : m);
    return BarChart(BarChartData(
      maxY: maxVal > 0 ? maxVal * 1.2 : 10,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 2,
          getTitlesWidget: (v, _) => Text('${v.toInt()}h', style: const TextStyle(fontSize: 8, color: Colors.grey)))),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      barGroups: List.generate(24, (h) {
        final val = _c.ingresosPorHora[h] ?? 0;
        return BarChartGroupData(x: h, barRods: [
          BarChartRodData(toY: val, width: 8, borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            color: h == _c.peakHour && val > 0 ? AppTheme.ayanamiBlue : AppTheme.ayanamiBlue.withValues(alpha: 0.2)),
        ]);
      }),
    ));
  }

  Widget _trendChart() {
    final spots = _c.dailyTrend.map((e) => FlSpot((e['day'] as num).toDouble(), (e['total'] as num).toDouble())).toList();
    if (spots.isEmpty) return const SizedBox();
    final maxSpot = spots.reduce((a, b) => a.y > b.y ? a : b);
    final avg = spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length;
    return LineChart(LineChartData(
      gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(
        color: v == 0 || v == maxSpot.y ? Colors.grey.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.06),
        strokeWidth: v == 0 ? 1 : 0.5, dashArray: v == 0 ? null : [4, 4])),
      borderData: FlBorderData(show: false),
      minY: 0,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 3,
          getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 8),
            child: Text('Día ${v.toInt()}', style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w600))))),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 48,
          getTitlesWidget: (v, _) => Text( _fmt(v), style: TextStyle(fontSize: 8, color: Colors.grey.shade400, fontWeight: FontWeight.w600)))),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true, color: AppTheme.ayanamiBlue, barWidth: 3, isStrokeCapRound: true,
          dotData: FlDotData(show: true, getDotPainter: (spot, _, __, ___) =>
            FlDotCirclePainter(
              radius: spot == maxSpot ? 6 : (spot.y > 0 ? 3 : 0),
              color: Colors.white, strokeWidth: spot == maxSpot ? 3 : 2,
              strokeColor: spot == maxSpot ? const Color(0xFF8B5CF6) : AppTheme.ayanamiBlue.withValues(alpha: 0.5))),
          belowBarData: BarAreaData(show: true,
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [AppTheme.ayanamiBlue.withValues(alpha: 0.2), const Color(0xFF8B5CF6).withValues(alpha: 0.05), Colors.transparent])),
        ),
        if (avg > 0)
          LineChartBarData(
            spots: [FlSpot(spots.first.x, avg), FlSpot(spots.last.x, avg)],
            isCurved: false, color: Colors.orange.withValues(alpha: 0.5), barWidth: 1.5, dashArray: [6, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
      ],
      extraLinesData: ExtraLinesData(horizontalLines: avg > 0 ? [
        HorizontalLine(y: avg, color: Colors.orange.withValues(alpha: 0.5), strokeWidth: 1.5, dashArray: [6, 4],
          label: HorizontalLineLabel(show: true, alignment: Alignment.topRight,
            style: TextStyle(color: Colors.orange.shade400, fontSize: 9, fontWeight: FontWeight.w700),
            labelResolver: (_) => 'Prom ${_fmt(avg)}'))
      ] : []),
    ));
  }

  Widget _rankBlock(String t, List items, IconData ic) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(ic, color: AppTheme.ayanamiBlue, size: 14), const SizedBox(width: 6), Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12))]),
      const SizedBox(height: 10),
      if (items.isEmpty) const Padding(padding: EdgeInsets.only(bottom: 4), child: Text('Sin datos', style: TextStyle(color: Colors.grey, fontSize: 11)))
      else ...items.take(5).toList().asMap().entries.map((e) {
        final i = e.key; final p = e.value;
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
          Container(width: 20, height: 20, decoration: BoxDecoration(color: _colors[i % _colors.length].withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: _colors[i % _colors.length])))),
          const SizedBox(width: 8),
          Expanded(child: Text(p['nombre'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text('${p['unidadesVendidas']}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
        ]));
      }),
    ]);
  }

  Widget _donut() {
    final entries = _c.categoryData.entries.take(5).toList();
    final total = entries.fold(0.0, (s, e) => s + e.value);
    return _card(Column(children: [
      SizedBox(height: 150, child: PieChart(PieChartData(
        sections: entries.isEmpty
          ? [PieChartSectionData(color: Colors.grey.shade200, value: 1, title: '')]
          : entries.indexed.map(((int, MapEntry<String, double>) r) {
              final (i, e) = r;
              return PieChartSectionData(color: _colors[i % _colors.length], value: e.value, title: '', radius: 26);
            }).toList(),
        centerSpaceRadius: 38, sectionsSpace: 2,
      ))),
      const SizedBox(height: 16),
      if (entries.isEmpty) const Text('Sin datos de categorías', style: TextStyle(color: Colors.grey, fontSize: 11))
      else ...entries.indexed.map(((int, MapEntry<String, double>) r) {
        final (i, e) = r;
        final pct = total > 0 ? '${(e.value / total * 100).toStringAsFixed(1)}%' : '0%';
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: _colors[i % _colors.length], borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Expanded(child: Text(e.key, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          Text(pct, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _colors[i % _colors.length])),
        ]));
      }),
    ]));
  }

  Widget _errorBanner() => ErrorDisplay.inline(
    message: _c.error!,
    onDismiss: () => _c.error = null,
  );

  // ── SUMMARY DIALOG ──
  void _showSummary() {
    final s = _c.dailySummary;
    if (s.isEmpty) return;
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 540, constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(28)),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.ayanamiBlue, AppTheme.ayanamiBlue.withValues(alpha: 0.8)]), borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            child: Row(children: [
              const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('CIERRE DE CAJA', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                Text('${s['fecha']}  •  ${s['hora']} hrs', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
              ])),
              IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => Navigator.pop(ctx)),
            ]),
          ),
          Flexible(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _modalS('FINANCIERO', [
              _modalR('Ingresos Brutos', _fmt(s['ingresos']), bold: true, color: AppTheme.greenMetal),
              _modalR('Ventas Totales', '${s['ventas']} facturas'),
              _modalR('Ticket Promedio', _fmt(s['ticketPromedio'])),
              _modalR('Ticket Máximo', _fmt(s['ticketMaximo']), color: AppTheme.greenMetal),
              _modalR('Ticket Mínimo', _fmt(s['ticketMinimo']), color: Colors.orange),
            ]),
            const SizedBox(height: 16),
            _modalS('OPERATIVO', [
              _modalR('Unidades Despachadas', '${s['totalUnidades']} uds'),
              _modalR('Primera Venta', '${s['primeraVenta']} hrs'),
              _modalR('Última Venta', '${s['ultimaVenta']} hrs'),
              _modalR('Hora Pico', '${s['horaPico']} (${s['horaPicoVentas']} ventas)'),
              _modalR('Producto Estrella', '${s['productoEstrella']}'),
            ]),
            const SizedBox(height: 16),
            _modalS('CONTEXTO MENSUAL', [
              _modalR('Ingresos del Mes', _fmt(s['ingresosMes']), bold: true),
              _modalR('Ventas del Mes', '${s['ventasMes']} facturas'),
              _modalR('Promedio Diario', _fmt(s['promedioDiario'])),
              _modalR('Mejor Día', 'Día ${s['mejorDia']} → ${_fmt(s['mejorDiaTotal'])}', color: AppTheme.greenMetal),
              _modalR('Días con Ventas', '${s['diasConVentas']} días'),
              _modalR('Balance Neto', _fmt(s['balanceMes']), bold: true, color: (s['balanceMes'] ?? 0) >= 0 ? AppTheme.greenMetal : AppTheme.reiOrangeRed),
            ]),
          ]))),
        ]),
      ),
    ));
  }

  Widget _modalS(String t, List<Widget> rows) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
    const SizedBox(height: 8),
    Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(14)), child: Column(children: rows)),
  ]);

  Widget _modalR(String l, String v, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(child: Text(l, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500))),
      Text(v, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w900 : FontWeight.w700, color: color)),
    ]),
  );
}
