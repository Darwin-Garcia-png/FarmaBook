import 'dart:math';
import 'package:flutter/material.dart';

/// Staggered fade+slide entrance for list items
class AnimatedEntry extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const AnimatedEntry({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 60),
  });

  @override
  State<AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(widget.delay * widget.index, _ctrl.forward);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Scale on hover for cards / tappable containers
class HoverScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final double elevation;

  const HoverScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 1.02,
    this.elevation = 6,
  });

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovering ? widget.scale : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              boxShadow: _hovering
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: widget.elevation * 2,
                        offset: Offset(0, widget.elevation),
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Floating particles background
class ParticleBackground extends StatefulWidget {
  final Color color;
  final int particleCount;

  const ParticleBackground({
    super.key,
    this.color = Colors.white,
    this.particleCount = 20,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _particles = <_Particle>[];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: _rng.nextDouble() * 4 + 2,
        speedX: (_rng.nextDouble() - 0.5) * 0.003,
        speedY: (_rng.nextDouble() - 0.5) * 0.003 - 0.001,
        opacity: _rng.nextDouble() * 0.4 + 0.1,
      ));
    }
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _ctrl.addListener(() {
      for (final p in _particles) {
        p.x += p.speedX;
        p.y += p.speedY;
        if (p.x > 1) p.x = 0;
        if (p.x < 0) p.x = 1;
        if (p.y > 1) p.y = 0;
        if (p.y < 0) p.y = 1;
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlePainter(_particles, widget.color),
      size: Size.infinite,
    );
  }
}

class _Particle {
  double x, y, size, speedX, speedY, opacity;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  _ParticlePainter(this.particles, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = color.withValues(alpha: p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}


