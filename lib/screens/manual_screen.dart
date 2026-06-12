import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/dashboard_controller.dart';

class ManualScreen extends StatelessWidget {
  const ManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final cardColor = Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF1A1A1A) : Colors.white);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(40, 120, 40, 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(textColor),
                const SizedBox(height: 40),
                _buildSectionTitle('GUÍA DE MÓDULOS', Icons.explore_rounded, AppTheme.ayanamiBlue),
                const SizedBox(height: 24),
                _buildModulesGrid(context, cardColor, textColor),
                const SizedBox(height: 56),
                _buildSectionTitle('FLUJOS DE TRABAJO', Icons.route_rounded, AppTheme.greenMetal),
                const SizedBox(height: 24),
                _buildFlujos(cardColor, textColor),
                const SizedBox(height: 56),
                _buildSectionTitle('PREGUNTAS FRECUENTES', Icons.quiz_rounded, const Color(0xFF8B5CF6)),
                const SizedBox(height: 24),
                _buildFaqList(cardColor, textColor),
                const SizedBox(height: 56),
                _buildSectionTitle('RESOLUCIÓN DE ERRORES', Icons.bug_report_rounded, AppTheme.reiOrangeRed),
                const SizedBox(height: 24),
                _buildTroubleshootingList(cardColor, textColor),
              ],
            ),
          ),
          _buildHeaderBar(context, bgColor, textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MANUAL DE USUARIO', style: TextStyle(color: textColor, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
        const SizedBox(height: 8),
        Text('Guía completa para usar FarmaBook', style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
      const SizedBox(width: 16),
      Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
    ]);
  }

  // ─────────────────────────────────────────────────────────────
  // MÓDULOS
  // ─────────────────────────────────────────────────────────────

  Widget _buildModulesGrid(BuildContext context, Color cardColor, Color textColor) {
    return SizedBox(height: 1000, child: GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.4,
      mainAxisSpacing: 24, crossAxisSpacing: 24,
      children: [
        _buildCard(context, 'Panel de Inicio', 'Resumen visual de ingresos, egresos y salud del inventario.',
          'Visión general del negocio.\n\n'
          '▸ KPIs principales: Ingresos del día, egresos, \% stock saludable y ganancia neta.\n'
          '▸ Ventas recientes: Últimas 5 transacciones con monto y hora.\n'
          '▸ Top 3 productos: Lo más vendido del día.\n'
          '▸ Alertas activas: Stock bajo y productos próximos a vencer.\n'
          '▸ Módulos rápidos: Acceso directo a las funciones más usadas.',
          Icons.dashboard_rounded, AppTheme.ayanamiBlue, cardColor, textColor),
        _buildCard(context, 'Almacén Central', 'Gestión completa de inventario y productos.',
          'Control total del stock.\n\n'
          '▸ Agregar producto: Botón "+" — ingresa nombre, presentación, precio, categoria.\n'
          '▸ Editar: Toca un producto para modificar precio o datos.\n'
          '▸ Buscar: Filtra por nombre o código de barras.\n'
          '▸ Stock mínimo: Define un límite por producto; el sistema alerta al llegar a ese nivel.\n'
          '▸ Categorías: Organiza por tipo (analgésico, antibiótico, etc.).',
          Icons.inventory_2_rounded, const Color(0xFF8B5CF6), cardColor, textColor),
        _buildCard(context, 'Punto de Venta', 'Realizar ventas y generar tickets.',
          'Flujo de venta rápida.\n\n'
          '▸ Buscar producto: Escribe nombre o código de barras.\n'
          '▸ Agregar al carrito: Toca "Agregar", selecciona cantidad.\n'
          '▸ Vista previa: El carrito muestra productos, cantidades y subtotales.\n'
          '▸ Cliente: Opcional — ingresa nombre y cédula antes de cobrar.\n'
          '▸ Cobrar: Presiona "Realizar Venta" — el stock se descuenta al instante.\n'
          '▸ Recibo: Se genera un ticket en pantalla; puedes imprimirlo.',
          Icons.point_of_sale_rounded, AppTheme.greenMetal, cardColor, textColor),
        _buildCard(context, 'Gestión de Lotes', 'Control de fechas de vencimiento.',
          'Evita pérdidas por caducidad.\n\n'
          '▸ Semáforo visual: Verde = Vigente, Amarillo = Próximo a vencer (30 días), Rojo = Vencido.\n'
          '▸ Registrar lote: Al agregar producto, indica lote y fecha de vencimiento.\n'
          '▸ Trazabilidad: Sabes exactamente qué lote se vendió primero (FIFO).\n'
          '▸ Alertas: El sistema notifica con 30 días de anticipación.',
          Icons.layers_outlined, AppTheme.reiOrangeRed, cardColor, textColor),
        _buildCard(context, 'Estadísticas', 'Análisis financiero y reportes.',
          'Datos completos del negocio.\n\n'
          '▸ Resumen del día: Ingresos, ventas, ticket promedio, unidades, hora pico.\n'
          '▸ Ventas por hora: Gráfica de barras con las 24 horas del día.\n'
          '▸ Rendimiento mensual: Ingresos, egresos, balance, mejor día.\n'
          '▸ Tendencia diaria: Evolución de ingresos día por día en el mes.\n'
          '▸ Top productos: Ranking de más vendidos (hoy, mes, global).\n'
          '▸ Categorías: Pastel con distribución por tipo.\n'
          '▸ PDF: Botón para descargar reporte completo.',
          Icons.analytics_rounded, const Color(0xFFF59E0B), cardColor, textColor),
        _buildCard(context, 'Centro de Alertas', 'Notificaciones automáticas.',
          'Sistema proactivo de notificaciones.\n\n'
          '▸ Stock bajo: Productos por debajo del mínimo configurado.\n'
          '▸ Próximos a vencer: Alertas a 30 días de la fecha de caducidad.\n'
          '▸ Navegación directa: Toca una alerta para ir al módulo correspondiente.',
          Icons.warning_amber_rounded, AppTheme.reiOrangeRed, cardColor, textColor),
        _buildCard(context, 'Movimientos Hoy', 'Auditoría del día.',
          'Registro detallado de cada transacción.\n\n'
          '▸ Lista completa: Todas las ventas, ingresos y ajustes del día.\n'
          '▸ Detalle: Monto, hora, productos involucrados.\n'
          '▸ Auditoría: Revisa qué ocurrió minuto a minuto.\n'
          '▸ Exportación: Puedes consultar recibos individuales.',
          Icons.history_rounded, AppTheme.greenMetal, cardColor, textColor),
        _buildCard(context, 'Catálogos', 'Configuración del sistema.',
          'Datos maestros del sistema.\n\n'
          '▸ Proveedores: Nombres, teléfonos, direcciones de tus distribuidores.\n'
          '▸ Categorías: Clasificación de productos (genéricos, patente, etc.).\n'
          '▸ Usuarios: Creación de cuentas con roles y permisos.',
          Icons.auto_awesome_motion_rounded, Colors.grey.shade600, cardColor, textColor),
        _buildCard(context, 'Manual de Ayuda', 'Este documento.',
          'Todo lo que necesitas saber.\n\n'
          '▸ Guía de módulos: Explicación de cada pantalla.\n'
          '▸ Flujos de trabajo: Pasos para tareas comunes.\n'
          '▸ FAQ: Respuestas a preguntas frecuentes.\n'
          '▸ Errores: Solución a problemas comunes.',
          Icons.menu_book_rounded, AppTheme.ayanamiBlue, cardColor, textColor),
      ],
    ));
  }

  Widget _buildCard(BuildContext context, String title, String desc, String detailed, IconData icon, Color color, Color cardColor, Color textColor) {
    return InkWell(
      onTap: () => _showDetail(context, title, detailed, icon, color),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 24)),
            Icon(Icons.add_circle_outline_rounded, color: color.withOpacity(0.5), size: 20),
          ]),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(desc, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext context, String title, String detail, IconData icon, Color color) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 540, constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Icon(icon, color: color, size: 32)),
            const SizedBox(width: 24),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1))),
          ]),
          const SizedBox(height: 32),
          const Text('GUÍA DETALLADA', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 16),
          Flexible(child: SingleChildScrollView(
            child: Text(detail, style: TextStyle(fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8), height: 1.6, fontWeight: FontWeight.w500)),
          )),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ENTENDIDO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          )),
        ]),
      ),
    ));
  }

  // ─────────────────────────────────────────────────────────────
  // FLUJOS DE TRABAJO
  // ─────────────────────────────────────────────────────────────

  Widget _buildFlujos(Color cardColor, Color textColor) {
    return Column(children: [
      _flujo(cardColor, textColor, 'Registrar un producto nuevo',
        Icons.add_box_rounded, const Color(0xFF8B5CF6),
        '1. Ve a Almacén Central.\n'
        '2. Presiona el botón "+" (esquina inferior derecha).\n'
        '3. Completa: nombre, presentación, precio de compra, precio de venta.\n'
        '4. Selecciona la categoría (si no existe, créala en Catálogos).\n'
        '5. Opcional: agrega lote con fecha de vencimiento.\n'
        '6. Presiona "Guardar". El producto ya está disponible para vender.'),
      const SizedBox(height: 16),
      _flujo(cardColor, textColor, 'Realizar una venta',
        Icons.shopping_cart_checkout_rounded, AppTheme.greenMetal,
        '1. Ve a Punto de Venta.\n'
        '2. Escribe el nombre del producto en el buscador.\n'
        '3. Selecciona el producto y ajusta la cantidad.\n'
        '4. Repite hasta tener todo el carrito listo.\n'
        '5. Opcional: ingresa nombre y cédula del cliente.\n'
        '6. Presiona "Realizar Venta".\n'
        '7. Se genera el recibo — puedes imprimirlo o cerrar.'),
      const SizedBox(height: 16),
      _flujo(cardColor, textColor, 'Revisar estadísticas del negocio',
        Icons.insights_rounded, const Color(0xFFF59E0B),
        '1. Ve a Estadísticas.\n'
        '2. Revisa los indicadores del día (ingresos, ventas, ticket promedio).\n'
        '3. Desplázate hacia abajo para ver ventas por hora y rendimiento mensual.\n'
        '4. La tendencia diaria muestra la evolución del mes.\n'
        '5. Al final están los rankings de productos y categorías.\n'
        '6. Presiona el botón PDF para descargar un reporte completo.\n'
        '7. Presiona el ojo para ver el resumen ejecutivo (cierre de caja).'),
      const SizedBox(height: 16),
      _flujo(cardColor, textColor, 'Gestionar inventario y alertas',
        Icons.notifications_active_rounded, AppTheme.reiOrangeRed,
        '1. En el Panel de Inicio revisa las alertas activas.\n'
        '2. Si hay stock bajo, ve a Almacén Central y agrega inventario.\n'
        '3. Si hay productos por vencer, revisa Gestión de Lotes.\n'
        '4. Edita el lote o da salida anticipada al producto.\n'
        '5. Define stocks mínimos en cada producto para evitar faltantes.'),
    ]);
  }

  Widget _flujo(Color cardColor, Color textColor, String t, IconData ic, Color c, String d) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: c.withOpacity(0.12))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(ic, color: c, size: 20)),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Text(d, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500, height: 1.5)),
        ])),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FAQ
  // ─────────────────────────────────────────────────────────────

  Widget _buildFaqList(Color cardColor, Color textColor) {
    return Column(children: [
      _faq(cardColor, textColor, '¿Cómo agrego un cliente a la venta?',
        'En el Punto de Venta, antes de presionar "Realizar Venta", verás dos campos: "Nombre del Cliente" y "Cédula / ID del Cliente". '
        'Llénalos y esa información aparecerá en el recibo. No es obligatorio — si no ingresas nada, el recibo mostrará "Consumidor Final".'),
      _faq(cardColor, textColor, '¿Puedo modificar el precio de un producto después de crearlo?',
        'Sí. Ve a Almacén Central, busca el producto, tócalo para abrir la vista de detalle y presiona "Editar". '
        'Podrás cambiar precio, presentación y otros campos. Los cambios se reflejan al instante en el Punto de Venta.'),
      _faq(cardColor, textColor, '¿Cómo imprimo un recibo de una venta anterior?',
        'Ve al módulo de Ventas (en el historial), busca la venta que necesitas y tócala. Se abrirá el recibo; presiona "Imprimir".'),
      _faq(cardColor, textColor, '¿Qué significa el semáforo en Gestión de Lotes?',
        'Verde = producto vigente. Amarillo = vence en menos de 30 días. Rojo = ya venció. '
        'Útil para aplicar rotación FIFO (primero en vencer, primero en salir) y evitar pérdidas.'),
      _faq(cardColor, textColor, '¿Cómo descargo el reporte de estadísticas?',
        'En la pantalla de Estadísticas, presiona el ícono de PDF en la barra superior. '
        'El archivo se guarda automáticamente en tu carpeta de Descargas.'),
      _faq(cardColor, textColor, '¿Puedo tener varios usuarios en el sistema?',
        'Sí. Ve a Catálogos > Usuarios y presiona "Agregar". '
        'Cada usuario tiene su propia contraseña. El administrador puede gestionar permisos.'),
      _faq(cardColor, textColor, '¿Qué hago si el sistema no encuentra un producto?',
        'Primero verifica que esté registrado en Almacén Central. '
        'Si existe pero no aparece en el buscador, puede ser un error de conexión — intenta refrescar. '
        'Si el problema persiste, revisa que tenga stock disponible.'),
      _faq(cardColor, textColor, '¿Cómo sé cuánto gané hoy?',
        'En el Panel de Inicio, el primer KPI muestra los ingresos del día. '
        'Para un análisis más detallado, ve a Estadísticas donde verás ingresos, egresos, balance, ticket promedio y más.'),
    ]);
  }

  Widget _faq(Color cardColor, Color textColor, String q, String a) {
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.08))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(margin: const EdgeInsets.only(top: 2), padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.help_outline_rounded, color: Color(0xFF8B5CF6), size: 16)),
          const SizedBox(width: 14),
          Expanded(child: Text(q, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w800))),
        ]),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Text(a, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500, height: 1.5)),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TROUBLESHOOTING
  // ─────────────────────────────────────────────────────────────

  Widget _buildTroubleshootingList(Color cardColor, Color textColor) {
    return Column(children: [
      _trouble(cardColor, textColor, 'No puedo iniciar sesión',
        Icons.login_rounded,
        'Verifica que tu usuario y contraseña sean correctos (distingue mayúsculas/minúsculas). '
        'Asegúrate de que el servidor esté encendido — el sistema necesita conexión de red. '
        'Si olvidaste tu contraseña, contacta al administrador.'),
      _trouble(cardColor, textColor, 'El stock no se actualiza después de una venta',
        Icons.inventory_rounded,
        'Esto puede ocurrir si hay un problema de conexión momentáneo. '
        'Refresca el módulo de Almacén Central o cierra y abre la aplicación. '
        'Si el problema persiste, ve al historial de ventas y verifica que la transacción se haya completado correctamente.'),
      _trouble(cardColor, textColor, 'No aparecen productos en el buscador del Punto de Venta',
        Icons.search_off_rounded,
        'Confirma que el producto esté registrado en Almacén Central. '
        'Asegúrate de que tenga stock disponible (cantidad > 0). '
        'Si tienes muchos productos, intenta escribir el nombre completo o el código de barras.'),
      _trouble(cardColor, textColor, 'Error al descargar el PDF de estadísticas',
        Icons.picture_as_pdf_rounded,
        'El PDF se guarda en la carpeta de Descargas. Verifica que tengas permisos de escritura. '
        'Si el botón se queda cargando, puede ser que el servidor esté generando el reporte — espera unos segundos.'),
      _trouble(cardColor, textColor, 'La pantalla se queda en blanco o gris',
        Icons.tv_off_rounded,
        'Esto puede ocurrir en Windows por problemas de gráficos. '
        'Cierra la aplicación completamente y vuelve a abrirla. '
        'Si el problema continúa, reinicia tu computadora. FarmaBook está optimizado para evitar este error.'),
      _trouble(cardColor, textColor, 'Los datos de estadísticas no se cargan',
        Icons.bar_chart_rounded,
        'Verifica tu conexión a internet. El sistema necesita obtener datos del servidor. '
        'Presiona el botón de refrescar (ícono circular) en la pantalla de Estadísticas. '
        'Si el error persiste, puede haber un problema con el servidor.'),
      _trouble(cardColor, textColor, 'No puedo ver las ventas anteriores',
        Icons.receipt_long_rounded,
        'Ve al módulo de Ventas y asegúrate de que el historial esté cargado. '
        'Si la lista está vacía, puede ser que no haya ventas registradas o que el filtro de fechas esté limitando los resultados.'),
      _trouble(cardColor, textColor, 'El recibo no muestra el nombre del cliente',
        Icons.person_outline_rounded,
        'El nombre del cliente se muestra solo si lo ingresaste antes de realizar la venta. '
        'Si no aparece, significa que no se registró ningún nombre. '
        'Para ventas nuevas, llena el campo "Nombre del Cliente" en el Punto de Venta.'),
    ]);
  }

  Widget _trouble(Color cardColor, Color textColor, String t, IconData ic, String d) {
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.reiOrangeRed.withOpacity(0.1))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.reiOrangeRed.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(ic, color: AppTheme.reiOrangeRed, size: 20)),
        const SizedBox(width: 18),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(d, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500, height: 1.5)),
        ])),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeaderBar(BuildContext context, Color bgColor, Color textColor) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        height: 100, padding: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.95),
          border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
        ),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.ayanamiBlue, size: 20),
            onPressed: () => Provider.of<DashboardController>(context, listen: false).onItemTapped(0),
            tooltip: 'Volver al Inicio'),
          const SizedBox(width: 8),
          const Icon(Icons.menu_book_rounded, color: AppTheme.ayanamiBlue, size: 28),
          const SizedBox(width: 16),
          Text('MANUAL DE AYUDA', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ]),
      ),
    );
  }
}
