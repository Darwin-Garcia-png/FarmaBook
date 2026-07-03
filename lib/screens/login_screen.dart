import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../controllers/login_controller.dart';
import '../controllers/recovery_controller.dart';
import '../controllers/almacen_controller.dart';
import '../controllers/lotes_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/error_display.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final LoginController _controller = LoginController();
  late AnimationController _bgCtrl;
  late Animation<double> _bgAnim;
  late List<_FloatingIcon> _icons;

  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOutSine),
    );

    _icons = List.generate(6, (i) {
      return _FloatingIcon(
        icon: [Icons.medication_rounded, Icons.healing_rounded, Icons.biotech_rounded,
                Icons.science_rounded, Icons.health_and_safety_rounded, Icons.coronavirus_rounded][i],
        x: _rng.nextDouble() * 0.8 + 0.1,
        y: _rng.nextDouble() * 0.8 + 0.1,
        size: _rng.nextDouble() * 20 + 16,
        speed: _rng.nextDouble() * 0.002 + 0.001,
        opacity: _rng.nextDouble() * 0.12 + 0.04,
        phase: _rng.nextDouble() * 2 * pi,
      );
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleLogin() async {
    final success = await _controller.login();
    if (success && mounted) {
      try {
        await Future.wait([
          context.read<AlmacenController>().init(),
          context.read<LotesController>().init(),
        ]);
        if (mounted) context.go('/dashboard');
      } catch (e) {
        if (mounted) {
          ErrorDisplay.dialog(context: context, message: ErrorDisplay.cleanMessage(e), title: 'Error al cargar datos');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background con partículas
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(_bgAnim.value * 0.2, -1),
                    end: Alignment(-_bgAnim.value * 0.2, 1),
                    colors: const [
                      Color(0xFF0F2027),
                      Color(0xFF203A43),
                      Color(0xFF2C5364),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: _buildFloatingIcons(),
              );
            },
          ),
          // Glow corners
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (context, _) {
              return Stack(
                children: [
                  Positioned(
                    top: -100, left: -100,
                    child: Container(
                      width: 300, height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppTheme.ayanamiBlue.withValues(alpha: 0.15 + _bgAnim.value * 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80, right: -80,
                    child: Container(
                      width: 250, height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF2C5364).withValues(alpha: 0.2 + _bgAnim.value * 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo animado
                    _AnimatedLogo(),
                    const SizedBox(height: 40),
                    // Card de login
                    _LoginForm(
                      controller: _controller,
                      onLogin: _handleLogin,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingIcons() {
    return AnimatedBuilder(
      animation: _bgCtrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _FloatingIconsPainter(_icons, _bgCtrl.value),
          size: Size.infinite,
        );
      },
    );
  }
}

// ─── Floating icons background ───────────────────────────────────

class _FloatingIcon {
  final IconData icon;
  double x, y;
  final double size, speed, opacity, phase;
  _FloatingIcon({required this.icon, required this.x, required this.y,
    required this.size, required this.speed, required this.opacity, required this.phase});
}

class _FloatingIconsPainter extends CustomPainter {
  final List<_FloatingIcon> icons;
  final double time;

  _FloatingIconsPainter(this.icons, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    for (final icon in icons) {
      final x = icon.x * size.width + sin(time * 2 * pi + icon.phase) * 20;
      final y = icon.y * size.height + cos(time * 2 * pi + icon.phase) * 15;
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.icon.codePoint),
          style: TextStyle(
            fontSize: icon.size,
            fontFamily: icon.icon.fontFamily,
            color: Colors.white.withValues(alpha: icon.opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingIconsPainter old) => true;
}

// ─── Animated Logo ───────────────────────────────────────────────

class _AnimatedLogo extends StatefulWidget {
  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
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
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: Column(
            children: [
              // Cropped logo with transparent background for premium look
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'FarmaBook',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gestión Inteligente',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 3,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Login Form ──────────────────────────────────────────────────

class _LoginForm extends StatefulWidget {
  final LoginController controller;
  final VoidCallback onLogin;

  const _LoginForm({required this.controller, required this.onLogin});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  final _userFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _userFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Form(
            key: widget.controller.formKey,
            child: Column(
              children: [
                _Field(
                  controller: widget.controller.emailController,
                  label: 'Usuario',
                  icon: Icons.person_outline,
                  focusNode: _userFocusNode,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocusNode),
                ),
                const SizedBox(height: 14),
                _Field(
                  controller: widget.controller.passwordController,
                  label: 'Contraseña',
                  icon: Icons.lock_outline,
                  obscureText: widget.controller.obscurePassword,
                  focusNode: _passwordFocusNode,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => widget.onLogin(),
                  suffix: GestureDetector(
                    onTap: widget.controller.togglePasswordVisibility,
                    child: Icon(
                      widget.controller.obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: Colors.white38,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _LoginButton(
                  isLoading: widget.controller.isLoading,
                  onPressed: widget.controller.isLoading ? null : widget.onLogin,
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => context.go('/forgot-password', extra: RecoveryController()),
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

// ─── Campo de texto ──────────────────────────────────────────────

class _Field extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_Field old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      old.focusNode?.removeListener(_onFocusChange);
      widget.focusNode?.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = widget.focusNode?.hasFocus ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) {
        if (widget.focusNode == null) setState(() => _focused = v);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _focused ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focused
                ? AppTheme.ayanamiBlue.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.obscureText,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              color: _focused
                  ? AppTheme.ayanamiBlue
                  : Colors.white60,
              fontSize: 14,
            ),
            floatingLabelStyle: TextStyle(
              color: _focused ? AppTheme.ayanamiBlue : Colors.white60,
              fontSize: 12,
            ),
            prefixIcon: Icon(widget.icon, color: _focused ? AppTheme.ayanamiBlue : Colors.white60, size: 20),
            suffixIcon: widget.suffix != null
                ? Padding(padding: const EdgeInsets.only(right: 8), child: widget.suffix)
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
        ),
      ),
    );
  }
}

// ─── Botón con animación ─────────────────────────────────────────

class _LoginButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _LoginButton({required this.isLoading, this.onPressed});

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton>
    with SingleTickerProviderStateMixin {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _hovering ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _hovering
                    ? [AppTheme.ayanamiBlue, const Color(0xFF4A8BC4)]
                    : [AppTheme.ayanamiBlue.withValues(alpha: 0.9), const Color(0xFF4A8BC4).withValues(alpha: 0.9)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.ayanamiBlue.withValues(alpha: _hovering ? 0.4 : 0.2),
                  blurRadius: _hovering ? 16 : 8,
                  offset: Offset(0, _hovering ? 6 : 4),
                ),
              ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'INICIAR SESIÓN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
