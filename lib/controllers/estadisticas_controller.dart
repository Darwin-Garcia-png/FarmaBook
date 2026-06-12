import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/download_helper.dart';

// Bogotá = UTC-5 (sin horario de verano)
DateTime _toBogota(DateTime utc) => utc.isUtc
    ? utc.subtract(const Duration(hours: 5))
    : utc.toUtc().subtract(const Duration(hours: 5));

class EstadisticasController extends ChangeNotifier {
  Timer? _autoClearTimer;

  bool isLoading = true;
  String? error;

  @override
  void dispose() {
    _autoClearTimer?.cancel();
    super.dispose();
  }

  // ── KPIs básicos de la API ──────────────────────────────────────
  double ingresosHoy = 0;
  double ingresosMes = 0;
  int ventasHoy = 0;
  int ventasMes = 0;
  double egresosMes = 0;
  double balanceMes = 0;

  // ── Métricas calculadas de HOY ──────────────────────────────────
  double ticketMaximo = 0;
  double ticketMinimo = 0;
  double averageTicket = 0;
  int totalUnidadesHoy = 0;
  int peakHour = 0;
  int peakHourCount = 0;          // cuántas ventas en la hora pico
  String primeraVentaHora = '--:--';
  String ultimaVentaHora  = '--:--';
  Map<int, double> ingresosPorHora = {};   // hora → ingresos
  Map<String, int> rankingProductosHoy = {}; // nombre → unidades

  // ── Métricas calculadas del MES ─────────────────────────────────
  double promedioVentaDiaria = 0;
  int mejorDiaMes = 0;
  double mejorDiaIngresos = 0;
  int diasConVentas = 0;

  // ── Rankings de la API ──────────────────────────────────────────
  List<dynamic> topProductosHoy    = [];
  List<dynamic> topProductosMes    = [];
  List<dynamic> topProductosGlobal = [];

  // ── Datos para gráficas ─────────────────────────────────────────
  List<Map<String, dynamic>> dailyTrend = [];
  Map<String, double> categoryData = {};

  // ── Resumen del día (objeto plano para el modal) ─────────────────
  Map<String, dynamic> dailySummary = {};

  void touch() {
    _autoClearTimer?.cancel();
    _autoClearTimer = null;
  }

  void scheduleAutoClear() {
    _autoClearTimer?.cancel();
    _autoClearTimer = Timer(const Duration(minutes: 5), () {
      clearData();
    });
  }

