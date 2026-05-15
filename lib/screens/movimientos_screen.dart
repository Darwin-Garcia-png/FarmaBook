import 'dart:ui';
import 'package:flutter/material.dart';
import '../controllers/movimientos_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_header.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  final MovimientosController _controller = MovimientosController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumHeader(
        title: 'Actividad de Auditoría',
        subtitle: 'Historial completo de operaciones y cambios',
        icon: Icons.history_rounded,
        baseColor: AppTheme.ayanamiBlue,
        trailing: const SizedBox.shrink(),
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _controller.error != null
              ? _buildErrorState()
              : _buildList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.reiOrangeRed.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.reiOrangeRed.withOpacity(0.2))
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security_update_warning_rounded, color: AppTheme.reiOrangeRed, size: 70),
            const SizedBox(height: 24),
            Text(_controller.error!, style: const TextStyle(color: AppTheme.reiOrangeRed, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar Reconexión'),
              onPressed: () => _controller.init(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.ayanamiBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              )
            )
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(48, 40, 48, 20),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Text('LÍNEA DE TIEMPO', 
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
                const SizedBox(width: 16),
                Expanded(child: Divider(color: Colors.grey.withOpacity(0.1))),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _controller.movimientos[index];
                return _ActivityTimelineTile(
                  item: item,
                  isFirst: index == 0,
                  isLast: index == _controller.movimientos.length - 1,
                );
              },
              childCount: _controller.movimientos.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 50), sliver: SliverToBoxAdapter()),
      ],
    );
  }
}

class _ActivityTimelineTile extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isFirst;
  final bool isLast;

  const _ActivityTimelineTile({required this.item, required this.isFirst, required this.isLast});

  @override
  State<_ActivityTimelineTile> createState() => _ActivityTimelineTileState();
}

class _ActivityTimelineTileState extends State<_ActivityTimelineTile> {
  bool _isHovered = false;

  void _showDetails(BuildContext context) {
    if (widget.item['payload'] == null || widget.item['payload'] is! Map) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 600,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color?.withOpacity(0.95),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(_getIcon(), color: _getColor(), size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DETALLES DEL REGISTRO', 
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1.5)
                            ),
                            Text('${widget.item['accion']?.toString().toUpperCase()} - ${widget.item['entidad']?.toString().toUpperCase()}', 
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)
                            ),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(32),
                    children: _buildPayloadCards(widget.item['payload'] as Map<String, dynamic>, context),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPayloadCards(Map<String, dynamic> payload, BuildContext context) {
    return payload.entries.map((e) {
      final key = _formatKey(e.key);
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(key.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _buildValueWidget(e.value, context),
          ],
        ),
      );
    }).toList();
  }

  String _formatKey(String key) {
    if (key.isEmpty) return key;
    final text = key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}');
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildValueWidget(dynamic value, BuildContext context) {
    if (value is Map) {
      return Text(value.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
    }
    if (value is List) {
      if (value.isEmpty) return const Text('Sin registros', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: value.map((e) {
          if (e is Map) {
            final nombre = e['nombre'] ?? e['producto'] ?? e['id'] ?? 'Elemento';
            final cant = e['cantidadDeUnidades'] ?? e['cantidad'] ?? '';
            final sub = e['subTotal'] ?? '';
            return Container(
              margin: const EdgeInsets.only(top: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(nombre.toString(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
                  if (cant.toString().isNotEmpty) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.ayanamiBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('x$cant', style: const TextStyle(color: AppTheme.ayanamiBlue, fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                  if (sub.toString().isNotEmpty) Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Text('\$$sub', style: const TextStyle(color: AppTheme.greenMetal, fontWeight: FontWeight.w900, fontSize: 16)),
                  )
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                const Icon(Icons.arrow_right_rounded, color: AppTheme.ayanamiBlue),
                const SizedBox(width: 8),
                Expanded(child: Text(e.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
              ],
            ),
          );
        }).toList(),
      );
    }
    final text = value?.toString() ?? 'N/A';
    return Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5));
  }

  Color _getColor() {
    final accion = widget.item['accion']?.toString().toLowerCase() ?? '';
    switch (accion) {
      case 'venta': return AppTheme.greenMetal;
      case 'crear': return AppTheme.ayanamiBlue;
      case 'eliminar': return AppTheme.reiOrangeRed;
      case 'modificar': return Colors.amber.shade700;
      default: return Colors.grey;
    }
  }

  IconData _getIcon() {
    final accion = widget.item['accion']?.toString().toLowerCase() ?? '';
    switch (accion) {
      case 'venta': return Icons.point_of_sale_rounded;
      case 'crear': return Icons.add_circle_rounded;
      case 'eliminar': return Icons.delete_rounded;
      case 'modificar': return Icons.edit_rounded;
      default: return Icons.info_outline;
    }
  }

  String _getVerb() {
    final accion = widget.item['accion']?.toString().toLowerCase() ?? '';
    switch (accion) {
      case 'venta': return 'completó una venta de';
      case 'crear': return 'registró un nuevo';
      case 'eliminar': return 'eliminó un registro de';
      case 'modificar': return 'actualizó información de';
      default: return 'realizó una acción en';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final icon = _getIcon();
    final verb = _getVerb();
    final entidad = widget.item['entidad']?.toString().toLowerCase() ?? '';
    final nombreUsuario = widget.item['nombreUsuario'] ?? 'Usuario Desconocido';
    final payload = widget.item['payload'] is Map ? widget.item['payload'] as Map : {};
    
    final createdAtStr = widget.item['created_at']?.toString() ?? '';
    String timeAgo = 'Justo ahora';
    
    try {
       final dt = DateTime.parse(createdAtStr).toLocal();
       final diff = DateTime.now().difference(dt);
       if (diff.inSeconds < 60) timeAgo = 'Justo ahora';
       else if (diff.inMinutes < 60) timeAgo = 'Hace ${diff.inMinutes} min';
       else if (diff.inHours < 24) timeAgo = 'Hace ${diff.inHours} hrs';
       else timeAgo = 'Hace ${diff.inDays} días';
    } catch (_) {}

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(width: 2, height: 20, color: widget.isFirst ? Colors.transparent : Colors.grey.withOpacity(0.2)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                Expanded(child: Container(width: 2, color: widget.isLast ? Colors.transparent : Colors.grey.withOpacity(0.2))),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: GestureDetector(
                  onTap: () => _showDetails(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: _isHovered ? color.withOpacity(0.3) : Theme.of(context).dividerColor.withOpacity(0.1),
                        width: 1.5
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isHovered ? color.withOpacity(0.1) : Colors.black.withOpacity(0.02),
                          blurRadius: _isHovered ? 30 : 10,
                          offset: const Offset(0, 8),
                        )
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppTheme.ayanamiBlue.withOpacity(0.1),
                                  child: const Icon(Icons.person_rounded, size: 16, color: AppTheme.ayanamiBlue),
                                ),
                                const SizedBox(width: 10),
                                Text(nombreUsuario, 
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: -0.2)
                                ),
                              ],
                            ),
                            Text(timeAgo, 
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade500)
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.4,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                            children: [
                              TextSpan(text: verb, style: const TextStyle(fontWeight: FontWeight.w500)),
                              TextSpan(text: ' ${entidad.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                        if (payload.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.data_exploration_rounded, size: 18, color: color),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Audit ID: ${widget.item['cambioId']?.toString().substring(0,8) ?? "..."}',
                                     style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color.withOpacity(0.5)),
                              ],
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
