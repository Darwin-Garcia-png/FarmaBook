import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/proveedores_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/error_display.dart';
import '../widgets/shimmer_loading.dart';
import '../services/api_service.dart';
import '../widgets/animations.dart';
import 'package:flutter/services.dart';
import '../controllers/dashboard_controller.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final ProveedoresController _controller = ProveedoresController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _controller.init();
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

  Color get _accent => AppTheme.reiPurple;

  Future<void> _showSupplierHouses(Map<String, dynamic> supplier) async {
    final supplierId = supplier['proveedorId']?.toString() ?? '';
    if (supplierId.isEmpty) return;

    List<dynamic> houses = [];
    bool loading = true;

    try {
      houses = await ApiService.getSupplierProductHouses(supplierId);
    } catch (_) {} finally { loading = false; }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Theme.of(context).cardTheme.color,
        child: Container(
          width: 500,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.reiPurple, AppTheme.reiPurple.withValues(alpha: 0.8)]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.business_rounded, color: Colors.white, size: 28)),
                  const SizedBox(width: 16),
                  Expanded(child: Text('Casas que distribuye ${supplier['nombre'] ?? ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900))),
                  IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                ]),
              ),
              Flexible(
                child: loading
                  ? const Center(child: SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3)))
                  : houses.isEmpty
                    ? const Center(child: Text('Sin casas asociadas', style: TextStyle(color: Colors.grey)))
                    : ListView(
                        padding: const EdgeInsets.all(24),
                        children: houses.map((h) => Container(
                          margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppTheme.reiPurple.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.reiPurple.withValues(alpha: 0.1))),
                          child: Row(children: [
                            Icon(Icons.business_rounded, size: 16, color: AppTheme.reiPurple),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(h['nombre'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              if (h['paisDeOrigen'] != null && h['paisDeOrigen'].toString().isNotEmpty)
                                Text(h['paisDeOrigen'], style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ])),
                          ]),
                        )).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? supplier}) async {
    final isEdit = supplier != null;
    final formKey = GlobalKey<FormState>();

    final nombre = TextEditingController(text: supplier?['nombre'] ?? '');
    final direccion = TextEditingController(text: supplier?['direccion'] ?? '');
    final telefono = TextEditingController(text: supplier?['telefono'] ?? '');
    final email = TextEditingController(text: supplier?['email'] ?? '');

    final nombreFn = FocusNode();
    final direccionFn = FocusNode();
    final telefonoFn = FocusNode();
    final emailFn = FocusNode();

    Future<void> submit(BuildContext diaCtx) async {
      if (!formKey.currentState!.validate()) return;

      final data = {
        'nombre': nombre.text.trim(),
        'direccion': direccion.text.trim(),
        'telefono': telefono.text.trim(),
        'email': email.text.trim(),
      };

      bool success;
      if (isEdit) {
        success = await _controller.actualizarProveedor(supplier['proveedorId'], data);
      } else {
        _controller.nombreCtrl.text = data['nombre']!;
        _controller.direccionCtrl.text = data['direccion']!;
        _controller.telefonoCtrl.text = data['telefono']!;
        _controller.emailCtrl.text = data['email']!;
        success = await _controller.agregarProveedor();
      }

      if (mounted) {
        if (success) {
          Navigator.pop(diaCtx);
          ErrorDisplay.successSnackBar(context: context, message: isEdit ? 'Proveedor actualizado' : 'Proveedor registrado');
        } else {
          ErrorDisplay.snackBar(
            context: context,
            message: _controller.error ?? 'Error al guardar. Verifica los datos e inténtalo de nuevo.',
            title: 'Error al guardar',
          );
        }
      }
    }

    try {
      showDialog(
        context: context,
        builder: (diaCtx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Theme.of(context).cardTheme.color,
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isEdit ? 'Editar Proveedor' : 'Nuevo Proveedor',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color)),
                        IconButton(icon: Icon(Icons.close, color: Theme.of(context).textTheme.bodyLarge?.color), onPressed: () => Navigator.pop(diaCtx)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildField('Nombre de la Empresa *', nombre, Icons.business, req: true,
                        focusNode: nombreFn, textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(direccionFn)),
                    _buildField('Dirección *', direccion, Icons.location_on, req: true,
                        focusNode: direccionFn, textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => FocusScope.of(diaCtx).requestFocus(telefonoFn)),
                    _buildField('Teléfono *', telefono, Icons.phone, req: true, keyboard: TextInputType.phone,
                        focusNode: telefonoFn, textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => FocusScope.of(diaCtx).requestFocus(emailFn)),
                    _buildField('Email *', email, Icons.email, req: true, keyboard: TextInputType.emailAddress,
                        focusNode: emailFn, textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => submit(diaCtx)),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(diaCtx), child: Text('Cancelar', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => submit(diaCtx),
                          child: Text(isEdit ? 'Guardar Cambios' : 'Registrar Proveedor', style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      nombreFn.dispose();
      direccionFn.dispose();
      telefonoFn.dispose();
      emailFn.dispose();
    }
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon,
      {bool req = false, TextInputType keyboard = TextInputType.text,
       FocusNode? focusNode, TextInputAction? textInputAction,
       ValueChanged<String>? onFieldSubmitted}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        focusNode: focusNode,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        keyboardType: keyboard,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        inputFormatters: [
          if (keyboard == TextInputType.phone || keyboard == TextInputType.number) FilteringTextInputFormatter.digitsOnly,
          if (label.toLowerCase().contains('nombre')) FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _accent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.reiOrangeRed, width: 1)),
        ),
        validator: (v) {
          if (req && (v == null || v.trim().isEmpty)) return 'Requerido';
          if (label.toLowerCase().contains('nombre') && v != null && RegExp(r'[0-9]').hasMatch(v)) {
            return 'No se permiten números en el nombre';
          }
          if (keyboard == TextInputType.phone && v != null && v.isNotEmpty) {
            if (v.length < 6) return 'Mínimo 6 dígitos';
            if (v.length > 10) return 'Máximo 10 dígitos';
          }
          if (keyboard == TextInputType.emailAddress && v != null && v.isNotEmpty) {
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Email inválido';
          }
          return null;
        },
      ),
    );
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
          const ShimmerList(itemCount: 5, itemHeight: 80),
        ]),
      );
    }

    if (_controller.error != null) {
      return Scaffold(
        backgroundColor: bg,
        body: Stack(children: [
          Positioned(top: 0, left: 0, right: 0, child: _buildHeader(bg, text, accent)),
          ErrorDisplay.fullScreen(
            title: 'Error al cargar',
            message: _controller.error!,
            onRetry: _controller.cargarProveedores,
          ),
        ]),
      );
    }

    final list = _controller.filteredProveedores;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 100, 40, 60),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSearchBar(accent, bg, text),
            const SizedBox(height: 24),
            if (list.isEmpty)
              _buildEmptyState(accent)
            else
              ...list.asMap().entries.map((e) => AnimatedEntry(
                index: e.key,
                child: _buildCard(e.value, accent, text, card),
              )),
          ]),
        ),
        Positioned(top: 0, left: 0, right: 0, child: _buildHeader(bg, text, accent)),
        Positioned(bottom: 24, right: 40,
          child: HoverScale(
            glowColor: accent,
            child: FloatingActionButton(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () => _showAddEditDialog(),
              child: const Icon(Icons.add_rounded, size: 28),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader(Color bg, Color text, Color accent) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(color: bg),
      child: Row(children: [
        IconButton(
          icon: Icon(Icons.menu_rounded, color: text, size: 24),
          onPressed: () {
            ScaffoldState? scaffold = Scaffold.maybeOf(context);
            while (scaffold != null && !scaffold.hasDrawer) {
              scaffold = scaffold.context.findAncestorStateOfType<ScaffoldState>();
            }
            scaffold?.openDrawer();
          },
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.local_shipping_rounded, color: AppTheme.reiPurple, size: 24),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('PROVEEDORES', style: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          Text('Gestiona tus fuentes de suministro', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _buildSearchBar(Color accent, Color bg, Color text) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _controller.searchCtrl,
        onChanged: (v) => _controller.search(v),
        decoration: InputDecoration(
          hintText: 'Buscar proveedores...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
          suffixIcon: _controller.searchCtrl.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 18), onPressed: () { _controller.searchCtrl.clear(); _controller.search(''); })
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: bg.withValues(alpha: 0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(color: _cardColor(context), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(children: [
        Icon(Icons.local_shipping_outlined, size: 64, color: accent.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text('No se encontraron proveedores', style: TextStyle(fontSize: 18, color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Agrega un nuevo proveedor', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Agregar nuevo', style: TextStyle(fontWeight: FontWeight.w900)),
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: () => _showAddEditDialog(),
        ),
      ]),
    );
  }

  Widget _buildCard(Map<String, dynamic> p, Color accent, Color text, Color card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.business_rounded, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['nombre'] ?? 'Sin nombre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: text), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              _iconText(Icons.email_rounded, p['email'] ?? 'No especificado'),
              const SizedBox(height: 4),
              _iconText(Icons.phone_rounded, p['telefono'] ?? 'No especificado'),
              const SizedBox(height: 4),
              _iconText(Icons.location_on_rounded, p['direccion'] ?? 'No especificado', maxLines: 1),
            ]),
          ),
          const SizedBox(width: 8),
          Column(mainAxisSize: MainAxisSize.min, children: [
            _actionButton(Icons.info_outline_rounded, AppTheme.ayanamiBlue, () => _showSupplierHouses(p)),
            const SizedBox(height: 6),
            _actionButton(Icons.edit_rounded, accent, () => _showAddEditDialog(supplier: p)),
            const SizedBox(height: 6),
            _actionButton(Icons.delete_rounded, AppTheme.reiOrangeRed, () => _confirmDelete(p)),
          ]),
        ]),
      ),
    );
  }

  Widget _iconText(IconData icon, String text, {int maxLines = 1}) {
    return Row(children: [
      Icon(icon, size: 12, color: Colors.grey.shade400),
      const SizedBox(width: 4),
      Expanded(
        child: Text(text, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600),
          maxLines: maxLines, overflow: TextOverflow.ellipsis),
      ),
    ]);
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text('Eliminar Proveedor', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color)),
        content: Text('¿Deseas eliminar a "${p['nombre']}"? Esta acción no se puede deshacer.', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.reiOrangeRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _controller.eliminarProveedor(p['proveedorId']);
      if (mounted) {
        if (success) {
          ErrorDisplay.successSnackBar(context: context, message: 'Proveedor eliminado');
        } else {
          ErrorDisplay.snackBar(
            context: context,
            message: _controller.error ?? 'Error al eliminar. Puede tener dependencias asociadas.',
            title: 'Error',
          );
        }
      }
    }
  }

  Color _cardColor(BuildContext context) => Theme.of(context).cardTheme.color ?? Colors.white;
}
