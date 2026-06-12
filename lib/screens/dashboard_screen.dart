import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/almacen_controller.dart';
import '../controllers/lotes_controller.dart';
import '../controllers/ventas_controller.dart';
import '../controllers/notificaciones_controller.dart';
import '../theme/app_theme.dart';
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
            color: Theme.of(context).cardTheme.color?.withOpacity(0.95),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
              _buildLogoutItem(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: Stack(children: [
        RepaintBoundary(child: _buildScreen()),
        if (_controller.selectedIndex != 0)
          Positioned(top: 88, left: 12,
            child: FloatingActionButton.small(
              heroTag: 'backBtn',
              onPressed: () => _controller.onItemTapped(0),
              backgroundColor: AppTheme.ayanamiBlue,
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
      ]),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.ayanamiBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.local_pharmacy_rounded, size: 32, color: AppTheme.ayanamiBlue),
          ),
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
                color: AppTheme.ayanamiBlue.withOpacity(0.3),
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
                  color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7), 
                  fontSize: 15, 
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  letterSpacing: isSelected ? 0.2 : 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSubItem(IconData icon, String title, int index) {
    final isSelected = _controller.selectedIndex == index;
    
    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 4, right: 8),
      child: InkWell(
        onTap: () {
          _controller.onItemTapped(index);
          if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.ayanamiBlue.withOpacity(0.1) : Colors.transparent,
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
                  color: isSelected ? AppTheme.ayanamiBlue : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6), 
                  fontSize: 14, 
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
          Navigator.pop(context);
          context.read<AlmacenController>().clearData();
          context.read<LotesController>().clearData();
          context.read<VentasController>().clearData();
          context.read<NotificacionesController>().clearData();
          
          await _controller.logout();
          if (mounted) context.go('/login');
        },
      ),
    );
  }
}
