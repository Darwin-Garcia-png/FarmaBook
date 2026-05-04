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
  final EstadisticasController _controller = EstadisticasController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.init();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumHeader(
        title: 'Análisis & Estadísticas',
        subtitle: 'Resumen financiero y rendimiento de productos',
        icon: Icons.analytics_rounded,
        baseColor: AppTheme.ayanamiBlue,
        trailing: IconButton(
          icon: const Icon(Icons.refresh, color: AppTheme.ayanamiBlue),
          onPressed: () => _controller.cargarEstadisticas(),
        ),
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_controller.error != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text(_controller.error!, style: const TextStyle(color: Colors.red)),
                        ),
                      _buildDailySummary(),
                      const SizedBox(height: 32),
                      _buildMonthlyKPIs(),
                      const SizedBox(height: 32),
                      _buildTrendSection(),
                      const SizedBox(height: 32),
                      _buildRankingsGrid(),
                      const SizedBox(height: 32),
                      _buildCategorySection(),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDailySummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ACTIVIDAD DE HOY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _miniKpiCard('Ingresos Hoy', '\$${_controller.ingresosHoy.toStringAsFixed(2)}', Icons.payments_rounded, AppTheme.ayanamiBlue)),
            const SizedBox(width: 20),
            Expanded(child: _miniKpiCard('Ventas Hoy', '${_controller.ventasHoy}', Icons.shopping_cart_rounded, AppTheme.greenMetal)),
          ],
        ),
      ],
    );
  }

  Widget _miniKpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMonthlyKPIs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RENDIMIENTO MENSUAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _kpiCard('Ingresos Mes', '\$${_controller.ingresosMes.toStringAsFixed(2)}', Icons.trending_up_rounded, AppTheme.ayanamiBlue)),
            const SizedBox(width: 20),
            Expanded(child: _kpiCard('Gastos Lotes', '\$${_controller.egresosMes.toStringAsFixed(2)}', Icons.trending_down_rounded, AppTheme.reiOrangeRed)),
            const SizedBox(width: 20),
            Expanded(child: _kpiCard('Balance Neto', '\$${_controller.balanceMes.toStringAsFixed(2)}', Icons.account_balance_wallet_rounded, AppTheme.greenMetal)),
          ],
        ),
      ],
    );
  }

  Widget _buildRankingsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rankings de Productos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _rankingList('Top Hoy', _controller.topProductosHoy)),
            const SizedBox(width: 16),
            Expanded(child: _rankingList('Top Mes', _controller.topProductosMes)),
            const SizedBox(width: 16),
            Expanded(child: _rankingList('Top Histórico', _controller.topProductosGlobal)),
          ],
        ),
      ],
    );
  }

  Widget _rankingList(String title, List<dynamic> items) {
    return _sectionCard(
      title: title,
      subtitle: 'Más vendidos',
      child: Column(
        children: items.isEmpty 
          ? [const Padding(padding: EdgeInsets.all(16), child: Text('Sin datos', style: TextStyle(color: Colors.grey, fontSize: 12)))]
          : items.take(3).map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(child: Text(p['nombre'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color), overflow: TextOverflow.ellipsis)),
                Text('${p['unidadesVendidas']} u', style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
              ],
            ),
          )).toList(),
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 24),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
        ],
      ),
    );
  }

  Widget _buildTrendSection() {
    return _sectionCard(
      title: 'Tendencia de Ingresos Diarios',
      subtitle: 'Visión general del rendimiento este mes',
      child: SizedBox(
        height: 300,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  interval: 5,
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: _controller.dailyTrend.map((e) => FlSpot(e['day'].toDouble(), e['total'] as double)).toList(),
                isCurved: true,
                color: AppTheme.ayanamiBlue,
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.ayanamiBlue.withOpacity(0.3), AppTheme.ayanamiBlue.withOpacity(0.0)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    final data = _controller.categoryData;
    final List<PieChartSectionData> sections = [];
    final colors = [const Color(0xFF6DABE4), const Color(0xFF2F855A), const Color(0xFFE53E3E), const Color(0xFFF6AD55), const Color(0xFF805AD5)];

    final totalCategorized = data.values.fold(0.0, (sum, item) => sum + item);
    
    int i = 0;
    data.forEach((cat, val) {
      sections.add(PieChartSectionData(
        color: colors[i % colors.length],
        value: val,
        title: '${(val / (totalCategorized > 0 ? totalCategorized : 1) * 100).toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
      i++;
    });

    return _sectionCard(
      title: 'Ventas por Categoría',
      subtitle: 'Distribución porcentual de ingresos',
      child: Row(
        children: [
          SizedBox(
            height: 200,
            width: 200,
            child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 40)),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.keys.take(5).toList().asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Text(e.value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(),
          ),
          child,
        ],
      ),
    );
  }
}