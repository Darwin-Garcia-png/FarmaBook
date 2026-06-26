import 'package:flutter/material.dart';
import '../controllers/categorias_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/error_display.dart';
import '../widgets/shimmer_loading.dart';
import 'package:flutter/services.dart';
import '../widgets/animations.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final CategoriasController _controller = CategoriasController();
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

  Color get _accent => const Color(0xFF8B5CF6);

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return _controller.categorias.cast<Map<String, dynamic>>();
    return _controller.categorias.cast<Map<String, dynamic>>().where((c) {
      return (c['nombre'] ?? '').toString().toLowerCase().contains(q) ||
             (c['descripcion'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? cat}) async {
    final isEdit = cat != null;
    final formKey = GlobalKey<FormState>();
    
    if (isEdit) {
      _controller.nombreCtrl.text = cat['nombre'] ?? '';
      _controller.descripcionCtrl.text = cat['descripcion'] ?? '';
    } else {
      _controller.nombreCtrl.clear();
      _controller.descripcionCtrl.clear();
    }

    final _nombreFocus = FocusNode();
    final _descFocus = FocusNode();

    void _saveAndPop(BuildContext ctx) async {
      if (!formKey.currentState!.validate()) return;
      bool success;
      if (isEdit) {
        success = await _controller.actualizarCategoria(cat['categoriaId']);
      } else {
        success = await _controller.agregarCategoria();
      }
      if (mounted) {
        Navigator.pop(ctx);
        if (success) {
          ErrorDisplay.successSnackBar(context: context, message: isEdit ? 'Categoría actualizada' : 'Categoría registrada');
        } else {
          ErrorDisplay.snackBar(context: context, message: 'Error', hint: 'Revisa los datos e intenta de nuevo.');
        }
      }
    }

    try {
      await showGeneralDialog(
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
              width: 520,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 12)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(28, 24, 20, 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_accent, _accent.withValues(alpha: 0.85)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(isEdit ? Icons.edit_rounded : Icons.category_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isEdit ? 'Editar Categoría' : 'Nueva Categoría',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                                  Text(isEdit ? 'Modifica los datos de la categoría' : 'Registra una nueva clasificación',
                                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildField('Nombre de la Categoría', _controller.nombreCtrl, Icons.category_rounded, req: true, focusNode: _nombreFocus, textInputAction: TextInputAction.next, onFieldSubmitted: (_) => FocusScope.of(ctx).requestFocus(_descFocus)),
                            _buildField('Descripción (Opcional)', _controller.descripcionCtrl, Icons.description_rounded, maxLines: 3, focusNode: _descFocus, textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _saveAndPop(ctx)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 12),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_accent, const Color(0xFF7C3AED)],
                                  begin: Alignment.centerLeft, end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                ),
                                onPressed: () => _saveAndPop(ctx),
                                child: Text(isEdit ? 'Guardar Cambios' : 'Registrar Categoría',
                                    style: const TextStyle(fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } finally {
      _nombreFocus.dispose();
      _descFocus.dispose();
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Eliminar Categoría', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('¿Deseas eliminar "${cat['nombre']}"? Esta acción no se puede deshacer.'),
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
      final success = await _controller.eliminarCategoria(cat['categoriaId']);
      if (mounted) {
        if (success) {
          ErrorDisplay.successSnackBar(context: context, message: 'Categoría eliminada');
        } else {
          ErrorDisplay.snackBar(context: context, message: 'Error al eliminar', hint: 'Es posible que la categoría tenga productos asociados.');
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
           if (label.toLowerCase().contains('nombre')) FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
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
            message: _controller.error!,
            onRetry: _controller.cargarCategorias,
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
              ...list.asMap().entries.map((entry) => AnimatedEntry(
                index: entry.key,
                child: _AnimatedCatCard(
                  key: ValueKey(entry.value['categoriaId']),
                  index: entry.key,
                  cat: entry.value,
                  accent: accent,
                  text: text,
                  card: card,
                  onEdit: () => _showAddEditDialog(cat: entry.value),
                  onDelete: () => _confirmDelete(entry.value),
                ),
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
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.08))),
      ),
      child: Row(children: [
        IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: text),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.category_rounded, color: Color(0xFF8B5CF6), size: 24),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('CATEGORÍAS', style: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          Text('Gestiona las clasificaciones', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
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
          hintText: 'Buscar categorías...',
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
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.1),
          ),
          child: Icon(Icons.category_outlined, size: 48, color: accent.withValues(alpha: 0.4)),
        ),
        const SizedBox(height: 20),
        Text('No hay categorías', style: TextStyle(fontSize: 18, color: Colors.grey.shade500, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        Text('Agrega una nueva categoría con el botón +',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
      ]),
    );
  }

  Color _cardColor(BuildContext context) => Theme.of(context).cardTheme.color ?? Colors.white;
}

class _AnimatedCatCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> cat;
  final Color accent, text, card;
  final VoidCallback onEdit, onDelete;
  const _AnimatedCatCard({
    super.key,
    required this.index,
    required this.cat,
    required this.accent,
    required this.text,
    required this.card,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_AnimatedCatCard> createState() => _AnimatedCatCardState();
}

class _AnimatedCatCardState extends State<_AnimatedCatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 60 * widget.index), _animCtrl.forward);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    final accent = widget.accent;
    final text = widget.text;
    final card = widget.card;
    final gradient = LinearGradient(
      colors: [accent.withValues(alpha: 0.12), accent.withValues(alpha: 0.04)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: accent.withValues(alpha: 0.5), width: 3)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.category_rounded, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cat['nombre'] ?? 'Sin nombre',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: text),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.description_outlined, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        cat['descripcion']?.isEmpty ?? true ? 'Sin descripción' : cat['descripcion'],
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ]),
              ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _actionButton(Icons.edit_rounded, accent, widget.onEdit),
                const SizedBox(width: 4),
                _actionButton(Icons.delete_rounded, AppTheme.reiOrangeRed, widget.onDelete),
              ],)
            ]),
          ),
        ),
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
}
