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
  List<dynamic> supplierRanking   = [];

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
    supplierRanking.clear();
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
      final nowBogota = _toBogota(DateTime.now());
      final firstOfMonthBogota = DateTime(nowBogota.year, nowBogota.month, 1);
      final firstOfMonthUtc = firstOfMonthBogota.add(const Duration(hours: 5));
      final fechaInicioStr = firstOfMonthUtc.toIso8601String();

      // Peticiones paralelas a la API de analytics y a la lista de ventas del mes
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
        ApiService.getSales(limit: 1000, queryParams: {'fechaInicio': fechaInicioStr}),
      ]);

      ingresosHoy = double.tryParse((results[0] as Map)['data']?['ingresosDiarios']?.toString() ?? '0') ?? 0;
      ingresosMes = double.tryParse((results[1] as Map)['data']?['ingresosMensuales']?.toString() ?? '0') ?? 0;
      ventasHoy   = ((results[2] as Map)['data']?['ventasDelDia'] as num? ?? 0).toInt();
      ventasMes   = ((results[3] as Map)['data']?['ventasMensuales'] as num? ?? 0).toInt();
      egresosMes  = double.tryParse((results[4] as Map)['data']?['egresosMensuales']?.toString() ?? '0') ?? 0;
      balanceMes  = double.tryParse((results[5] as Map)['data']?['balanceMensual']?.toString() ?? '0') ?? 0;

      topProductosHoy    = (results[6] as Map)['data'] as List? ?? [];
      topProductosMes    = (results[7] as Map)['data'] as List? ?? [];
      topProductosGlobal = (results[8] as Map)['data'] as List? ?? [];

      final List salesList = results[9] as List? ?? [];

      try {
        supplierRanking = await ApiService.getSupplierAvgCost(order: 'asc', limit: 10);
      } catch (_) {}

      // Análisis profundo a partir de las ventas reales
      await _processTodaysSales(salesList);
      await _processMonthlyTrend(salesList);

      // Recalcular averageTicket con los valores corregidos (activos y filtrados por día)
      averageTicket = ventasHoy > 0 ? ingresosHoy / ventasHoy : 0;

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
  Future<void> _processTodaysSales(List salesList) async {
    try {
      final nowBogota = _toBogota(DateTime.now());

      double maxTicket = 0;
      double minTicket = double.infinity;
      int totalUnidades = 0;
      DateTime? firstSale;
      DateTime? lastSale;
      final Map<int, double> hourlyRev  = {};
      final Map<int, int>    hourlyCount = {};
      final Map<String, int> prodMap    = {};

      double calcIngresosHoy = 0;
      int calcVentasHoy = 0;

      for (var sale in salesList) {
        // Ignorar ventas inactivas/anuladas
        final activo = sale['activo'];
        final isInactive = activo == false || activo.toString() == 'false' || activo == 0 || activo.toString() == '0';
        if (isInactive) continue;

        final total = double.tryParse(sale['total']?.toString() ?? '0') ?? 0;

        final dateStr = (sale['fechaDeVenta'] ?? '').toString().replaceAll(' ', 'T');
        final date = DateTime.tryParse(dateStr);
        final bogota = date != null ? _toBogota(date) : null;
        
        if (bogota != null) {
          final isToday = bogota.year == nowBogota.year &&
              bogota.month == nowBogota.month &&
              bogota.day == nowBogota.day;
              
          if (isToday) {
            calcIngresosHoy += total;
            calcVentasHoy++;

            if (total > maxTicket) maxTicket = total;
            if (total > 0 && total < minTicket) minTicket = total;

            final h = bogota.hour;
            hourlyRev[h]   = (hourlyRev[h] ?? 0) + total;
            hourlyCount[h] = (hourlyCount[h] ?? 0) + 1;
            if (firstSale == null || bogota.isBefore(firstSale)) firstSale = bogota;
            if (lastSale  == null || bogota.isAfter(lastSale))  lastSale  = bogota;

            final items = sale['productosVendidos'] as List? ?? [];
            for (var item in items) {
              final nombre = item['nombre']?.toString() ?? 'Desconocido';
              final qty = (item['cantidadDeUnidades'] as num? ?? 0).toInt();
              totalUnidades += qty;
              prodMap[nombre] = (prodMap[nombre] ?? 0) + qty;
            }
          }
        }
      }

      ticketMaximo    = maxTicket;
      ticketMinimo    = minTicket == double.infinity ? 0 : minTicket;
      totalUnidadesHoy = totalUnidades;
      ingresosPorHora = hourlyRev;

      // Sobrescribir KPI diario del API con los valores activos reales
      ingresosHoy = calcIngresosHoy;
      ventasHoy = calcVentasHoy;

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
  Future<void> _processMonthlyTrend(List salesList) async {
    try {
      final nowBogota = _toBogota(DateTime.now());

      // Categorías — mapa producto → categoría
      final Map<String, double> catMap = {};
      double calcIngresosMes = 0;
      int calcVentasMes = 0;
      
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
          // Ignorar ventas inactivas/anuladas
          final activo = s['activo'];
          final isInactive = activo == false || activo.toString() == 'false' || activo == 0 || activo.toString() == '0';
          if (isInactive) continue;

          final dateStr = (s['fechaDeVenta'] ?? '').toString().replaceAll(' ', 'T');
          final raw = DateTime.tryParse(dateStr);
          if (raw == null) continue;
          final date = _toBogota(raw);
          if (date.month != nowBogota.month || date.year != nowBogota.year) continue;

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
        // Ignorar ventas inactivas/anuladas
        final activo = s['activo'];
        final isInactive = activo == false || activo.toString() == 'false' || activo == 0 || activo.toString() == '0';
        if (isInactive) continue;

        try {
          final dateStr = (s['fechaDeVenta'] ?? '').toString().replaceAll(' ', 'T');
          final raw = DateTime.tryParse(dateStr);
          if (raw == null) continue;
          final date = _toBogota(raw);
          if (date.month != nowBogota.month || date.year != nowBogota.year) continue;
          
          final total = double.tryParse(s['total']?.toString() ?? '0') ?? 0;
          trendMap[date.day] = (trendMap[date.day] ?? 0) + total;
          
          calcIngresosMes += total;
          calcVentasMes++;
        } catch (_) {}
      }
      dailyTrend = List.generate(31, (i) => {'day': i + 1, 'total': trendMap[i + 1] ?? 0.0});

      // Sobrescribir KPIs mensuales del API con los valores activos reales
      ingresosMes = calcIngresosMes;
      ventasMes = calcVentasMes;
      balanceMes = ingresosMes - egresosMes;

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

      promedioVentaDiaria = nowBogota.day > 0 ? sumaMes / nowBogota.day : 0;
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
