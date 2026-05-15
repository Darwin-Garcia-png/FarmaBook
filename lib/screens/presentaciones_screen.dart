import 'package:flutter/material.dart';
import '../controllers/presentaciones_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_header.dart';
import 'package:flutter/services.dart';

class PresentacionesScreen extends StatefulWidget {
  const PresentacionesScreen({super.key});

  @override
  State<PresentacionesScreen> createState() => _PresentacionesScreenState();
}

class _PresentacionesScreenState extends State<PresentacionesScreen> {
  final PresentacionesController _controller = PresentacionesController();

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

    showDialog(
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
                _buildField('Nombre del Formato', _controller.nombreCtrl, Icons.local_pharmacy_rounded, req: true),
                _buildField('Descripción (Opcional)', _controller.descripcionCtrl, Icons.description_rounded, maxLines: 3),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(diaCtx), child: const Text('Cancelar')),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.ayanamiBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        bool success;
                        if (isEdit) {
                          success = await _controller.actualizarPresentacion(pres['presentacionId']);
                        } else {
                          success = await _controller.agregarPresentacion();
                        }
                        
                        if (mounted) {
                          Navigator.pop(diaCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? (isEdit ? 'Presentación actualizada' : 'Presentación registrada') : 'Error en la operación'),
                              backgroundColor: success ? AppTheme.greenMetal : AppTheme.reiOrangeRed,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Presentación eliminada' : 'Error al eliminar'),
            backgroundColor: success ? AppTheme.greenMetal : AppTheme.reiOrangeRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {bool req = false, int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
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
          fillColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumHeader(
        title: 'Presentaciones',
        subtitle: 'Formatos, empaques y envases',
        icon: Icons.local_pharmacy_rounded,
        baseColor: AppTheme.ayanamiBlue,
        trailing: ElevatedButton.icon(
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nueva Presentación', style: TextStyle(fontWeight: FontWeight.w900)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.ayanamiBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: AppTheme.ayanamiBlue.withOpacity(0.4),
          ),
          onPressed: () => _showAddEditDialog(),
        ),
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCategoryGrid(),
    );
  }

  Widget _buildCategoryGrid() {
    if (_controller.error != null) {
      return Center(child: Text(_controller.error!, style: const TextStyle(color: AppTheme.reiOrangeRed)));
    }
    
    if (_controller.presentaciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_pharmacy_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('No hay presentaciones registradas', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(32),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 210,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: _controller.presentaciones.length,
      itemBuilder: (context, i) {
        final pres = _controller.presentaciones[i];
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.ayanamiBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.local_pharmacy_rounded, color: AppTheme.ayanamiBlue, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(pres['nombre'] ?? 'Sin nombre',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  pres['descripcion']?.isEmpty ?? true ? 'Sin descripción provista' : pres['descripcion'],
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _actionButton(Icons.edit_rounded, AppTheme.ayanamiBlue, () => _showAddEditDialog(pres: pres)),
                    const SizedBox(width: 8),
                    _actionButton(Icons.delete_rounded, AppTheme.reiOrangeRed, () => _confirmDelete(pres)),
                  ],
                )
              ],
            ),
          ),
        );
      },
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
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}