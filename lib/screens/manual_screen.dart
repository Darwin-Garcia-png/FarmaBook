import 'package:flutter/material.dart';
import 'dart:ui';
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
                _buildSectionTitle('RESOLUCIÓN DE ERRORES', Icons.bug_report_rounded, AppTheme.reiOrangeRed),
                const SizedBox(height: 24),
                _buildTroubleshootingList(cardColor, textColor),
              ],
            ),
          ),
          _buildFrostyHeader(context, bgColor, textColor),
        ],
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MANUAL DE USUARIO',
          style: TextStyle(
            color: textColor,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Bienvenido al centro de ayuda de FarmaBook. Aquí aprenderás a dominar todas las funciones del sistema.',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildModulesGrid(BuildContext context, Color cardColor, Color textColor) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.4,
      mainAxisSpacing: 24,
      crossAxisSpacing: 24,
      children: [
        _buildManualCard(
          context,
          'Panel de Inicio',
          'Resumen visual de ingresos, egresos y salud del inventario.',
          'Este es el "Centro de Mando" de tu farmacia. \n\n'
          '• KPIs: Los 4 cuadros superiores muestran dinero ingresado, gastos, porcentaje de stock saludable y la ganancia neta.\n'
          '• Gráfica: Permite ver el rendimiento de los últimos meses para tomar decisiones financieras.\n'
          '• Monitor en Vivo: Muestra las últimas 5 ventas y las alertas más urgentes sin tener que navegar a otros módulos.',
          Icons.dashboard_rounded,
          AppTheme.ayanamiBlue,
          cardColor,
          textColor,
        ),
        _buildManualCard(
          context,
          'Almacén Central',
          'Gestión total de inventario y registro de productos.',
          'Aquí es donde organizas toda tu mercancía.\n\n'
          '• Agregar: Usa el botón "+" para registrar un producto nuevo. Asegúrate de poner el precio de venta correcto.\n'
          '• Stock: Puedes ver cuánto te queda de cada cosa. El sistema marca en azul lo que está bien y en rojo lo que falta.\n'
          '• Búsqueda: Filtra por nombre o categoría para encontrar medicamentos rápidamente.',
          Icons.inventory_2_rounded,
          const Color(0xFF8B5CF6),
          cardColor,
          textColor,
        ),
        _buildManualCard(
          context,
          'Punto de Venta',
          'Módulo para realizar ventas y generar tickets.',
          'Optimizado para la velocidad del mostrador.\n\n'
          '• Vender: Busca el producto, indica la cantidad y dale a "Agregar".\n'
          '• Total: El sistema calcula impuestos y descuentos automáticamente.\n'
          '• Confirmar: Al presionar "Realizar Venta", el stock se descuenta del almacén y se genera un folio de seguimiento.',
          Icons.point_of_sale_rounded,
          AppTheme.greenMetal,
          cardColor,
          textColor,
        ),
        _buildManualCard(
          context,
          'Gestión de Lotes',
          'Control preventivo de fechas de vencimiento.',
          'Crucial para evitar pérdidas por caducidad.\n\n'
          '• Trazabilidad: Cada producto puede tener varios lotes con fechas distintas.\n'
          '• Semáforo: El sistema usa colores (Verde = Seguro, Amarillo = Por vencer, Rojo = Caducado).\n'
          '• Acción: Te permite identificar qué lote sacar primero para rotar el inventario.',
          Icons.layers_outlined,
          AppTheme.reiOrangeRed,
          cardColor,
          textColor,
        ),
        _buildManualCard(
          context,
          'Estadísticas',
          'Análisis financiero y reportes de rendimiento.',
          'Conoce los números reales de tu negocio.\n\n'
          '• Flujo de Caja: Compara tus compras vs tus ventas diarias.\n'
          '• Top Productos: Descubre qué marcas o medicamentos son tus "Best Sellers" para nunca quedarte sin ellos.\n'
          '• Exportación: Genera vistas detalladas de tus movimientos financieros.',
          Icons.analytics_rounded,
          const Color(0xFFF59E0B),
          cardColor,
          textColor,
        ),
        _buildManualCard(
          context,
          'Centro de Alertas',
          'Notificaciones automáticas del sistema.',
          'El sistema trabaja por ti detectando problemas.\n\n'
          '• Stock Bajo: Te avisa cuando queda menos del mínimo configurado.\n'
          '• Próximos a Vencer: Alerta con 30 días de anticipación sobre caducidades.\n'
          '• Directo al Grano: Haz clic en cualquier alerta para ir directamente a solucionar el problema.',
          Icons.warning_amber_rounded,
          AppTheme.reiOrangeRed,
          cardColor,
          textColor,
        ),
        _buildManualCard(
          context,
          'Movimientos Hoy',
          'Auditoría y registro histórico del día.',
          'Para tener el control de lo que sucede cada minuto.\n\n'
          '• Historial: Lista de cada venta, ingreso o ajuste manual.\n'
          '• Auditoría: Revisa quién hizo qué cambio y a qué hora.\n'
          '• Transparencia: Útil para cierres de caja y arqueos diarios.',
          Icons.history_rounded,
          AppTheme.greenMetal,
          cardColor,
          textColor,
        ),
        _buildManualCard(
          context,
          'Catálogos',
          'Configuración de base y administración de usuarios.',
          'La base estructural de tu FarmaBook.\n\n'
          '• Proveedores: Datos de contacto de quienes te surten.\n'
          '• Categorías: Organiza por (Genéricos, Patente, Abarrotes, etc.).\n'
          '• Usuarios: Crea cuentas para tus empleados y controla sus permisos.',
          Icons.auto_awesome_motion_rounded,
          Colors.grey.shade600,
          cardColor,
          textColor,
        ),
      ],
    );
  }

  Widget _buildManualCard(BuildContext context, String title, String desc, String detailedDesc, IconData icon, Color color, Color cardColor, Color textColor) {
    return InkWell(
      onTap: () => _showDetailDialog(context, title, detailedDesc, icon, color),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Icon(Icons.add_circle_outline_rounded, color: color.withOpacity(0.5), size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, String title, String detail, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 500,
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'GUÍA DETALLADA',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ENTENDIDO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTroubleshootingList(Color cardColor, Color textColor) {
    return Column(
      children: [
        _buildTroubleItem(
          'No puedo iniciar sesión',
          'Verifica que tu usuario y contraseña sean correctos. Asegúrate de que el servidor esté encendido y tengas conexión a internet.',
          cardColor,
          textColor,
        ),
        _buildTroubleItem(
          'El stock no se actualiza',
          'Intenta refrescar el módulo o verifica si la venta se completó correctamente. A veces puede haber un pequeño retraso de red.',
          cardColor,
          textColor,
        ),
        _buildTroubleItem(
          'No aparecen productos en el buscador',
          'Asegúrate de que el producto esté registrado en el Almacén Central y tenga stock disponible para la venta.',
          cardColor,
          textColor,
        ),
        _buildTroubleItem(
          'Error al generar reporte PDF',
          'Verifica que tengas permisos de escritura en tu dispositivo y que el navegador o sistema no esté bloqueando las descargas.',
          cardColor,
          textColor,
        ),
      ],
    );
  }

  Widget _buildTroubleItem(String title, String solution, Color cardColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.reiOrangeRed.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.help_outline_rounded, color: AppTheme.reiOrangeRed, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  solution,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostyHeader(BuildContext context, Color bgColor, Color textColor) {
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
              border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.ayanamiBlue, size: 20),
                  onPressed: () => Provider.of<DashboardController>(context, listen: false).onItemTapped(0),
                  tooltip: 'Volver al Inicio',
                ),
                const SizedBox(width: 8),
                const Icon(Icons.menu_book_rounded, color: AppTheme.ayanamiBlue, size: 28),
                const SizedBox(width: 16),
                Text(
                  'MANUAL DE AYUDA',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
