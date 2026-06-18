import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../controllers/notificaciones_controller.dart';
import '../utils/global_error_handler.dart';

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

class _NotifBellState extends State<_NotifBell> {
  NotificacionesController? _ctrl;
  int _lastCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ctrl = context.read<NotificacionesController>();
    if (ctrl != _ctrl) {
      _ctrl?.removeListener(_onNotifChanged);
      _ctrl = ctrl;
      ctrl.addListener(_onNotifChanged);
    }
  }

  void _onNotifChanged() {
    if (!mounted) return;
    final c = _ctrl;
    if (c == null) return;
    if (c.unreadCount > 0 && c.unreadCount != _lastCount) {
      _lastCount = c.unreadCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PremiumHeader._showToast(c);
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
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
            right: 8, top: 8,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppTheme.reiOrangeRed,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(
                '${notifCtrl.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showDialog(BuildContext context, NotificacionesController notifCtrl) {
    final list = List<Map<String, dynamic>>.from(notifCtrl.notificaciones);
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: 460,
            constraints: const BoxConstraints(maxHeight: 520),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.ayanamiBlue.withValues(alpha: 0.12),
                        AppTheme.ayanamiBlue.withValues(alpha: 0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.ayanamiBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_rounded, color: AppTheme.ayanamiBlue, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text('Notificaciones',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const Spacer(),
                      if (list.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            notifCtrl.markAllAsRead();
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.ayanamiBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Marcar leídas',
                              style: TextStyle(fontSize: 12, color: AppTheme.ayanamiBlue, fontWeight: FontWeight.w700)),
                          ),
                        ),
                    ],
                  ),
                ),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 48, color: AppTheme.greenMetal),
                        SizedBox(height: 12),
                        Text('No hay notificaciones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text('Todo está en orden', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      shrinkWrap: true,
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 48),
                      itemBuilder: (_, i) {
                        final n = list[i];
                        final tipo = n['tipo']?.toString() ?? '';
                        final isExpiry = tipo == 'vencimiento';
                        final colors = isExpiry
                            ? const [AppTheme.reiOrangeRed, Color(0xFFD84315)]
                            : const [Colors.orange, Color(0xFFE65100)];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colors[0].withValues(alpha: 0.15),
                                      colors[1].withValues(alpha: 0.08),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isExpiry ? Icons.event_available_rounded : Icons.inventory_2_rounded,
                                  size: 18, color: colors[0],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isExpiry ? 'Vencimiento próximo' : 'Stock bajo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: colors[0],
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      n['mensaje']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors[0].withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isExpiry ? 'Urgente' : 'Alerta',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: colors[0]),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: AppTheme.ayanamiBlue.withValues(alpha: 0.3)),
                      ),
                      child: Text('CERRAR',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.ayanamiBlue.withValues(alpha: 0.8),
                        )),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) => notifCtrl.markAllAsRead());
  }
}
