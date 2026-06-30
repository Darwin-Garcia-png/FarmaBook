import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/presentaciones_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/error_display.dart';
import '../widgets/animations.dart';
import '../widgets/shimmer_loading.dart';
import 'package:flutter/services.dart';
import '../controllers/dashboard_controller.dart';

class PresentacionesScreen extends StatefulWidget {
  const PresentacionesScreen({super.key});

  @override
  State<PresentacionesScreen> createState() => _PresentacionesScreenState();
}

class _PresentacionesScreenState extends State<PresentacionesScreen> {
  final PresentacionesController _controller = PresentacionesController();
  final TextEditingController _searchCtrl = TextEditingController();

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
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Color get _accent => AppTheme.greenMetal;

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return _controller.presentaciones.cast<Map<String, dynamic>>();
    return _controller.presentaciones.cast<Map<String, dynamic>>().where((p) {
      return (p['nombre'] ?? '').toString().toLowerCase().contains(q) ||
             (p['descripcion'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? pres}) async {
    final isEdit = pres != null;
    final formKey = GlobalKey<FormState>();
    
    if (isEdit) {
      _controller.nombreCtrl.text = pres['nombre'] ?? '';
      _controller.descripcionCtrl.text = pres['descripcion'] ?? '';
    } else {
      _controller.nombreCtrl.clear();
      _controller.descripcionCtrl.clear();
    }

    final _nombreFocus = FocusNode();
    final _descFocus = FocusNode();

    void _saveAndPop(BuildContext diaCtx) async {
      if (!formKey.currentState!.validate()) return;
      bool success;
      if (isEdit) {
        success = await _controller.actualizarPresentacion(pres['presentacionId']);
      } else {
        success = await _controller.agregarPresentacion();
      }
      if (mounted) {
        if (success) {
          Navigator.pop(diaCtx);
          ErrorDisplay.successSnackBar(context: context, message: isEdit ? 'Presentación actualizada' : 'Presentación registrada');
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
      await showDialog(
        context: context,
        builder: (diaCtx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          backgroundColor: Theme.of(context).cardTheme.color,
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isEdit ? 'Editar Presentación' : 'Nueva Presentación',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(diaCtx)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildField('Nombre del Formato', _controller.nombreCtrl, Icons.local_pharmacy_rounded, req: true, focusNode: _nombreFocus, textInputAction: TextInputAction.next, onFieldSubmitted: (_) => FocusScope.of(diaCtx).requestFocus(_descFocus)),
                  _buildField('Descripción *', _controller.descripcionCtrl, Icons.description_rounded, maxLines: 3, req: true, focusNode: _descFocus, textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _saveAndPop(diaCtx)),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(diaCtx), child: const Text('Cancelar')),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () => _saveAndPop(diaCtx),
                        child: Text(isEdit ? 'Guardar Cambios' : 'Registrar Presentación', style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      _nombreFocus.dispose();
      _descFocus.dispose();
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> pres) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Eliminar Presentación', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('¿Deseas eliminar "${pres['nombre']}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.reiOrangeRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _controller.eliminarPresentacion(pres['presentacionId']);
      if (mounted) {
        if (success) {
          ErrorDisplay.successSnackBar(context: context, message: 'Presentación eliminada');
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

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {bool req = false, int maxLines = 1, TextInputType keyboard = TextInputType.text, FocusNode? focusNode, TextInputAction? textInputAction, ValueChanged<String>? onFieldSubmitted}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        focusNode: focusNode,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        maxLines: maxLines,
        keyboardType: keyboard,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        inputFormatters: [
           if (keyboard == TextInputType.number) FilteringTextInputFormatter.digitsOnly,
           if (label.toLowerCase().contains('nombre')) FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
        ],
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _accent),
          alignLabelWithHint: maxLines > 1,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.reiOrangeRed, width: 1)),
        ),
        validator: (v) {
          if (req && (v == null || v.trim().isEmpty)) return 'Este campo es obligatorio';
          if (label.toLowerCase().contains('nombre') && v != null && RegExp(r'[0-9]').hasMatch(v)) {
            return 'No se permiten números en el nombre';
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
            onRetry: _controller.cargarPresentaciones,
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
        Positioned(top: 0, left: 0, right: 0, child: AnimatedEntry(index: 0, child: _buildHeader(bg, text, accent))),
        Positioned(bottom: 24, right: 40,
          child: FloatingActionButton(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () => _showAddEditDialog(),
            child: const Icon(Icons.add_rounded, size: 28),
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
          child: const Icon(Icons.local_pharmacy_rounded, color: AppTheme.greenMetal, size: 24),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('PRESENTACIONES', style: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          Text('Formatos, empaques y envases', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
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
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Buscar presentaciones...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 18), onPressed: () { _searchCtrl.clear(); setState(() {}); })
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
        Icon(Icons.local_pharmacy_outlined, size: 64, color: accent.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text('No hay presentaciones registradas', style: TextStyle(fontSize: 18, color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Agrega una nueva presentación', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ]),
    );
  }

  Widget _buildCard(Map<String, dynamic> pres, Color accent, Color text, Color card) {
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
            child: Icon(Icons.local_pharmacy_rounded, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pres['nombre'] ?? 'Sin nombre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: text), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(pres['descripcion']?.isEmpty ?? true ? 'Sin descripción provista' : pres['descripcion'],
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _actionButton(Icons.edit_rounded, accent, () => _showAddEditDialog(pres: pres)),
            const SizedBox(width: 4),
            _actionButton(Icons.delete_rounded, AppTheme.reiOrangeRed, () => _confirmDelete(pres)),
          ],)
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
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Color _cardColor(BuildContext context) => Theme.of(context).cardTheme.color ?? Colors.white;
}
