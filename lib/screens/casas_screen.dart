import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/casas_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/error_display.dart';
import '../widgets/shimmer_loading.dart';
import '../services/api_service.dart';
import '../widgets/animations.dart';
import 'package:flutter/services.dart';
import '../controllers/dashboard_controller.dart';

class CasasScreen extends StatefulWidget {
  const CasasScreen({super.key});

  @override
  State<CasasScreen> createState() => _CasasScreenState();
}

class _CasasScreenState extends State<CasasScreen> {
  final CasasController _controller = CasasController();
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

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return _controller.casas.cast<Map<String, dynamic>>();
    return _controller.casas.cast<Map<String, dynamic>>().where((c) {
      return (c['nombre'] ?? '').toString().toLowerCase().contains(q) ||
             (c['paisDeOrigen'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _showHouseDetail(Map<String, dynamic> casa) async {
    final houseId = casa['casaId']?.toString() ?? '';
    if (houseId.isEmpty) return;

    List<dynamic> suppliers = [];
    List<dynamic> products = [];
    bool loading = true;
    String? error;

    try {
      final results = await Future.wait([
        ApiService.getHouseSuppliers(houseId),
        ApiService.getHouseProducts(houseId),
      ]);
      suppliers = results[0];
      products = results[1];
    } catch (e) {
      error = 'Error al cargar detalles';
    } finally {
      loading = false;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Theme.of(context).cardTheme.color,
        child: Container(
          width: 600,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.ayanamiBlue, AppTheme.ayanamiBlue.withValues(alpha: 0.8)]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.business_rounded, color: Colors.white, size: 28)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(casa['nombre'] ?? 'Casa', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                    Text(casa['paisDeOrigen']?.isEmpty ?? true ? 'País no especificado' : casa['paisDeOrigen'],
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  ])),
                  IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                ]),
              ),
              Flexible(
                child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                    ? Center(child: Text(error, style: const TextStyle(color: AppTheme.reiOrangeRed)))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('PROVEEDORES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          if (suppliers.isEmpty)
                            const Text('Sin proveedores asociados', style: TextStyle(color: Colors.grey, fontSize: 13))
                          else
                            ...suppliers.map((s) => Container(
                              width: double.infinity, margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppTheme.reiPurple.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.reiPurple.withValues(alpha: 0.1))),
                              child: Row(children: [
                                Icon(Icons.local_shipping_rounded, size: 16, color: AppTheme.reiPurple),
                                const SizedBox(width: 8),
                                Expanded(child: Text(s['nombre'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                              ]),
                            )),
                          const SizedBox(height: 24),
                          const Text('PRODUCTOS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          if (products.isEmpty)
                            const Text('Sin productos asociados', style: TextStyle(color: Colors.grey, fontSize: 13))
                          else
                            ...products.map((p) => Container(
                              width: double.infinity, margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppTheme.ayanamiBlue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.ayanamiBlue.withValues(alpha: 0.1))),
                              child: Row(children: [
                                Icon(Icons.medication_rounded, size: 16, color: AppTheme.ayanamiBlue),
                                const SizedBox(width: 8),
                                Expanded(child: Text(p['nombre'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                              ]),
                            )),
                        ]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? casa}) async {
    final isEdit = casa != null;
    final formKey = GlobalKey<FormState>();

    if (isEdit) {
      _controller.nombreCtrl.text = casa['nombre'] ?? '';
      _controller.paisCtrl.text = casa['paisDeOrigen'] ?? '';
    } else {
      _controller.nombreCtrl.clear();
      _controller.paisCtrl.clear();
    }

    final _nombreFocus = FocusNode();
    final _paisFocus = FocusNode();

    void _saveAndPop(BuildContext ctx) async {
      if (!formKey.currentState!.validate()) return;
      bool success;
      if (isEdit) {
        success = await _controller.actualizarCasa(casa['casaId']);
      } else {
        success = await _controller.agregarCasa();
      }
      if (mounted) {
        Navigator.pop(ctx);
        if (success) {
          ErrorDisplay.successSnackBar(context: context, message: isEdit ? 'Casa actualizada' : 'Casa registrada');
        } else {
          ErrorDisplay.snackBar(context: context, message: 'Error');
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
                            colors: [AppTheme.ayanamiBlue, AppTheme.ayanamiBlue.withValues(alpha: 0.85)],
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
                              child: Icon(isEdit ? Icons.edit_rounded : Icons.business_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isEdit ? 'Editar Casa' : 'Nueva Casa',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                                  Text(isEdit ? 'Modifica los datos de la casa' : 'Registra una casa farmacéutica',
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
                            _buildField('Nombre de la Casa', _controller.nombreCtrl, Icons.business_rounded, req: true, focusNode: _nombreFocus, textInputAction: TextInputAction.next, onFieldSubmitted: (_) => FocusScope.of(ctx).requestFocus(_paisFocus)),
                            _buildField('País de Origen *', _controller.paisCtrl, Icons.public_rounded, req: true, focusNode: _paisFocus, textInputAction: TextInputAction.done, onFieldSubmitted: (_) => _saveAndPop(ctx)),
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
                                gradient: const LinearGradient(
                                  colors: [AppTheme.ayanamiBlue, Color(0xFF4A8BC4)],
                                  begin: Alignment.centerLeft, end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: AppTheme.ayanamiBlue.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
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
                                child: Text(isEdit ? 'Guardar Cambios' : 'Registrar Casa',
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
      _paisFocus.dispose();
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> casa) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Eliminar Casa', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('¿Deseas eliminar "${casa['nombre']}"? Esta acción no se puede deshacer.'),
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
      final success = await _controller.eliminarCasa(casa['casaId']);
      if (mounted) {
        if (success) {
          ErrorDisplay.successSnackBar(context: context, message: 'Casa eliminada');
        } else {
          ErrorDisplay.snackBar(context: context, message: 'Error al eliminar');
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
          prefixIcon: Icon(icon, color: AppTheme.ayanamiBlue),
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
    final accent = AppTheme.ayanamiBlue;

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
            onRetry: _controller.cargarCasas,
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
        Positioned(top: 0, left: 0, right: 0, child: _buildHeader(bg, text, accent)),
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
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.business_rounded, color: AppTheme.ayanamiBlue, size: 24),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('CASAS', style: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          Text('Gestiona las casas farmacéuticas', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  Widget _buildSearchBar(Color accent, Color bg, Color text) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Buscar casas...',
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
      decoration: BoxDecoration(color: cardColor(context), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(children: [
        Icon(Icons.business_outlined, size: 64, color: accent.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text('No hay casas registradas', style: TextStyle(fontSize: 18, color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Agrega una nueva casa farmacéutica', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ]),
    );
  }

  Widget _buildCard(Map<String, dynamic> casa, Color accent, Color text, Color card) {
    return GestureDetector(
      onTap: () => _showHouseDetail(casa),
      child: Container(
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
              Text(casa['nombre'] ?? 'Sin nombre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: text), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.public_rounded, size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(casa['paisDeOrigen']?.isEmpty ?? true ? 'País no especificado' : casa['paisDeOrigen'],
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ]),
            ]),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _actionButton(Icons.edit_rounded, accent, () => _showAddEditDialog(casa: casa)),
            const SizedBox(width: 4),
            _actionButton(Icons.delete_rounded, AppTheme.reiOrangeRed, () => _confirmDelete(casa)),
          ],)
        ]),
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

  Color cardColor(BuildContext context) => Theme.of(context).cardTheme.color ?? Colors.white;
}