  void clearData() {
    topProductosHoy.clear();
    topProductosMes.clear();
    topProductosGlobal.clear();
    dailyTrend.clear();
    ingresosPorHora.clear();
    rankingProductosHoy.clear();
    categoryData.clear();
    dailySummary.clear();
    ingresosHoy = 0;
    ingresosMes = 0;
    ventasHoy = 0;
    ventasMes = 0;
    egresosMes = 0;
    balanceMes = 0;
    ticketMaximo = 0;
    ticketMinimo = 0;
    averageTicket = 0;
    totalUnidadesHoy = 0;
    peakHour = 0;
    peakHourCount = 0;
    primeraVentaHora = '--:--';
    ultimaVentaHora = '--:--';
    promedioVentaDiaria = 0;
    mejorDiaMes = 0;
    mejorDiaIngresos = 0;
    diasConVentas = 0;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────
  Future<void> init() async => cargarEstadisticas();

  Future<void> cargarEstadisticas() async {
    isLoading = true;
    error = null;

    try {
  
      // Peticiones paralelas a la API de analytics
      final results = await Future.wait([
        ApiService.getRevenueToday(),
        ApiService.getRevenueMonth(),
        ApiService.getSalesToday(),
        ApiService.getSalesMonth(),
        ApiService.getExpenses(),
        ApiService.getBalance(),
        ApiService.getTopProducts(),
        ApiService.getTopProducts(),
        ApiService.getTopProducts(),
      ]);

      ingresosHoy = double.tryParse(results[0]['data']?['ingresosDiarios']?.toString() ?? '0') ?? 0;
      ingresosMes = double.tryParse(results[1]['data']?['ingresosMensuales']?.toString() ?? '0') ?? 0;
      ventasHoy   = (results[2]['data']?['ventasDelDia'] as num? ?? 0).toInt();
      ventasMes   = (results[3]['data']?['ventasMensuales'] as num? ?? 0).toInt();
      egresosMes  = double.tryParse(results[4]['data']?['egresosMensuales']?.toString() ?? '0') ?? 0;
      balanceMes  = double.tryParse(results[5]['data']?['balanceMensual']?.toString() ?? '0') ?? 0;

      topProductosHoy    = results[6]['data'] as List? ?? [];
      topProductosMes    = results[7]['data'] as List? ?? [];
      topProductosGlobal = results[8]['data'] as List? ?? [];

      averageTicket = ventasHoy > 0 ? ingresosHoy / ventasHoy : 0;

      // Análisis profundo a partir de las ventas reales
      await Future.wait([
        _processTodaysSales(),
        _processMonthlyTrend(),
      ]);

      _buildDailySummary();

    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
      error = 'No se pudieron cargar las estadísticas. Verifica la conexión.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Ventas de HOY — cálculo de métricas detalladas ───────────────
  Future<void> _processTodaysSales() async {
    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      final List salesList = await ApiService.getSales(limit: 200);

      double maxTicket = 0;
      double minTicket = double.infinity;
      int totalUnidades = 0;
      DateTime? firstSale;
      DateTime? lastSale;
      final Map<int, double> hourlyRev  = {};
      final Map<int, int>    hourlyCount = {};
      final Map<String, int> prodMap    = {};

      for (var sale in salesList) {
        final total = double.tryParse(sale['total']?.toString() ?? '0') ?? 0;
        if (total > maxTicket) maxTicket = total;
        if (total > 0 && total < minTicket) minTicket = total;

        final dateStr = (sale['fechaDeVenta'] ?? '').toString().replaceAll(' ', 'T');
        final date = DateTime.tryParse(dateStr);
        final bogota = date != null ? _toBogota(date) : null;
        if (bogota != null) {
          final h = bogota.hour;
          hourlyRev[h]   = (hourlyRev[h] ?? 0) + total;
          hourlyCount[h] = (hourlyCount[h] ?? 0) + 1;
          if (firstSale == null || bogota.isBefore(firstSale)) firstSale = bogota;
          if (lastSale  == null || bogota.isAfter(lastSale))  lastSale  = bogota;
        }

        final items = sale['productosVendidos'] as List? ?? [];
        for (var item in items) {
          final nombre = item['nombre']?.toString() ?? 'Desconocido';
          final qty = (item['cantidadDeUnidades'] as num? ?? 0).toInt();
          totalUnidades += qty;
          prodMap[nombre] = (prodMap[nombre] ?? 0) + qty;
        }
      }

      ticketMaximo    = maxTicket;
      ticketMinimo    = minTicket == double.infinity ? 0 : minTicket;
      totalUnidadesHoy = totalUnidades;
      ingresosPorHora = hourlyRev;

      // Hora pico por conteo de ventas
      int maxCount = 0;
      int bestHour = 0;
      hourlyCount.forEach((h, c) {
        if (c > maxCount) { maxCount = c; bestHour = h; }
      });
      peakHour      = bestHour;
      peakHourCount = maxCount;

      _fmt(DateTime? dt) => dt != null
          ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
          : '--:--';
      primeraVentaHora = _fmt(firstSale);
      ultimaVentaHora  = _fmt(lastSale);

      // Ranking de productos HOY ordenado
      final sorted = prodMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      rankingProductosHoy = Map.fromEntries(sorted);

    } catch (e) {
      debugPrint('Error procesando ventas de hoy: $e');
    }
  }

  // ── Tendencia mensual + distribución de categorías ────────────────
  Future<void> _processMonthlyTrend() async {
    try {
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final lastDay  = DateTime(now.year, now.month + 1, 0);
      final fmt      = DateFormat('yyyy-MM-dd');

      final List salesList = await ApiService.getSales(limit: 200);

      // Categorías — mapa producto → categoría
      final Map<String, double> catMap = {};
      try {
        final rawProds = await ApiService.getProductos(page: 1, limit: 100);
        final rawCats  = await ApiService.getCategories();
        final Map<String, String> prodToCat = {};
        final Map<String, String> catIdToName = {};

        for (var p in rawProds) {
          final pid = (p['productoId'] ?? '').toString();
          final cid = (p['categoriaId'] ?? '').toString();
          if (pid.isNotEmpty) prodToCat[pid] = cid;
        }
        for (var c in rawCats) {
          final cid  = (c['categoriaId'] ?? '').toString();
          final name = (c['nombre'] ?? 'Otros').toString();
          if (cid.isNotEmpty) catIdToName[cid] = name;
        }
        for (var s in salesList) {
          for (var item in (s['productosVendidos'] as List? ?? [])) {
            final pid     = (item['productoId'] ?? '').toString();
            final subTotal = double.tryParse(item['subTotal']?.toString() ?? '0') ?? 0;
            final cid     = prodToCat[pid];
            if (cid != null) {
              final name = catIdToName[cid] ?? 'Otros';
              catMap[name] = (catMap[name] ?? 0) + subTotal;
            }
          }
        }
      } catch (_) {}
      categoryData = catMap;

      // Tendencia diaria
      final Map<int, double> trendMap = {};
      for (var s in salesList) {
        try {
          final dateStr = (s['fechaDeVenta'] ?? '').toString().replaceAll(' ', 'T');
          final raw = DateTime.tryParse(dateStr);
          if (raw == null) continue;
          final date = _toBogota(raw);
          if (date.month != now.month) continue;
          final total = double.tryParse(s['total']?.toString() ?? '0') ?? 0;
          trendMap[date.day] = (trendMap[date.day] ?? 0) + total;
        } catch (_) {}
      }
      dailyTrend = List.generate(31, (i) => {'day': i + 1, 'total': trendMap[i + 1] ?? 0.0});

      // Análisis mensual
      double maxDayTotal = 0;
      int maxDay = 0;
      int diasConVentasCount = 0;
      double sumaMes = 0;

      trendMap.forEach((day, total) {
        sumaMes += total;
        diasConVentasCount++;
        if (total > maxDayTotal) { maxDayTotal = total; maxDay = day; }
      });

      promedioVentaDiaria = now.day > 0 ? sumaMes / now.day : 0;
      mejorDiaMes         = maxDay;
      mejorDiaIngresos    = maxDayTotal;
      diasConVentas       = diasConVentasCount;

    } catch (e) {
      debugPrint('Error procesando tendencia mensual: $e');
    }
  }

  // ── Construir objeto resumen ──────────────────────────────────────
  void _buildDailySummary() {
    final productoEstrellaHoy = rankingProductosHoy.isNotEmpty
        ? rankingProductosHoy.entries.first.key
        : (topProductosHoy.isNotEmpty ? topProductosHoy[0]['nombre'] ?? 'N/A' : 'N/A');
    final unidadesEstrella = rankingProductosHoy.isNotEmpty
        ? rankingProductosHoy.entries.first.value
        : 0;

    dailySummary = {
      // FINANCIERO
      'ingresos':       ingresosHoy,
      'ventas':         ventasHoy,
      'ticketPromedio': averageTicket,
      'ticketMaximo':   ticketMaximo,
      'ticketMinimo':   ticketMinimo,
      // OPERATIVO
      'totalUnidades':  totalUnidadesHoy,
      'primeraVenta':   primeraVentaHora,
      'ultimaVenta':    ultimaVentaHora,
      'horaPico':       '${peakHour.toString().padLeft(2, '0')}:00 hrs',
      'horaPicoVentas': peakHourCount,
      'productoEstrella': productoEstrellaHoy,
      'unidadesEstrella': unidadesEstrella,
      // MENSUAL
      'ingresosMes':     ingresosMes,
      'ventasMes':       ventasMes,
      'egresosMes':      egresosMes,
      'balanceMes':      balanceMes,
      'promedioDiario':  promedioVentaDiaria,
      'mejorDia':        mejorDiaMes,
      'mejorDiaTotal':   mejorDiaIngresos,
      'diasConVentas':   diasConVentas,
      // META
      'fecha': DateFormat("EEEE d 'de' MMMM, yyyy", 'es').format(DateTime.now()),
      'hora':  DateFormat('HH:mm').format(DateTime.now()),
      // TOP 5 HOY (para listar en modal)
      'top5Hoy': rankingProductosHoy.entries.take(5).map((e) => {
        'nombre': e.key, 'unidades': e.value
      }).toList(),
    };
  }

  // ── Descarga de reporte PDF ────────────────────────────────────────
  Future<void> downloadPdfReport() async {
    try {
      final bytes = await ApiService.getAnalyticsReportPdf();
      final ts = DateTime.now().millisecondsSinceEpoch;
      downloadBytes(bytes, 'reporte_farmabook_$ts.pdf');
    } catch (e) {
      debugPrint('Error descargando PDF: $e');
      rethrow;
    }
  }
}
