import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/almacen_controller.dart';
import '../controllers/lotes_controller.dart';
import '../controllers/ventas_controller.dart';
import '../controllers/notificaciones_controller.dart';
import '../utils/user_session.dart';
import '../theme/app_theme.dart';
import '../widgets/animations.dart';
import 'inicio_screen.dart';
import 'almacen_screen.dart';
import 'proveedores_screen.dart';
import 'casas_screen.dart';
import 'estadisticas_screen.dart';
import 'ventas_screen.dart';
import 'lotes_screen.dart';
import 'categorias_screen.dart';
import 'presentaciones_screen.dart';
import 'usuarios_screen.dart';
import 'manual_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<DashboardController>();
  }

  @override
  Widget build(BuildContext context) {
    _controller = context.watch<DashboardController>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(10, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDrawerHeader(),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildDrawerItem(Icons.dashboard_rounded, 'Panel Inicio', 0),
                    _buildDrawerItem(Icons.inventory_2_rounded, 'Almacén Central', 1),
                    _buildDrawerItem(Icons.point_of_sale_rounded, 'Punto de Venta', 2),
                    _buildDrawerItem(Icons.layers_outlined, 'Gestión de Lotes', 3),
                    _buildDrawerItem(Icons.analytics_rounded, 'Estadísticas', 4),
                    _buildDrawerItem(Icons.menu_book_rounded, 'Manual de Ayuda', 11),
                    
                    const SizedBox(height: 12),
                    _buildExpansionCatalogos(),
                  ],
                ),
              ),
              const Divider(indent: 32, endIndent: 32),
              Consumer<NotificacionesController>(
                builder: (context, notifCtrl, _) => _buildNotifItem(notifCtrl),
              ),
              _buildLogoutItem(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.f1): () => _controller.onItemTapped(11),
          if (_controller.selectedIndex != 0)
            const SingleActivator(LogicalKeyboardKey.escape): () => _controller.onItemTapped(0),
          const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => _controller.onItemTapped(0),
          const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => _controller.onItemTapped(1),
          const SingleActivator(LogicalKeyboardKey.digit3, control: true): () => _controller.onItemTapped(2),
          const SingleActivator(LogicalKeyboardKey.digit4, control: true): () => _controller.onItemTapped(3),
          const SingleActivator(LogicalKeyboardKey.digit5, control: true): () => _controller.onItemTapped(4),
        },
        child: Focus(
          autofocus: true,
          child: Stack(children: [
            RepaintBoundary(child: _buildScreen()),
          ]),
        ),
      ),
    );
  }

  Widget _buildScreen() {
    switch (_controller.selectedIndex) {
      case 0:
        return const InicioScreen();
      case 1:
        return const AlmacenScreen();
      case 2:
        return const VentasScreen();
      case 3:
        return const LotesScreen();
      case 4:
        return const EstadisticasScreen();
      case 5:
        return const CasasScreen();
      case 7:
        return const CategoriasScreen();
      case 8:
        return const PresentacionesScreen();
      case 9:
        return const ProveedoresScreen();
      case 10:
        return const UsuariosScreen();
      case 11:
        return const ManualScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildExpansionCatalogos() {
    bool isCatalogActive = [5, 7, 8, 9, 10].contains(_controller.selectedIndex);
    
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isCatalogActive,
        leading: Icon(Icons.auto_awesome_motion_rounded, color: isCatalogActive ? AppTheme.ayanamiBlue : Colors.grey.shade500),
        title: Text('CATÁLOGOS', 
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w900, 
            color: isCatalogActive ? AppTheme.ayanamiBlue : Colors.grey.shade600, 
            letterSpacing: 1
          )
        ),
        children: [
          _buildDrawerSubItem(Icons.business_rounded, 'Casas', 5),
          _buildDrawerSubItem(Icons.category_rounded, 'Categorías', 7),
          _buildDrawerSubItem(Icons.medication_liquid_rounded, 'Presentaciones', 8),
          _buildDrawerSubItem(Icons.local_shipping_rounded, 'Proveedores', 9),
          _buildDrawerSubItem(Icons.people_alt_rounded, 'Usuarios', 10),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      child: Row(
        children: [
          Image.asset('assets/images/logo_base.png', height: 40, width: 40, fit: BoxFit.contain),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('FarmaBook',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              Text('Sistema de Gestión',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _controller.selectedIndex == index;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HoverScale(
        scale: 1.02,
        elevation: 4,
        onTap: () {
          _controller.onItemTapped(index);
          if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
        },
        child: InkWell(
        onTap: () {
          _controller.onItemTapped(index);
          if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.ayanamiBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppTheme.ayanamiBlue.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          child: Row(
            children: [
              Icon(icon, 
                color: isSelected ? Colors.white : Colors.grey.shade500, 
                size: 22
              ),
              const SizedBox(width: 16),
              Text(title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.7), 
                  fontSize: 15, 
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: isSelected ? 0.2 : 0,
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildDrawerSubItem(IconData icon, String title, int index) {
    final isSelected = _controller.selectedIndex == index;
    
    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 4, right: 8),
      child: HoverScale(
        scale: 1.02,
        elevation: 2,
        onTap: () {
          _controller.onItemTapped(index);
          if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
        },
        child: InkWell(
        onTap: () {
          _controller.onItemTapped(index);
          if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.ayanamiBlue.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, 
                color: isSelected ? AppTheme.ayanamiBlue : Colors.grey.shade500, 
                size: 18
              ),
              const SizedBox(width: 12),
              Text(title,
                style: TextStyle(
                  color: isSelected ? AppTheme.ayanamiBlue : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6), 
                  fontSize: 14, 
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  void _showNotifDialog(BuildContext context, NotificacionesController notifCtrl) {
    final list = List<Map<String, dynamic>>.from(notifCtrl.notificaciones);
    showDialog(
      context: context,
      builder: (ctx) => _AnimatedNotifDialog(list: list, notifCtrl: notifCtrl),
    ).then((_) => notifCtrl.markAllAsRead());
  }

  Widget _buildNotifItem(NotificacionesController notifCtrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(notifCtrl.unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_outlined,
              color: notifCtrl.unreadCount > 0 ? AppTheme.reiOrangeRed : Colors.grey.shade500, size: 22),
            if (notifCtrl.unreadCount > 0)
              Positioned(
                right: -4, top: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: AppTheme.reiOrangeRed, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text('${notifCtrl.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
        title: Text('Notificaciones',
          style: TextStyle(
            color: notifCtrl.unreadCount > 0 ? AppTheme.reiOrangeRed : Colors.grey.shade600,
            fontSize: 14, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          Navigator.pop(context);
          _showNotifDialog(context, notifCtrl);
        },
      ),
    );
  }

  Widget _buildLogoutItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: const Icon(Icons.logout_rounded, color: AppTheme.reiOrangeRed, size: 22),
        title: const Text('Cerrar Sesión',
          style: TextStyle(color: AppTheme.reiOrangeRed, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        onTap: () async {
          await _controller.logout();
          if (mounted) {
            context.read<AlmacenController>().clearData();
            context.read<LotesController>().clearData();
            context.read<NotificacionesController>().clearData();
            try { context.read<VentasController>().clearData(); } catch (_) {}
            UserSession.clear();
            context.go('/login');
          }
        },
      ),
    );
  }
}

class _AnimatedNotifDialog extends StatefulWidget {
  final List<Map<String, dynamic>> list;
  final NotificacionesController notifCtrl;
  const _AnimatedNotifDialog({required this.list, required this.notifCtrl});

  @override
  State<_AnimatedNotifDialog> createState() => _AnimatedNotifDialogState();
}

class _AnimatedNotifDialogState extends State<_AnimatedNotifDialog> {
  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 420,
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.ayanamiBlue, AppTheme.ayanamiBlue.withValues(alpha: 0.85)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Notificaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('${list.length} pendiente${list.length != 1 ? 's' : ''}', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
                  ]),
                  const Spacer(),
                  if (list.isNotEmpty)
                    GestureDetector(
                      onTap: () { widget.notifCtrl.markAllAsRead(); Navigator.pop(context); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                        child: Text('Marcar leídas', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
            if (list.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppTheme.greenMetal.withValues(alpha: 0.08), shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppTheme.greenMetal),
                    ),
                    const SizedBox(height: 16),
                    const Text('No hay notificaciones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    const Text('Todo está en orden', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final n = list[i];
                    final isExpiry = n['tipo']?.toString() == 'vencimiento';
                    final color = isExpiry ? AppTheme.reiOrangeRed : Colors.orange;
                    return _NotifItem(
                      index: i,
                      icon: isExpiry ? Icons.event_available_rounded : Icons.inventory_2_rounded,
                      color: color,
                      message: n['mensaje']?.toString() ?? '',
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('CERRAR'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifItem extends StatefulWidget {
  final int index;
  final IconData icon;
  final Color color;
  final String message;
  const _NotifItem({required this.index, required this.icon, required this.color, required this.message});

  @override
  State<_NotifItem> createState() => _NotifItemState();
}

class _NotifItemState extends State<_NotifItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 50 * widget.index), _ctrl.forward);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.color.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 18, color: widget.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
