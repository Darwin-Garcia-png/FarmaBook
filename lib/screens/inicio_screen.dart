import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../controllers/inicio_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/notificaciones_controller.dart';
import '../theme/app_theme.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> with TickerProviderStateMixin {
  final InicioController _controller = InicioController();
  late AnimationController _sonarController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.init();
    
    _sonarController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _sonarController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _navigateTo(int index) {
     Provider.of<DashboardController>(context, listen: false).onItemTapped(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF1A1A1A) : Colors.white);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final borderColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: bgColor,
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.ayanamiBlue))
          : _controller.error != null
              ? _buildErrorState()
              : FadeTransition(
                  opacity: _fadeController,
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(40, 120, 40, 60),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildKPIsSelectiveResponse(cardColor, textColor, borderColor),
                            const SizedBox(height: 56),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: _buildHighEndChart(cardColor, textColor)),
                                const SizedBox(width: 40),
                                Expanded(flex: 2, child: _buildActiveSonarMonitor(cardColor, textColor)),
                              ],
                            ),
                            const SizedBox(height: 56),
                            _buildPremiumMetallicPodium(cardColor, textColor),
                          ],
                        ),
                      ),
                      _buildFrostyHeader(bgColor, textColor),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFrostyHeader(Color bgColor, Color textColor) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.7), 
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.menu_rounded, color: textColor, size: 28),
                      onPressed: () {
                        ScaffoldState? scaffold = Scaffold.maybeOf(context);
                        while (scaffold != null && !scaffold.hasDrawer) {
                          scaffold = scaffold.context.findAncestorStateOfType<ScaffoldState>();
                        }
                        scaffold?.openDrawer();
                      },
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CENTRO DE MANDO', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
                        Row(
                          children: [
                            _sonarPulse(AppTheme.greenMetal),
                            const SizedBox(width: 8),
                            const Text('SISTEMA ONLINE | ABRIL 2026', style: TextStyle(color: AppTheme.greenMetal, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    _proDateBadge(textColor, Theme.of(context).cardTheme.color ?? Colors.white),
                    const SizedBox(width: 16),
                    Consumer<NotificacionesController>(
                      builder: (context, notifCtrl, _) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                notifCtrl.unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_outlined,
                                color: textColor,
                              ),
                              onPressed: () {
                                notifCtrl.markAllAsRead();
                                Provider.of<DashboardController>(context, listen: false).onItemTapped(5); // Ir a alertas
                              },
                            ),
                            if (notifCtrl.unreadCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.reiOrangeRed,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  child: Text(
                                    '${notifCtrl.unreadCount}',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.settings_outlined, color: textColor),
                      onPressed: () {
                         GoRouter.of(context).push('/configuracion');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _proDateBadge(Color textColor, Color cardColor) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]),
      child: Text('${now.day}/${now.month}/${now.year}', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 13)),
    );
  }

  Widget _buildKPIsSelectiveResponse(Color cardColor, Color textColor, Color borderColor) {
    return Row(
      children: [
        _glowKPICard('INGRESOS MES', '\$${_controller.ingresos.toStringAsFixed(0)}', const Color(0xFF10B981), Icons.trending_up, cardColor, textColor, borderColor, _controller.marginPercent, true, () => _navigateTo(2)),
        const SizedBox(width: 24),
        _glowKPICard('EGRESOS TOTALES', '\$${_controller.egresos.toStringAsFixed(0)}', const Color(0xFFEF4444), Icons.trending_down, cardColor, textColor, borderColor, _controller.expensePercent, true, () => _navigateTo(4)),
        const SizedBox(width: 24),
        _glowKPICard('SALUD INVENTARIO', '${(_controller.stockHealthPercent * 100).toInt()}%', const Color(0xFF8B5CF6), Icons.medical_services_rounded, cardColor, textColor, borderColor, _controller.stockHealthPercent, false, () => _navigateTo(1)),
        const SizedBox(width: 24),
        _glowKPICard('BALANCE NETO', '\$${(_controller.ingresos - _controller.egresos).toStringAsFixed(0)}', const Color(0xFF3B82F6), Icons.account_balance_rounded, cardColor, textColor, borderColor, 1.0, false, () => _navigateTo(4)),
      ],
    );
  }

  Widget _glowKPICard(String label, String value, Color color, IconData icon, Color cardColor, Color textColor, Color borderColor, double ringVal, bool isResponsive, VoidCallback onTap) {
     return Expanded(
       child: InkWell(
         onTap: onTap,
         borderRadius: BorderRadius.circular(32),
         child: Container(
           padding: const EdgeInsets.all(28),
           decoration: BoxDecoration(
             color: cardColor,
             borderRadius: BorderRadius.circular(32),
             border: Border.all(color: borderColor),
             boxShadow: [
               BoxShadow(color: color.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 10)),
             ],
           ),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 20)),
                   SizedBox(width: 32, height: 32, child: CircularProgressIndicator(value: ringVal, strokeWidth: 3, backgroundColor: color.withOpacity(0.05), color: color, strokeCap: StrokeCap.round)),
                 ],
               ),
               const SizedBox(height: 20),
               Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1), maxLines: 1),
               const SizedBox(height: 6),
               isResponsive 
                 ? FittedBox(
                     fit: BoxFit.scaleDown,
                     alignment: Alignment.centerLeft,
                     child: Text(value, style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                   )
                 : Text(value, style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
             ],
           ),
         ),
       ),
     );
  }

  Widget _buildHighEndChart(Color cardColor, Color textColor) {
    final currentMonthIndex = DateTime.now().month - 1; 
    final months = ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HISTOGRAMA DE FLUJO MENSUAL (ABRIL)', style: TextStyle(color: Colors.grey, letterSpacing: 2, fontWeight: FontWeight.w800, fontSize: 11)),
        const SizedBox(height: 20),
        Container(
          height: 420,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cardColor, 
            borderRadius: BorderRadius.circular(40), 
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rendimiento Mensual', style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      Text('Comparativa de flujo de caja', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Spacer(),
                  _legendDot('Ingresos', const Color(0xFF10B981)),
                  const SizedBox(width: 24),
                  _legendDot('Egresos', const Color(0xFFEF4444)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Divider(),
              ),
              Expanded(
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Theme.of(context).dividerColor.withOpacity(0.05))),
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => Text('\$${v.toInt()}k', style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w900)))),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) {
                            final idx = v.toInt() % months.length;
                            return Padding(padding: const EdgeInsets.only(top: 12), child: Text(months[idx], style: TextStyle(color: idx == currentMonthIndex ? AppTheme.ayanamiBlue : Colors.grey.withOpacity(0.3), fontSize: 10, fontWeight: idx == currentMonthIndex ? FontWeight.w900 : FontWeight.w800)));
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(4, (i) {
                      if (i == 3) return _barGroup(i, _controller.ingresos / 1000, _controller.egresos / 1000);
                      return _barGroup(i, 0, 0); 
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BarChartGroupData _barGroup(int x, double inVal, double outVal) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: inVal > 0 ? inVal : 0.1, color: const Color(0xFF10B981), width: 24, borderRadius: BorderRadius.circular(8)),
        BarChartRodData(toY: outVal > 0 ? outVal : 0.1, color: const Color(0xFFEF4444), width: 24, borderRadius: BorderRadius.circular(8)),
      ],
    );
  }

  Widget _legendDot(String t, Color c) {
    return Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)), const SizedBox(width: 10), Text(t, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w800))]);
  }

  Widget _buildActiveSonarMonitor(Color cardColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MONITOR DE SISTEMAS EN VIVO', style: TextStyle(color: Colors.grey, letterSpacing: 2, fontWeight: FontWeight.w800, fontSize: 11)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cardColor, 
            borderRadius: BorderRadius.circular(40), 
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TICKET DE ACTIVIDAD', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  _sonarPulse(AppTheme.ayanamiBlue),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),
              if (_controller.alertsStock.isEmpty && _controller.alertsVencimiento.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('SISTEMAS SIN NOVEDAD', style: TextStyle(color: AppTheme.greenMetal, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1))))
              else
                Column(
                  children: [
                    ..._controller.alertsStock.take(2).map((a) => _proAlertItem(a['nombre'], 'STOCK CRÍTICO', const Color(0xFF8B5CF6), textColor, () => _navigateTo(5))),
                    ..._controller.alertsVencimiento.take(2).map((a) => _proAlertItem(a['productoNombre'] ?? 'LOTE', 'VENCIMIENTO PRÓXIMO', const Color(0xFFEF4444), textColor, () => _navigateTo(5))),
                  ],
                ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(height: 1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('FLUJO RECIENTE', style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  TextButton(onPressed: () => _navigateTo(6), child: const Text('Ver historial', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900))),
                ],
              ),
              const SizedBox(height: 12),
              if (_controller.recentSales.isEmpty)
                Text('Sin actividad registrada', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600))
              else
                ..._controller.recentSales.take(5).map((s) => _simpleLogItem(s, textColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _proAlertItem(String name, String type, Color c, Color textColor, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: c, size: 20),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis), Text(type, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5))])),
          ],
        ),
      ),
    );
  }

  Widget _simpleLogItem(dynamic s, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.circle, color: AppTheme.ayanamiBlue, size: 6),
          const SizedBox(width: 12),
          Expanded(child: Text('Folio #${s['ventaId']?.toString().toUpperCase().substring(0, 7)}', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w900))),
          Text('\$${(double.tryParse(s['total']?.toString() ?? '0') ?? 0.0).toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.greenMetal, fontWeight: FontWeight.w900, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPremiumMetallicPodium(Color cardColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         const Text('PRODUCTOS DESTACADOS EN ABRIL', style: TextStyle(color: Colors.grey, letterSpacing: 2, fontWeight: FontWeight.w800, fontSize: 11)),
         const SizedBox(height: 24),
         Row(
           crossAxisAlignment: CrossAxisAlignment.end,
           children: [
             if (_controller.topProducts.length >= 2) Expanded(child: _metallicPodium(_controller.topProducts[1], 'PLATA 2º', [const Color(0xFF94A3B8), const Color(0xFFCBD5E1)], 190, cardColor, textColor)),
             const SizedBox(width: 24),
             if (_controller.topProducts.isNotEmpty) Expanded(flex: 2, child: _metallicPodium(_controller.topProducts[0], 'ORO 1º', [const Color(0xFFF59E0B), const Color(0xFFFDE68A)], 250, cardColor, textColor)),
             const SizedBox(width: 24),
             if (_controller.topProducts.length >= 3) Expanded(child: _metallicPodium(_controller.topProducts[2], 'BRONCE 3º', [const Color(0xFFB45309), const Color(0xFFD97706)], 160, cardColor, textColor)),
           ],
         ),
      ],
    );
  }

  Widget _metallicPodium(dynamic p, String rank, List<Color> metals, double h, Color cardColor, Color textColor) {
    final imgUrl = p['imagenUrl']?.toString();
    return InkWell(
      onTap: () => _navigateTo(1),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        height: h,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border(top: BorderSide(color: metals[0], width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(borderRadius: BorderRadius.circular(16), child: imgUrl != null && imgUrl.isNotEmpty ? Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, size: 30)) : Icon(Icons.medication_rounded, size: 40, color: Theme.of(context).dividerColor)),
            ),
            const SizedBox(height: 12),
            Text(rank, style: TextStyle(color: metals[0], fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
            Text(p['nombre'] ?? 'PRODUCTO', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 13), maxLines: 1),
            Text('\$${(p['ingresosGenerados'] as num).toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _sonarPulse(Color color) {
    return AnimatedBuilder(
      animation: _sonarController,
      builder: (context, child) {
        return Container(
          width: 16, height: 16,
          alignment: Alignment.center,
          child: Stack(
            children: [
              Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle))),
              Center(child: Container(width: 20 * _sonarController.value, height: 20 * _sonarController.value, decoration: BoxDecoration(color: color.withOpacity(1.0 - _sonarController.value), shape: BoxShape.circle))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
     return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center, 
         children: [
           const Icon(Icons.terminal_rounded, size: 80, color: AppTheme.reiOrangeRed), 
           const SizedBox(height: 16), 
           Text(_controller.error!, style: const TextStyle(color: AppTheme.reiOrangeRed, fontWeight: FontWeight.bold)), 
           const SizedBox(height: 24), 
           ElevatedButton(onPressed: _controller.cargarDatos, child: const Text('REINTENTAR SINCRONIZACIÓN'))
         ]
       )
     );
  }
}
