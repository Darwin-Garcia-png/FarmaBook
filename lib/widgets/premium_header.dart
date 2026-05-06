import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/notificaciones_controller.dart';
import '../theme/app_theme.dart';

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
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: SafeArea(
          bottom: false,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.8),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withOpacity(0.05),
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
                    color: baseColor.withOpacity(0.1),
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
                              ?.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                const SizedBox(width: 8),
                Consumer<NotificacionesController>(
                  builder: (context, notifCtrl, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            notifCtrl.unreadCount > 0
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_none_outlined,
                            color: baseColor,
                            size: 22,
                          ),
                          onPressed: () {
                            notifCtrl.markAllAsRead();
                            context.push('/alertas');
                          },
                        ),
                        if (notifCtrl.unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppTheme.reiOrangeRed,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 14, minHeight: 14),
                              child: Text(
                                '${notifCtrl.unreadCount}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold),
                                textAlign: textAlignCenter(),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
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
      ),
    );
  }

  TextAlign textAlignCenter() => TextAlign.center;
}
