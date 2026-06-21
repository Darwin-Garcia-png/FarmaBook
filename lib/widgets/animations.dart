import 'dart:math';
import 'package:flutter/material.dart';

// ──────────────────────────────────────────────
// ENTRANCE VARIANTS
// ──────────────────────────────────────────────

enum EntryStyle { fadeUp, fadeDown, fadeLeft, fadeRight, zoom, bounce }

/// Staggered entrance animation for list items
class AnimatedEntry extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final EntryStyle style;

  const AnimatedEntry({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 60),
    this.style = EntryStyle.fadeUp,
  });

  @override
  State<AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

    _fade = Tween<double>(begin: 0, end: 1).animate(curve);

    Offset begin;
    switch (widget.style) {
      case EntryStyle.fadeUp:
        begin = const Offset(0, 0.15);
      case EntryStyle.fadeDown:
        begin = const Offset(0, -0.15);
      case EntryStyle.fadeLeft:
        begin = const Offset(-0.15, 0);
      case EntryStyle.fadeRight:
        begin = const Offset(0.15, 0);
      case EntryStyle.zoom:
        begin = Offset.zero;
      case EntryStyle.bounce:
        begin = const Offset(0, 0.2);
    }
    _slide = Tween<Offset>(begin: begin, end: Offset.zero).animate(curve);

    _scale = widget.style == EntryStyle.zoom
        ? Tween<double>(begin: 0.85, end: 1).animate(curve)
        : Tween<double>(begin: 1, end: 1).animate(curve);

    Future.delayed(widget.delay * widget.index, _ctrl.forward);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: _slide.value * MediaQuery.of(context).size.height * 0.02,
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ──────────────────────────────────────────────
// STAGGERED LIST – applies AnimatedEntry to children
// ──────────────────────────────────────────────

class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final int startIndex;
  final Duration delay;
  final EdgeInsets? padding;
  final EntryStyle style;

  const StaggeredList({
    super.key,
    required this.children,
    this.startIndex = 0,
    this.delay = const Duration(milliseconds: 60),
    this.padding,
    this.style = EntryStyle.fadeUp,
  });

  @override
  Widget build(BuildContext context) {
    final list = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      list.add(AnimatedEntry(
        index: startIndex + i,
        delay: delay,
        style: style,
        child: children[i],
      ));
    }
    if (padding != null) {
      return Padding(padding: padding!, child: Column(children: list));
    }
    return Column(children: list);
  }
}

// ──────────────────────────────────────────────
// HOVER SCALE
// ──────────────────────────────────────────────

class HoverScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final double elevation;
  final Color? glowColor;

  const HoverScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 1.02,
    this.elevation = 6,
    this.glowColor,
  });

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? Theme.of(context).colorScheme.primary;
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
                        color: glow.withValues(alpha: _hovering ? 0.15 : 0),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
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

// ──────────────────────────────────────────────
// GLOW EFFECT – pulses a coloured glow beneath a child
// ──────────────────────────────────────────────

class GlowEffect extends StatefulWidget {
  final Widget child;
  final Color color;
  final double radius;
  final bool autoAnimate;

  const GlowEffect({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.radius = 8,
    this.autoAnimate = true,
  });

  @override
  State<GlowEffect> createState() => _GlowEffectState();
}

class _GlowEffectState extends State<GlowEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    if (widget.autoAnimate) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat(reverse: true);
      _pulse = Tween<double>(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(
                    alpha: widget.autoAnimate ? _pulse.value : 0.4),
                blurRadius: widget.radius * 2,
                spreadRadius: widget.radius,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ──────────────────────────────────────────────
// GLASSMORPHISM CONTAINER
// ──────────────────────────────────────────────

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tint;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 20,
    this.padding,
    this.margin,
    this.tint,
    this.width,
    this.height,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = tint ??
        (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.55));
    final border = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.7);

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: child,
    );
  }
}

// ──────────────────────────────────────────────
// COUNTER ANIMATION – animates a number from 0 → value
// ──────────────────────────────────────────────

class AnimatedCounter extends StatefulWidget {
  final double value;
  final String Function(double value) builder;
  final Duration duration;
  final Curve curve;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _display = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _ctrl, curve: widget.curve),
    );
    _ctrl.addListener(() => setState(() => _display = _anim.value));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _ctrl.reset();
      _anim = Tween<double>(begin: _display, end: widget.value).animate(
        CurvedAnimation(parent: _ctrl, curve: widget.curve),
      );
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(widget.builder(_display));
}

// ──────────────────────────────────────────────
// PARTICLES BACKGROUND
// ──────────────────────────────────────────────

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
