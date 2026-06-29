import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';

enum NotificationType { success, error, warning, info }

class NotificationService extends ChangeNotifier {
  final List<_NotificationData> _items = [];

  List<_NotificationData> get items => _items;

  void success(String message, {String? title}) {
    _add(NotificationType.success, title ?? 'Éxito', message);
  }

  void error(String message, {String? title}) {
    _add(NotificationType.error, title ?? 'Error', message);
  }

  void warning(String message, {String? title}) {
    _add(NotificationType.warning, title ?? 'Advertencia', message);
  }

  void info(String message, {String? title}) {
    _add(NotificationType.info, title ?? 'Información', message);
  }

  void _add(NotificationType type, String title, String message) {
    _items.insert(0, _NotificationData(type: type, title: title, message: message));
    notifyListeners();
  }

  void remove(String id) {
    _items.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}

class _NotificationData {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  _NotificationData({required this.type, required this.title, required this.message})
      : id = DateTime.now().microsecondsSinceEpoch.toString() +
            (++_counter).toString();
  static int _counter = 0;
}

class NotificationOverlay extends StatefulWidget {
  final Widget child;
  const NotificationOverlay({required this.child, super.key});

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: false,
            child: Consumer<NotificationService>(
              builder: (context, service, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: service.items.map((n) {
                    return _NotificationCard(
                      key: ValueKey(n.id),
                      data: n,
                      onDismiss: () => service.remove(n.id),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final _NotificationData data;
  final VoidCallback onDismiss;
  const _NotificationCard({required this.data, required this.onDismiss, super.key});

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 5), _startExit);
  }

  void _startExit() {
    if (_exiting || !mounted) return;
    _exiting = true;
    _ctrl.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  void _dismissNow() {
    if (_exiting) return;
    _exiting = true;
    _ctrl.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.data.type) {
      case NotificationType.success: return const Color(0xFF22C55E);
      case NotificationType.error: return const Color(0xFFEF4444);
      case NotificationType.warning: return const Color(0xFFF59E0B);
      case NotificationType.info: return const Color(0xFF3B82F6);
    }
  }

  IconData get _icon {
    switch (widget.data.type) {
      case NotificationType.success: return Icons.check_circle_rounded;
      case NotificationType.error: return Icons.cancel_rounded;
      case NotificationType.warning: return Icons.warning_amber_rounded;
      case NotificationType.info: return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: 440,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: _color, width: 4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_icon, color: _color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.data.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade900,
                            decoration: TextDecoration.none,
                          )),
                      const SizedBox(height: 2),
                      Text(widget.data.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            decoration: TextDecoration.none,
                          )),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _dismissNow,
                  child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
