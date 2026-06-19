import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/config_controller.dart';
import '../providers/theme_provider.dart';
import '../controllers/dashboard_controller.dart';
import '../theme/app_theme.dart';
import '../utils/user_session.dart';
import '../widgets/premium_header.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/animations.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final ConfigController _controller = ConfigController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.cargarPreferencias();
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

  void _showEditNameDialog() {
    final ctrl = TextEditingController(text: _controller.pharmacyName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editar Nombre de Farmacia'),
        content: TextField(
          controller: ctrl,
          decoration:
              const InputDecoration(hintText: 'Ej. FarmaSalud Principal'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.ayanamiBlue,
                foregroundColor: Colors.white),
            onPressed: () {
              _controller.cambiarNombreFarmacia(ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _handleThemeToggle(bool isDark) {
    Provider.of<ThemeProvider>(context, listen: false).toggleTheme(isDark);
    _controller.cambiarTema(isDark);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final dashController = Provider.of<DashboardController>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumHeader(
        title: 'Ajustes del Sistema',
        subtitle: 'Configuración general de la farmacia',
        icon: Icons.settings_rounded,
        baseColor: AppTheme.ayanamiBlue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.titleLarge?.color),
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _controller.isLoading
          ? const ShimmerList(itemCount: 4, itemHeight: 100)
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileCard(),
                      const SizedBox(height: 40),
                      _buildSettingsGroup(
                        title: 'MI CUENTA',
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.all(24),
                            leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: AppTheme.reiPurple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16)),
                                child: const Icon(Icons.person_rounded, color: AppTheme.reiPurple, size: 24)),
                            title: const Text('Información Personal', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            subtitle: Text('${UserSession.role ?? "—"} · ${UserSession.email ?? "—"}',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _showMyAccountDialog(),
                          ),
                        ],
                      ),
                      if (UserSession.isDueno) ...[
                      const SizedBox(height: 40),
                      _buildSettingsGroup(
                        title: 'GESTIÓN DE EQUIPO',
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.all(24),
                            leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                                child: const Icon(Icons.people_alt_rounded, color: Colors.orange, size: 24)),
                            title: const Text('Personal y Roles', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            subtitle: const Text('Gestiona usuarios, permisos y accesos al sistema'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                                dashController.onItemTapped(10); 
                                Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      ],
                      const SizedBox(height: 40),
                      _buildSettingsGroup(
                        title: 'EXPERIENCIA Y PREFERENCIAS',
                        children: [
                          _buildSwitchTile(
                              'Modo Oscuro',
                              'Adaptación visual premium estilo consola Rei',
                              Icons.dark_mode_rounded,
                              isDark,
                              _handleThemeToggle),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _showMyAccountDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            width: 380,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 12))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.reiPurple, AppTheme.reiPurple.withValues(alpha: 0.85)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(UserSession.email ?? 'Sin correo',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        UserSession.role ?? 'Sin rol',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    if (UserSession.userId != null)
                      _detailRow(Icons.tag_rounded, 'ID de Usuario', '${UserSession.userId}'),
                    _detailRow(Icons.email_rounded, 'Correo Electrónico', UserSession.email ?? '—'),
                    _detailRow(Icons.badge_rounded, 'Rol', UserSession.role ?? '—'),
                    _detailRow(Icons.verified_rounded, 'Tipo de Cuenta', UserSession.isDueno ? 'Administrador' : 'Empleado'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('CERRAR'),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Icon(icon, size: 18, color: AppTheme.reiPurple.withValues(alpha: 0.6)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 30, offset: const Offset(0, 10))
        ],
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.ayanamiBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(Icons.storefront_rounded, size: 40, color: AppTheme.ayanamiBlue),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_controller.pharmacyName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(width: 12),
                    IconButton(icon: const Icon(Icons.edit_rounded, size: 20, color: Colors.grey), onPressed: _showEditNameDialog),
                  ],
                ),
                Text('Administrador de Sistema · ${_controller.userEmail}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 30, offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon,
      bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SwitchListTile(
        secondary: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppTheme.ayanamiBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: Icon(icon, color: AppTheme.ayanamiBlue, size: 24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle,
              style: TextStyle(
                color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.6) ?? Colors.grey)),
        ),
        value: value,
        activeColor: AppTheme.ayanamiBlue,
        onChanged: onChanged,
      ),
    );
  }
}
