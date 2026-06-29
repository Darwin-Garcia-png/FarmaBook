import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../router/app_router.dart';
import '../widgets/error_display.dart';

final GlobalKey<ScaffoldMessengerState> globalScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class GlobalErrorHandler {
  static OverlayEntry? _currentEntry;

  static void showError(String message, {int? statusCode}) {
    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    String title = 'Error';
    if (statusCode != null) {
      if (statusCode == 404) title = 'Recurso No Encontrado';
      else if (statusCode == 401 || statusCode == 403) title = 'Problema de Autenticación';
      else if (statusCode >= 500) title = 'Error del Servidor';
      else title = 'Error HTTP $statusCode';
    }

    _currentEntry?.remove();
    _currentEntry = null;

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: _AnimatedErrorCard(title: title, message: message),
        ),
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);

    Timer(const Duration(seconds: 5), () {
      if (_currentEntry == entry) {
        _currentEntry?.remove();
        _currentEntry = null;
      }
    });
  }
}

class _AnimatedErrorCard extends StatefulWidget {
  final String title;
  final String message;
  const _AnimatedErrorCard({required this.title, required this.message});

  @override
  State<_AnimatedErrorCard> createState() => _AnimatedErrorCardState();
}

class _AnimatedErrorCardState extends State<_AnimatedErrorCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(begin: const Offset(0.0, -1.0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutExpo));
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.reiOrangeRed,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppTheme.reiOrangeRed.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(widget.message, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
