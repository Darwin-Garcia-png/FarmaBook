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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
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
            width: 480,
            constraints: const BoxConstraints(maxHeight: 560),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(ctx, list, notifCtrl, isDark),
                  if (list.isEmpty)
                    _buildEmptyState(isDark)
                  else
                    Flexible(child: _buildList(ctx, list, notifCtrl, isDark)),
                  _buildFooter(ctx, isDark),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) => notifCtrl.markAllAsRead());
  }

  Widget _buildHeader(BuildContext ctx, List<Map<String, dynamic>> list,
      NotificacionesController notifCtrl, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1A2744),
                  const Color(0xFF2A4365),
                  const Color(0xFF1A2744),
                ]
              : [
                  const Color(0xFF6DABE4),
                  const Color(0xFF4A8BC4),
                  const Color(0xFF3A7BB4),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ayanamiBlue.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.notifications_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Notificaciones',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.3,
                )),
              const SizedBox(height: 2),
              Text(
                list.isEmpty
                    ? 'No hay pendientes'
                    : '${list.length} pendiente${list.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (list.isNotEmpty)
            GestureDetector(
              onTap: () {
                notifCtrl.markAllAsRead();
                Navigator.pop(ctx);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.done_all_rounded,
                        size: 14, color: Colors.white.withValues(alpha: 0.9)),
                    const SizedBox(width: 4),
                    Text('Leídas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                      )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.greenMetal.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                size: 48, color: AppTheme.greenMetal),
          ),
          const SizedBox(height: 20),
          const Text('Todo despejado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            )),
          const SizedBox(height: 6),
          Text('No hay notificaciones pendientes',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            )),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext ctx, List<Map<String, dynamic>> list,
      NotificacionesController notifCtrl, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      shrinkWrap: true,
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final n = list[i];
        final tipo = n['tipo']?.toString() ?? '';
        final isExpiry = tipo == 'vencimiento';
        return _NotifCard(
          isExpiry: isExpiry,
          mensaje: n['mensaje']?.toString() ?? '',
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildFooter(BuildContext ctx, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF2A4365), const Color(0xFF1A2744)]
                  : [const Color(0xFF6DABE4), const Color(0xFF4A8BC4)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.ayanamiBlue.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(ctx),
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text('CERRAR',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final bool isExpiry;
  final String mensaje;
  final bool isDark;
  const _NotifCard({
    required this.isExpiry,
    required this.mensaje,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpiry ? AppTheme.reiOrangeRed : const Color(0xFFED8936);
    final bgColor = color.withValues(alpha: 0.08);
    final borderColor = color.withValues(alpha: 0.2);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isExpiry
                        ? Icons.event_available_rounded
                        : Icons.inventory_2_rounded,
                    size: 20,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isExpiry ? 'Vencimiento' : 'Stock bajo',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: color,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isExpiry ? 'Urgente' : 'Alerta',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mensaje,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade300 : Colors.black87,
                          height: 1.3,
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
  }
}
