import 'package:flutter/material.dart';
import '../controllers/usuarios_controller.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final UsuariosController _controller = UsuariosController();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.fetchAll();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Color get _accent => AppTheme.ayanamiBlue;

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return _controller.usuarios.cast<Map<String, dynamic>>();
    return _controller.usuarios.cast<Map<String, dynamic>>().where((u) {
      final name = (u['nombre'] ?? u['username'] ?? '').toString().toLowerCase();
      final rol = (u['Rol']?['nombre'] ?? '').toString().toLowerCase();
      return name.contains(q) || rol.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final text = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final card = Theme.of(context).cardTheme.color ?? Colors.white;
    final accent = _accent;

    if (_controller.isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: Stack(children: [
          Positioned(top: 0, left: 0, right: 0, child: _buildHeader(bg, text, accent)),
          const Center(child: CircularProgressIndicator(color: AppTheme.ayanamiBlue)),
        ]),
      );
    }

    if (_controller.error != null) {
      return Scaffold(
        backgroundColor: bg,
        body: Stack(children: [
          Positioned(top: 0, left: 0, right: 0, child: _buildHeader(bg, text, accent)),
          Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.cloud_off_rounded, size: 80, color: AppTheme.reiOrangeRed),
              const SizedBox(height: 16),
              Text(_controller.error!, style: const TextStyle(color: AppTheme.reiOrangeRed, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                onPressed: _controller.fetchAll,
                style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
              ),
            ]),
          ),
        ]),
      );
    }

    final list = _filtered;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 100, 40, 60),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSearchBar(accent, bg, text),
            if (_controller.usuarios.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildQuickStats(text, card),
            ],
            const SizedBox(height: 20),
            if (list.isEmpty)
              _buildEmptyState(accent)
            else
              ...list.map((user) => _buildUserCard(user, accent, text, card)),
          ]),
        ),
        Positioned(top: 0, left: 0, right: 0, child: _buildHeader(bg, text, accent)),
        Positioned(bottom: 24, right: 40,
          child: FloatingActionButton(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => _showAddEditUserDialog(),
            child: const Icon(Icons.person_add_rounded, size: 28),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader(Color bg, Color text, Color accent) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(color: bg, border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.08)))),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.engineering_rounded, color: AppTheme.ayanamiBlue, size: 24),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('PERSONAL', style: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          Text('Administra usuarios y permisos', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _buildSearchBar(Color accent, Color bg, Color text) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Buscar personal...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 18), onPressed: () { _searchCtrl.clear(); setState(() {}); })
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: bg.withOpacity(0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildQuickStats(Color text, Color card) {
    return Row(children: [
      _statCard('Total Personal', _controller.usuarios.length.toString(), Icons.people_rounded, _accent, text, card),
      const SizedBox(width: 16),
      _statCard('Roles Activos', _controller.roles.length.toString(), Icons.admin_panel_settings_rounded, const Color(0xFFF59E0B), text, card),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color, Color text, Color card) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -1, color: text)),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.5)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(color: _cardColor(context), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(children: [
        Icon(Icons.people_outline_rounded, size: 64, color: accent.withOpacity(0.3)),
        const SizedBox(height: 16),
        Text('Sin miembros en el equipo', style: TextStyle(fontSize: 18, color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Agrega a tu primer empleado', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ]),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, Color accent, Color text, Color card) {
    final bool activo = user['activo'] ?? true;
    final String rolName = user['Rol']?['nombre'] ?? 'Personal';
    final String displayName = user['nombre'] ?? user['username'] ?? 'Usuario';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: activo ? accent.withOpacity(0.4) : AppTheme.reiOrangeRed.withOpacity(0.4), width: 3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: accent.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: Text(displayName[0].toUpperCase(),
                  style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 22)),
              ),
              Container(width: 14, height: 14,
                decoration: BoxDecoration(
                  color: activo ? AppTheme.greenMetal : AppTheme.reiOrangeRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: card, width: 3),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(displayName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: text), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: accent.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                  child: Text(rolName.toUpperCase(), style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: activo ? AppTheme.greenMetal.withOpacity(0.08) : AppTheme.reiOrangeRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(activo ? 'ACTIVO' : 'INACTIVO',
                    style: TextStyle(color: activo ? AppTheme.greenMetal : AppTheme.reiOrangeRed, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ]),
            ]),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            _actionButton(Icons.edit_rounded, accent, () => _showAddEditUserDialog(user: user)),
            const SizedBox(height: 6),
            _actionButton(Icons.delete_outline_rounded, AppTheme.reiOrangeRed, () => _confirmDelete(user)),
          ]),
        ]),
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: color),
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
        color: _accent.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Icon(isEdit ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded, color: _accent, size: 32),
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
            prefixIcon: Icon(icon, size: 20, color: _accent),
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
              color: isSelected ? _accent : _accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? _accent : Colors.transparent, width: 2),
            ),
            child: Column(
              children: [
                Icon(roleIcon, color: isSelected ? Colors.white : _accent, size: 28),
                const SizedBox(height: 8),
                Text(r['nombre'], 
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold, 
                    color: isSelected ? Colors.white : _accent
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
                backgroundColor: _accent,
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

  Color _cardColor(BuildContext context) => Theme.of(context).cardTheme.color ?? Colors.white;
}
