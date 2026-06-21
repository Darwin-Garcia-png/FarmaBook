import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/usuarios_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_header.dart';
import '../widgets/error_display.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/animations.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final UsuariosController _ctrl = UsuariosController();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onChanged);
    _ctrl.fetchAll();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChanged);
    _ctrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Color get _accent => AppTheme.ayanamiBlue;

  List<Map<String, dynamic>> get _filtered {
    final src = _ctrl.showDeleted ? _ctrl.deletedUsuarios : _ctrl.usuarios;
    final q = _searchQuery.toLowerCase().trim();
    if (q.isEmpty) return src;
    return src.where((u) {
      final n = (u['nombre'] ?? '').toString().toLowerCase();
      final e = (u['email'] ?? '').toString().toLowerCase();
      final r = (u['rolNombre'] ?? '').toString().toLowerCase();
      return n.contains(q) || e.contains(q) || r.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loading = _ctrl.isLoading || _ctrl.isLoadingDeleted;
    final hasError = _ctrl.error != null && _ctrl.usuarios.isEmpty && _ctrl.deletedUsuarios.isEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumHeader(
        title: 'Personal',
        subtitle: 'Administra usuarios y permisos',
        icon: Icons.engineering_rounded,
        baseColor: _accent,
        trailing: loading ? null : Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 20, color: _accent.withValues(alpha: 0.7)),
            onPressed: () { _ctrl.fetchAll(); if (_ctrl.showDeleted) _ctrl.fetchDeleted(); },
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
        ]),
      ),
      body: loading
          ? const ShimmerList(itemCount: 5, itemHeight: 80)
          : hasError
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off_rounded, size: 80, color: AppTheme.reiOrangeRed),
        const SizedBox(height: 16),
        Text(_ctrl.error!, style: const TextStyle(color: AppTheme.reiOrangeRed, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          onPressed: _ctrl.fetchAll,
        ),
      ]),
    );
  }

  Widget _buildContent() {
    final list = _filtered;
    return Stack(
      children: [
        Column(
          children: [
            _buildSearchBar(),
            _buildToggleTabs(),
            Expanded(
              child: list.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(32, 4, 32, 100),
                      children: list.asMap().entries.map((e) => AnimatedEntry(
                        index: e.key,
                        child: _buildUserCard(e.value, e.key),
                      )).toList(),
                    ),
            ),
          ],
        ),
        Positioned(
          bottom: 24,
          right: 32,
          child: FloatingActionButton.extended(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.person_add_rounded, size: 22),
            label: const Text('Añadir', style: TextStyle(fontWeight: FontWeight.w900)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => _showAddEditDialog(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, email o rol...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.ayanamiBlue),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                  onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); })
              : null,
          filled: true,
          fillColor: Theme.of(context).cardTheme.color,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildToggleTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 14, 32, 0),
      child: Row(
        children: [
          _tabChip('ACTIVOS (${_ctrl.usuarios.length})', !_ctrl.showDeleted, () {
            _ctrl.showDeleted = false; setState(() {});
          }),
          const SizedBox(width: 10),
          _tabChip('ELIMINADOS (${_ctrl.deletedUsuarios.length})', _ctrl.showDeleted, () {
            _ctrl.showDeleted = true;
            if (_ctrl.deletedUsuarios.isEmpty) _ctrl.fetchDeleted();
            setState(() {});
          }),
          const Spacer(),
                          Text('${_filtered.length} encontrados',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _tabChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _accent : _accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? _accent : _accent.withValues(alpha: 0.15), width: active ? 0 : 1),
        ),
        child: Text(label,
          style: TextStyle(
            color: active ? Colors.white : _accent,
            fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _ctrl.showDeleted ? AppTheme.reiOrangeRed.withValues(alpha: 0.06) : _accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              _ctrl.showDeleted ? Icons.archive_outlined : Icons.people_outline_rounded,
              size: 56,
              color: _ctrl.showDeleted ? AppTheme.reiOrangeRed.withValues(alpha: 0.4) : _accent.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _ctrl.showDeleted ? 'No hay usuarios eliminados' : 'Aún no hay personal registrado',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w700),
          ),
          if (!_ctrl.showDeleted) ...[
            const SizedBox(height: 8),
            Text('Presiona + para añadir el primer miembro',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ],
        ],
      ),
    );
  }

  Color _roleColor(String rol) {
    final r = rol.toLowerCase();
    if (r.contains('dueño')) return const Color(0xFFD4AF37);
    if (r.contains('admin')) return AppTheme.ayanamiBlue;
    if (r.contains('cajer')) return AppTheme.greenMetal;
    return Colors.orange;
  }

  IconData _roleIcon(String rol) {
    final r = rol.toLowerCase();
    if (r.contains('dueño')) return Icons.stars_rounded;
    if (r.contains('admin')) return Icons.admin_panel_settings_rounded;
    if (r.contains('cajer')) return Icons.point_of_sale_rounded;
    return Icons.badge_outlined;
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final isDeleted = _ctrl.showDeleted;
    final name = user['nombre']?.toString() ?? 'Sin nombre';
    final email = user['email']?.toString() ?? '';
    final rol = user['rolNombre']?.toString() ?? 'Personal';
    final rolCol = _roleColor(rol);
    final createdAt = user['createdAt']?.toString() ?? '';
    final dateStr = createdAt.length >= 10 ? createdAt.substring(0, 10) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: isDeleted ? AppTheme.reiOrangeRed.withValues(alpha: 0.04) : _accent.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 20, 4),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDeleted ? AppTheme.reiOrangeRed : rolCol,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [rolCol, rolCol.withValues(alpha: 0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: rolCol.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          if (isDeleted) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.reiOrangeRed.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('INACTIVO',
                                style: TextStyle(color: AppTheme.reiOrangeRed, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email_outlined, size: 11, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(email.isNotEmpty ? email : '—',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(_roleIcon(rol), size: 12, color: rolCol),
                          const SizedBox(width: 4),
                          Text(rol, style: TextStyle(fontSize: 12, color: rolCol, fontWeight: FontWeight.w700)),
                          if (dateStr.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.calendar_today_rounded, size: 10, color: Colors.grey.shade400),
                            const SizedBox(width: 3),
                            Text(dateStr, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isDeleted)
                  _actionIcon(Icons.restore_from_trash_rounded, AppTheme.greenMetal, () => _confirmRestore(user))
                else ...[
                  _actionIcon(Icons.edit_rounded, rolCol, () => _showAddEditDialog(user: user)),
                  const SizedBox(width: 6),
                  _actionIcon(Icons.delete_outline_rounded, AppTheme.reiOrangeRed, () => _confirmDelete(user)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  // ─── DIALOG ──────────────────────────────────────────────

  Future<void> _showAddEditDialog({Map<String, dynamic>? user}) async {
    final isEdit = user != null;
    final formKey = GlobalKey<FormState>();
    final usernameCtrl = TextEditingController(text: user?['username'] ?? '');
    final emailCtrl = TextEditingController(text: user?['email'] ?? '');
    final passCtrl = TextEditingController();
    final currentPassCtrl = TextEditingController();
    bool showPass = false;
    bool showCurrent = false;

    final usernameFocus = FocusNode();
    final emailFocus = FocusNode();
    final passFocus = FocusNode();
    final currentPassFocus = FocusNode();

    Future<void> handleSubmit(BuildContext ctx, GlobalKey<FormState> fKey) async {
      if (!fKey.currentState!.validate()) return;
      final data = <String, dynamic>{
        'username': usernameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
      };
      if (passCtrl.text.isNotEmpty) data['password'] = passCtrl.text;
      if (isEdit && currentPassCtrl.text.isNotEmpty) data['currentPassword'] = currentPassCtrl.text;
      try {
        if (isEdit) {
          await _ctrl.updateUser(user['usuarioId'], data);
        } else {
          await _ctrl.createUser(data);
        }
        if (ctx.mounted) Navigator.pop(ctx);
        if (context.mounted) {
          ErrorDisplay.successSnackBar(context: context, message: '¡Operación realizada con éxito!');
        }
      } catch (e) {
        if (context.mounted) {
          ErrorDisplay.snackBar(context: context, message: '$e');
        }
      }
    }

    try {
      await showDialog(
        context: context,
        barrierColor: Colors.black87.withValues(alpha: 0.8),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setDState) {
              return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              clipBehavior: Clip.antiAlias,
              child: GlassContainer(
                child: Container(
                width: 480,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogHeader(isEdit),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _section('ACCESO AL SISTEMA'),
                              const SizedBox(height: 16),
                              _formField('Usuario *', usernameCtrl, Icons.alternate_email_rounded,
                                  hint: 'Ej: juan.perez',
                                  focusNode: usernameFocus,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => FocusScope.of(ctx).requestFocus(emailFocus)),
                              const SizedBox(height: 4),
                              _formField('Email *', emailCtrl, Icons.email_outlined,
                                  keyboard: TextInputType.emailAddress, hint: 'ejemplo@correo.com',
                                  focusNode: emailFocus,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => FocusScope.of(ctx).requestFocus(passFocus)),
                              const SizedBox(height: 4),
                              _passField('Contraseña', passCtrl, showPass, () => setDState(() => showPass = !showPass),
                                  isEdit: isEdit,
                                  focusNode: passFocus,
                                  textInputAction: isEdit ? TextInputAction.next : TextInputAction.done,
                                  onFieldSubmitted: isEdit
                                      ? (_) => FocusScope.of(ctx).requestFocus(currentPassFocus)
                                      : (_) => handleSubmit(ctx, formKey)),
                              if (isEdit) ...[
                                const SizedBox(height: 4),
                                _passField('Contraseña actual *', currentPassCtrl, showCurrent,
                                    () => setDState(() => showCurrent = !showCurrent),
                                    hint: 'Necesaria para confirmar cambios',
                                    focusNode: currentPassFocus,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => handleSubmit(ctx, formKey)),
                              ],
                              const SizedBox(height: 4),
                              if (!isEdit)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, size: 14, color: Colors.grey.shade400),
                                      const SizedBox(width: 6),
                                      Text('El rol se asigna automáticamente al registrarse',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _dialogActions(ctx, formKey, isEdit, usernameCtrl, emailCtrl, passCtrl, currentPassCtrl, user,
                        () => handleSubmit(ctx, formKey)),
                  ],
                ),
              ),
              ),
            );
          },
        );
      },
    );
    } finally {
      usernameFocus.dispose();
      emailFocus.dispose();
      passFocus.dispose();
      currentPassFocus.dispose();
    }
  }

  Widget _section(String text) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(
          color: _accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _dialogHeader(bool isEdit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, _accent.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
            child: Icon(isEdit ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isEdit ? 'Editar Usuario' : 'Nuevo Usuario',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(isEdit ? 'Modifica los datos del empleado' : 'Registra un nuevo miembro del equipo',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }

  Widget _formField(String label, TextEditingController ctrl, IconData icon,
      {TextInputType keyboard = TextInputType.text, String hint = '',
      FocusNode? focusNode, TextInputAction? textInputAction, ValueChanged<String>? onFieldSubmitted}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4A5568))),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            focusNode: focusNode,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            keyboardType: keyboard,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              hintText: hint.isNotEmpty ? hint : 'Ingresa $label',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(icon, size: 20, color: _accent.withValues(alpha: 0.6)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
              filled: true,
              fillColor: Colors.grey.withValues(alpha: 0.04),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _accent.withValues(alpha: 0.5), width: 1.5)),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.reiOrangeRed, width: 1)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Este campo es obligatorio';
              if (label.toLowerCase().contains('email')) {
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Email inválido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _passField(String label, TextEditingController ctrl, bool obscure, VoidCallback toggle,
      {bool isEdit = false, String hint = 'Mínimo 8 caracteres',
      FocusNode? focusNode, TextInputAction? textInputAction, ValueChanged<String>? onFieldSubmitted}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4A5568))),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            focusNode: focusNode,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
            obscureText: !obscure,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              hintText: isEdit ? 'Dejar en blanco para no cambiar' : hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.lock_outline_rounded, size: 20, color: _accent.withValues(alpha: 0.6)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: Colors.grey),
                onPressed: toggle,
              ),
              filled: true,
              fillColor: Colors.grey.withValues(alpha: 0.04),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _accent.withValues(alpha: 0.5), width: 1.5)),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.reiOrangeRed, width: 1)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) {
              if (!isEdit && (v == null || v.isEmpty)) return 'Contraseña requerida';
              if (v != null && v.isNotEmpty && v.length < 8) return 'Mínimo 8 caracteres';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _dialogActions(
    BuildContext ctx,
    GlobalKey<FormState> formKey,
    bool isEdit,
    TextEditingController usernameCtrl,
    TextEditingController emailCtrl,
    TextEditingController passCtrl,
    TextEditingController currentPassCtrl,
    Map<String, dynamic>? user,
    VoidCallback? onSubmit,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueGrey,
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(isEdit ? 'GUARDAR CAMBIOS' : 'REGISTRAR', style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.reiOrangeRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.person_off_rounded, color: AppTheme.reiOrangeRed, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Desactivar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ]),
        content: Text('${user['nombre']} perderá el acceso al sistema inmediatamente. Puedes restaurarlo después.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.reiOrangeRed, foregroundColor: Colors.white),
            onPressed: () async {
              await _ctrl.deleteUser(user['usuarioId']);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('DESACTIVAR'),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.greenMetal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.greenMetal, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Restaurar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ]),
        content: Text('${user['nombre']} recuperará el acceso al sistema.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenMetal, foregroundColor: Colors.white),
            onPressed: () async {
              await _ctrl.restoreUser(user['usuarioId']);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('RESTAURAR'),
          ),
        ],
      ),
    );
  }
}
