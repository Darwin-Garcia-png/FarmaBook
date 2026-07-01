import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/config_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../theme/app_theme.dart';
import '../utils/user_session.dart';
import '../services/api_service.dart';
import '../widgets/premium_header.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/animations.dart';
import '../widgets/error_display.dart';

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

  @override
  Widget build(BuildContext context) {
    final dashController = Provider.of<DashboardController>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumHeader(
        title: 'Ajustes del Sistema',
        subtitle: 'Configuración general de la farmacia',
        icon: Icons.settings_rounded,
        baseColor: AppTheme.ayanamiBlue,
        hideSettings: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.titleLarge?.color),
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _controller.isLoading
          ? const ShimmerList(itemCount: 4, itemHeight: 100)
          : Stack(
              children: [
                const Positioned.fill(
                  child: ParticleBackground(color: AppTheme.ayanamiBlue, particleCount: 12),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileCard(),
                          const SizedBox(height: 40),
                          AnimatedEntry(index: 1, child: _buildSettingsGroup(
                            title: 'MI CUENTA',
                            children: [
                              HoverScale(scale: 1.01, elevation: 4, child: ListTile(
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
                              )),
                            ],
                          )),
                          if (UserSession.isDueno) const SizedBox(height: 40),
                          if (UserSession.isDueno) AnimatedEntry(index: 2, child: _buildSettingsGroup(
                            title: 'GESTIÓN DE EQUIPO',
                            children: [
                              HoverScale(scale: 1.01, elevation: 4, child: ListTile(
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
                              )),
                            ],
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
    );
  }

  void _showMyAccountDialog() {
    final emailCtrl = TextEditingController(text: UserSession.email ?? '');
    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.ayanamiBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.person_rounded, size: 24, color: AppTheme.ayanamiBlue),
                ),
                const SizedBox(width: 14),
                const Text('Mi Información', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                  style: IconButton.styleFrom(backgroundColor: Colors.grey.withValues(alpha: 0.1)),
                ),
              ]),
              const Divider(height: 24),
              _detailRow('ID de Usuario', '${UserSession.userId ?? '—'}'),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: nameCtrl,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de Usuario',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: emailCtrl,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) return 'Email inválido';
                    return null;
                  },
                ),
              ),
              _detailRow('Rol', UserSession.role ?? '—'),
              _detailRow('Tipo de Cuenta', UserSession.isDueno ? 'Administrador' : 'Empleado'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) { setDialogState(() => saving = false); return; }
                          setDialogState(() => saving = true);
                          try {
                            final data = <String, dynamic>{};
                            if (emailCtrl.text != (UserSession.email ?? '')) {
                              data['email'] = emailCtrl.text;
                            }
                            if (nameCtrl.text.isNotEmpty) {
                              data['username'] = nameCtrl.text;
                            }
                            if (data.isNotEmpty && UserSession.userId != null) {
                              final result = await ApiService.updateUser(
                                  UserSession.userId.toString(), data);
                              UserSession.save(result);
                              if (ctx.mounted) {
                                setState(() {});
                                ErrorDisplay.successSnackBar(context: ctx, message: 'Información actualizada correctamente');
                              }
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ErrorDisplay.snackBar(context: ctx, message: 'Error al actualizar');
                            }
                          } finally {
                            if (ctx.mounted) {
                              setDialogState(() => saving = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.ayanamiBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Guardar Cambios',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ),
      ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 140,
          child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showPharmacyInfoDialog() {
    final addrCtrl = TextEditingController(text: _controller.pharmacyAddress);
    final phoneCtrl = TextEditingController(text: _controller.pharmacyPhone);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setD) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.ayanamiBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.storefront_rounded, size: 24, color: AppTheme.ayanamiBlue),
                    ),
                    const SizedBox(width: 14),
                    const Text('Información de la Farmacia', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      style: IconButton.styleFrom(backgroundColor: Colors.grey.withValues(alpha: 0.1)),
                    ),
                  ]),
                  const Divider(height: 24),
                  TextFormField(
                    controller: addrCtrl,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      labelText: 'Dirección *',
                      prefixIcon: Icon(Icons.location_on_rounded, size: 18),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 5) return 'Mínimo 5 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneCtrl,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono *',
                      prefixIcon: Icon(Icons.phone_rounded, size: 18),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
                    validator: (v) {
                      final cleaned = v?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                      if (cleaned.length < 7) return 'Mínimo 7 dígitos';
                      if (cleaned.length > 15) return 'Máximo 15 dígitos';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setD(() => saving = true);
                        await _controller.cambiarDireccion(addrCtrl.text.trim());
                        await _controller.cambiarTelefono(phoneCtrl.text.trim());
                        setD(() => saving = false);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.ayanamiBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    addrCtrl.dispose();
    phoneCtrl.dispose();
  }

  Widget _buildProfileCard() {
    return AnimatedEntry(index: 0, style: EntryStyle.bounce, child: GlowEffect(
      color: AppTheme.ayanamiBlue,
      radius: 6,
      child: GlassContainer(
      padding: const EdgeInsets.all(32),
      borderRadius: 32,
      blur: 16,
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
                const Text('Farmabook', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const Text('Sistema de gestión farmacéutica',
                    style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _infoRow(Icons.location_on_rounded, _controller.pharmacyAddress),
                const SizedBox(height: 4),
                _infoRow(Icons.phone_rounded, _controller.pharmacyPhone),
              ],
            ),
          ),
          if (UserSession.isDueno)
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20, color: AppTheme.ayanamiBlue),
              tooltip: 'Editar información',
              onPressed: () => _showPharmacyInfoDialog(),
            ),
        ],
      ),
    )));
  }

  Widget _buildSettingsGroup({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
        const SizedBox(height: 20),
        GlassContainer(
          borderRadius: 32,
          blur: 12,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: children),
        ),
      ],
    );
  }
}
