import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../router/app_router.dart';

class NotificationOverlayService {
  static final NotificationOverlayService _instance = NotificationOverlayService._internal();
  factory NotificationOverlayService() => _instance;
  NotificationOverlayService._internal();

  final List<_ActiveNotification> _activeNotifications = [];

  void showNotification(String title, String message, {bool isUrgent = true, VoidCallback? onTap}) {
    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    late OverlayEntry entry;
    final notificationId = DateTime.now().millisecondsSinceEpoch.toString();

    entry = OverlayEntry(
      builder: (context) => _StackableNotification(
        id: notificationId,
        title: title,
        message: message,
        isUrgent: isUrgent,
        index: _activeNotifications.indexWhere((n) => n.id == notificationId),
        onClose: () => _removeNotification(notificationId),
        onTap: onTap,
      ),
    );

    _activeNotifications.add(_ActiveNotification(id: notificationId, entry: entry));
    overlayState.insert(entry);

    // Auto-hide after 5 seconds
    Timer(const Duration(seconds: 5), () {
      _removeNotification(notificationId);
    });
  }

  void _removeNotification(String id) {
    final index = _activeNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final notification = _activeNotifications[index];
      notification.entry.remove();
      _activeNotifications.removeAt(index);
      
      // Re-build all remaining ones to update their positions
      for (var n in _activeNotifications) {
        n.entry.markNeedsBuild();
      }
    }
  }
}

class _ActiveNotification {
  final String id;
  final OverlayEntry entry;
  _ActiveNotification({required this.id, required this.entry});
}

class _StackableNotification extends StatefulWidget {
  final String id;
  final String title;
  final String message;
  final bool isUrgent;
  final int index;
  final VoidCallback onClose;
  final VoidCallback? onTap;

  const _StackableNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isUrgent,
    required this.index,
    required this.onClose,
    this.onTap,
  });

  @override
  State<_StackableNotification> createState() => _StackableNotificationState();
}

class _StackableNotificationState extends State<_StackableNotification> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The index might have changed in the parent list, so we recalculate top position
    final currentIdx = NotificationOverlayService()._activeNotifications.indexWhere((n) => n.id == widget.id);
    if (currentIdx == -1) return const SizedBox.shrink();

    final double topPosition = 20.0 + (currentIdx * 100.0);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: topPosition,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {
            widget.onClose();
            if (widget.onTap != null) {
              widget.onTap!();
            } else {
              navigatorKey.currentContext?.push('/alertas');
            }
          },
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: _WhatsAppStyleCard(
                title: widget.title,
                message: widget.message,
                isUrgent: widget.isUrgent,
                onClose: widget.onClose,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WhatsAppStyleCard extends StatelessWidget {
  final String title;
  final String message;
  final bool isUrgent;
  final VoidCallback onClose;

  const _WhatsAppStyleCard({
    required this.title,
    required this.message,
    required this.isUrgent,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Stock Bajo -> Purple, Vencimiento -> Blue (if not urgent)
    final accentColor = isUrgent ? AppTheme.reiPurple : AppTheme.ayanamiBlue;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Urgent / Info strip
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isUrgent ? Icons.inventory_2_rounded : Icons.notifications_active_rounded,
                              size: 18,
                              color: accentColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: accentColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: onClose,
                              child: Icon(Icons.close_rounded, size: 16, color: Colors.grey.withOpacity(0.8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.darkSlate,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
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
