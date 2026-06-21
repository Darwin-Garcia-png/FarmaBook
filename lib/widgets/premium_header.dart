import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/notificaciones_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../utils/global_error_handler.dart';
import '../utils/user_session.dart';

class PremiumHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color baseColor;
  final Widget? trailing;
  final Widget? leading;

  const PremiumHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.baseColor,
    this.trailing,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).cardTheme.color ?? Colors.white;

    return ClipRRect(
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 16),
              ] else ...[
                IconButton(
                  icon: Icon(Icons.menu_rounded, color: baseColor, size: 24),
                  onPressed: () {
                    ScaffoldState? scaffold = Scaffold.maybeOf(context);
                    while (scaffold != null && !scaffold.hasDrawer) {
                      scaffold = scaffold.context
                          .findAncestorStateOfType<ScaffoldState>();
                    }
                    scaffold?.openDrawer();
                  },
                ),
                const SizedBox(width: 12),
              ],
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: baseColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.color
                            ?.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              const SizedBox(width: 8),
              _NotifBell(baseColor: baseColor),
              IconButton(
                icon:
                    Icon(Icons.settings_outlined, color: baseColor, size: 22),
                onPressed: () => context.push('/configuracion'),
              ),
              const SizedBox(width: 12),
              Container(
                height: 40,
                width: 3,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  static void _showToast(NotificacionesController ctrl) {
    final msg = ctrl.toastMessage;
    if (msg == null) return;
    ctrl.markToastShown();
    final state = globalScaffoldMessengerKey.currentState;
    if (state == null) return;
    state.showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
        ]),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: AppTheme.ayanamiBlue,
      ),
    );
  }
}

class _NotifBell extends StatefulWidget {
  final Color baseColor;
  const _NotifBell({required this.baseColor});
  @override
  State<_NotifBell> createState() => _NotifBellState();
}

class _NotifBellState extends State<_NotifBell> with SingleTickerProviderStateMixin {
  NotificacionesController? _ctrl;
  int _lastCount = 0;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ctrl = context.read<NotificacionesController>();
    if (ctrl != _ctrl) {
      _ctrl?.removeListener(_onNotifChanged);
      _ctrl = ctrl;
      ctrl.addListener(_onNotifChanged);
    }
    if (ctrl.unreadCount > 0) _pulseCtrl.repeat(reverse: true);
  }

  void _onNotifChanged() {
    if (!mounted) return;
    final c = _ctrl;
    if (c == null) return;
    if (c.unreadCount > 0 && c.unreadCount != _lastCount) {
      _lastCount = c.unreadCount;
      _pulseCtrl.repeat(reverse: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PremiumHeader._showToast(c);
      });
    } else if (c.unreadCount == 0) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 1.0;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ctrl?.removeListener(_onNotifChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifCtrl = context.watch<NotificacionesController>();
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            notifCtrl.unreadCount > 0
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_outlined,
            color: widget.baseColor,
            size: 22,
          ),
          onPressed: () => _showDialog(context, notifCtrl),
        ),
        if (notifCtrl.unreadCount > 0)
          Positioned(
            right: 8, top: 6,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (ctx, child) => Transform.scale(
                scale: _pulseAnim.value,
                child: child,
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppTheme.reiOrangeRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.reiOrangeRed.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: Text(
                  '${notifCtrl.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showDialog(BuildContext context, NotificacionesController notifCtrl) {
    final list = List<Map<String, dynamic>>.from(notifCtrl.notificaciones);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 500,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(children: [
                const Icon(Icons.notifications_rounded, size: 22, color: AppTheme.ayanamiBlue),
                const SizedBox(width: 10),
                Text('Notificaciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                const Spacer(),
                if (list.isNotEmpty)
                  GestureDetector(
                    onTap: () { notifCtrl.markAllAsRead(); Navigator.pop(ctx); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.ayanamiBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.done_all_rounded, size: 12, color: AppTheme.ayanamiBlue),
                        const SizedBox(width: 4),
                        Text('Leídas', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.ayanamiBlue)),
                      ]),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty) _buildEmptyState(isDark) else Flexible(child: _buildList(list, isDark, ctx)),
            _buildFooter(ctx, isDark),
          ]),
        ),
      ),
    ).then((_) => notifCtrl.markAllAsRead());
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.greenMetal.withValues(alpha: 0.1)),
          child: const Icon(Icons.check_circle_outline_rounded, size: 52, color: AppTheme.greenMetal),
        ),
        const SizedBox(height: 20),
        const Text('Todo al día', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Text('No hay notificaciones pendientes',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  void _navigateTo(BuildContext ctx, String tipo, String id) {
    Navigator.pop(ctx);
    final dash = context.read<DashboardController>();
    if (tipo == 'vencimiento' && UserSession.isDueno) {
      dash.onItemTapped(3); // Lotes — only for admin/dueño
    } else {
      dash.onItemTapped(1); // Almacén
    }
  }

  Widget _buildList(List<Map<String, dynamic>> list, bool isDark, BuildContext dialogCtx) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      shrinkWrap: true,
      itemCount: list.length,
      itemBuilder: (_, i) {
        final n = list[i];
        final tipo = n['tipo']?.toString() ?? '';
        final id = n['id']?.toString() ?? '';
        final isExpiry = tipo == 'vencimiento';
        return _NotifItem(
          index: i,
          isExpiry: isExpiry,
          mensaje: n['mensaje']?.toString() ?? '',
          isDark: isDark,
          tipo: tipo,
          itemId: id,
          onTap: () => _navigateTo(dialogCtx, tipo, id),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext ctx, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06))),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.ayanamiBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.close_rounded, size: 18),
            SizedBox(width: 6),
            Text('CERRAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ]),
        ),
      ),
    );
  }
}

class _NotifItem extends StatefulWidget {
  final int index;
  final bool isExpiry;
  final String mensaje;
  final bool isDark;
  final String tipo;
  final String itemId;
  final VoidCallback onTap;
  const _NotifItem({required this.index, required this.isExpiry, required this.mensaje, required this.isDark, required this.tipo, required this.itemId, required this.onTap});

  @override
  State<_NotifItem> createState() => _NotifItemState();
}

class _NotifItemState extends State<_NotifItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: 60 * widget.index), () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.isExpiry ? AppTheme.reiOrangeRed : const Color(0xFFED8936);
    final bgColor = color.withValues(alpha: 0.08);
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child) => Opacity(
        opacity: _anim.value,
        child: Transform.translate(
          offset: Offset(12 * (1 - _anim.value), 0),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.15)),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                    child: Icon(widget.isExpiry ? Icons.event_available_rounded : Icons.inventory_2_rounded, size: 18, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(5)),
                        child: Text(widget.isExpiry ? 'Vencimiento' : 'Stock bajo',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3)),
                      ),
                      const Spacer(),
                      Container(
                        width: 7, height: 7,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 3)]),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text(widget.mensaje, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.isDark ? Colors.grey.shade300 : Colors.black87, height: 1.3)),
                  ])),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
