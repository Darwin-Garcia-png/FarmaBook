import 'package:flutter/material.dart';
import '../controllers/usuarios_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_header.dart';
import 'package:flutter/services.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final UsuariosController _controller = UsuariosController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.fetchAll();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumHeader(
        title: 'Gestión de Personal',
        subtitle: 'Administra usuarios, cajeros y permisos',
        icon: Icons.engineering_rounded,
        baseColor: AppTheme.ayanamiBlue,
        trailing: ElevatedButton.icon(
          onPressed: () => _showAddEditUserDialog(),
          icon: const Icon(Icons.person_add_rounded),
          label: const Text('Nuevo Usuario', style: TextStyle(fontWeight: FontWeight.w900)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.ayanamiBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: AppTheme.ayanamiBlue.withOpacity(0.4),
          ),
        ),
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildUserList(),
    );
  }

  Widget _buildUserList() {
    if (_controller.usuarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.ayanamiBlue.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_outline_rounded,
                  size: 80, color: AppTheme.ayanamiBlue.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            const Text('Sin miembros en el equipo',
                style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text('Comienza agregando a tu primer empleado',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(32),
          sliver: SliverToBoxAdapter(
            child: _buildQuickStats(),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          sliver: SliverToBoxAdapter(
            child: Text('PERSONAL REGISTRADO', 
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(32),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 450,
              mainAxisExtent: 200,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final user = _controller.usuarios[index];
                final bool activo = user['activo'] ?? true;
                final String rolName = user['Rol']?['nombre'] ?? 'Personal';
                
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.ayanamiBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.center,
                              child: Text((user['nombre'] ?? user['username'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(color: AppTheme.ayanamiBlue, fontWeight: FontWeight.w900, fontSize: 32)),
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: activo ? AppTheme.greenMetal : AppTheme.reiOrangeRed,
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).cardTheme.color!, width: 4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(user['nombre'] ?? user['username'] ?? 'Usuario',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.ayanamiBlue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(rolName.toUpperCase(), 
                                  style: const TextStyle(color: AppTheme.ayanamiBlue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _actionButton(Icons.edit_rounded, AppTheme.ayanamiBlue, () => _showAddEditUserDialog(user: user)),
                            const SizedBox(height: 12),
                            _actionButton(Icons.delete_outline_rounded, AppTheme.reiOrangeRed, () => _confirmDelete(user)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: _controller.usuarios.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statCard('Total Personal', _controller.usuarios.length.toString(), Icons.people_rounded, AppTheme.ayanamiBlue),
        const SizedBox(width: 20),
        _statCard('Roles Activos', _controller.roles.length.toString(), Icons.admin_panel_settings_rounded, Colors.orange),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  void _showAddEditUserDialog({Map<String, dynamic>? user}) {
    final isEdit = user != null;
    final nombreCtrl = TextEditingController(text: user?['nombre'] ?? user?['username']);
    final realNameCtrl = TextEditingController(text: user?['nombreCompleto'] ?? user?['nombre']);
    final passCtrl = TextEditingController();
    bool showPass = false;
    String? selectedRol = user?['rolId']?.toString() ?? user?['roleId']?.toString();
    
    showDialog(
      context: context,
      barrierColor: Colors.black87.withOpacity(0.8),
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              width: 500,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40)],
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogHeader(isEdit),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DATOS DEL EMPLEADO', 
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
                          const SizedBox(height: 20),
                          _premiumField('Nombre Completo', 'Ej: Juan Pérez', realNameCtrl, Icons.badge_outlined),
                          const SizedBox(height: 12),
                          const Text('CREDENCIALES DE ACCESO', 
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
                          const SizedBox(height: 20),
                          _premiumField('Username', 'Para el inicio de sesión', nombreCtrl, Icons.alternate_email_rounded),
                          
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: passCtrl,
                                obscureText: !showPass,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: InputDecoration(
                                  hintText: isEdit ? 'Dejar en blanco para no cambiar' : 'Mínimo 8 caracteres',
                                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppTheme.ayanamiBlue),
                                  suffixIcon: IconButton(
                                    icon: Icon(showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: Colors.grey),
                                    onPressed: () => setDialogState(() => showPass = !showPass),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.withOpacity(0.05),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.reiOrangeRed, width: 1)),
                                  contentPadding: const EdgeInsets.all(20),
                                ),
                                validator: (v) {
                                  if (!isEdit && (v == null || v.isEmpty)) return 'Contraseña requerida';
                                  if (v != null && v.isNotEmpty && v.length < 8) return 'Mínimo 8 caracteres';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),

                          const SizedBox(height: 8),
                          const Text('AUTORIZACIÓN DE RANGO', 
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
                          const SizedBox(height: 16),
                          _buildRoleSelector(selectedRol, (v) => setDialogState(() => selectedRol = v)),
                        ],
                      ),
                    ),
                  ),
                  _dialogActions(context, isEdit, nombreCtrl, realNameCtrl, passCtrl, selectedRol, user),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _dialogHeader(bool isEdit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.ayanamiBlue.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Icon(isEdit ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded, color: AppTheme.ayanamiBlue, size: 32),
          const SizedBox(width: 16),
          Text(isEdit ? 'Refinar Perfil' : 'Añadir al Equipo', 
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _premiumField(String label, String hint, TextEditingController ctrl, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4A5568))),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          inputFormatters: [
            if (label.toLowerCase().contains('nombre')) FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
          ],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            prefixIcon: Icon(icon, size: 20, color: AppTheme.ayanamiBlue),
            filled: true,
            fillColor: Colors.grey.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.reiOrangeRed, width: 1)),
            contentPadding: const EdgeInsets.all(20),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Este campo es obligatorio';
            if (label.toLowerCase().contains('nombre') && RegExp(r'[0-9]').hasMatch(v)) return 'No se permiten números';
            return null;
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRoleSelector(String? selected, Function(String) onSelect) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _controller.roles.map((r) {
        final isSelected = r['rolId']?.toString() == selected;
        final name = r['nombre'].toString().toLowerCase();
        IconData roleIcon = Icons.badge_outlined;
        if (name.contains('admin')) roleIcon = Icons.admin_panel_settings_rounded;
        if (name.contains('cajer')) roleIcon = Icons.point_of_sale_rounded;
        if (name.contains('dueño')) roleIcon = Icons.stars_rounded;

        return GestureDetector(
          onTap: () => onSelect(r['rolId'].toString()),
          child: Container(
            width: 130,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.ayanamiBlue : AppTheme.ayanamiBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? AppTheme.ayanamiBlue : Colors.transparent, width: 2),
            ),
            child: Column(
              children: [
                Icon(roleIcon, color: isSelected ? Colors.white : AppTheme.ayanamiBlue, size: 28),
                const SizedBox(height: 8),
                Text(r['nombre'], 
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold, 
                    color: isSelected ? Colors.white : AppTheme.ayanamiBlue
                  ),
                textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dialogActions(BuildContext context, bool isEdit, TextEditingController n, TextEditingController rn, TextEditingController p, String? r, Map<String, dynamic>? u) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () async {
                if (n.text.isEmpty || (!isEdit && p.text.isEmpty) || r == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Revisa los campos obligatorios')));
                  return;
                }
                final data = {
                  'username': n.text.trim(),
                  'password': p.text,
                  'roleId': r,
                };
                try {
                  if (isEdit) {
                    await _controller.updateUser(u!['usuarioId'], data);
                  } else {
                    await _controller.createUser(data);
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Operación realizada con éxito!')));
                } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aviso: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.ayanamiBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(isEdit ? 'GUARDAR USUARIO' : 'REGISTRAR EMPLEADO', style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('¿Desactivar miembro?'),
        content: Text('${user['nombre'] ?? user['username']} perderá el acceso al sistema inmediatamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () async {
              await _controller.deleteUser(user['usuarioId']);
              Navigator.pop(context);
            },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }
}
