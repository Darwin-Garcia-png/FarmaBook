import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../controllers/login_controller.dart';
import '../services/api_service.dart';
import '../controllers/almacen_controller.dart';
import '../controllers/lotes_controller.dart';
import '../widgets/gradient_button.dart';
import '../theme/app_theme.dart';
import '../widgets/error_display.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController _controller = LoginController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
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
          ErrorDisplay.dialog(context: context, message: '$e', title: 'Error al cargar datos');
        }
      }
    }
  }

  void _showRegisterDialog() {
    final formKey = GlobalKey<FormState>();
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool obscure = true;
    bool loading = false;
    String? selectedRole;

    const roleOptions = ['Dueño', 'Administrador', 'Cajero'];

    showDialog(
      context: context,
      barrierColor: Colors.black87.withOpacity(0.8),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: 440,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.ayanamiBlue, Color(0xFF5B9BD5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                            child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Crear Cuenta',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                            SizedBox(height: 2),
                            Text('Regístrate para usar FarmaBook',
                              style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
                          ]),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(children: [
                                Text('ACCESO AL SISTEMA',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
                              ]),
                              const SizedBox(height: 16),
                              _registerField('Usuario *', usernameCtrl, Icons.alternate_email_rounded, hint: 'Ej: juan.perez'),
                              const SizedBox(height: 4),
                              _registerField('Email *', emailCtrl, Icons.email_outlined,
                                  keyboard: TextInputType.emailAddress, hint: 'ejemplo@correo.com'),
                              const SizedBox(height: 4),
                              _registerPassField('Contraseña *', passCtrl, obscure, () => setDState(() => obscure = !obscure)),
                              const SizedBox(height: 12),
                              const Row(children: [
                                Text('ROL',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.5)),
                              ]),
                              const SizedBox(height: 4),
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedRole,
                                    isExpanded: true,
                                    hint: Text('Seleccionar rol', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                                    items: roleOptions.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14)))).toList(),
                                    onChanged: (v) => setDState(() => selectedRole = v),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 12, 32, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blueGrey,
                                side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: loading ? null : () async {
                                if (!formKey.currentState!.validate()) return;
                                if (selectedRole == null) {
                                  ErrorDisplay.snackBar(context: ctx, message: 'Debes seleccionar un rol');
                                  return;
                                }
                                setDState(() => loading = true);
                                try {
                                  await ApiService.createUser({
                                    'username': usernameCtrl.text.trim(),
                                    'email': emailCtrl.text.trim(),
                                    'password': passCtrl.text,
                                    'rolNombre': selectedRole,
                                  });
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ErrorDisplay.successSnackBar(context: context, message: 'Cuenta creada exitosamente. Inicia sesión.');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ErrorDisplay.snackBar(context: context, message: '$e');
                                  }
                                } finally {
                                  if (ctx.mounted) setDState(() => loading = false);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.ayanamiBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: loading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('REGISTRARSE', style: TextStyle(fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Refined Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? const [Color(0xFF0F1115), Color(0xFF1A1A2E), Color(0xFF2A4365)]
                    : const [Color(0xFF6DABE4), Color(0xFF2A4365), Color(0xFF1A2744)],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // 2. Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.local_pharmacy_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'FarmaBook',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Gestión de Farmacia',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.75),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Simplified Glassmorphism Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                          ),
                          child: Form(
                            key: _controller.formKey,
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: _controller.emailController,
                                  label: 'Usuario',
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _controller.passwordController,
                                  label: 'Contraseña',
                                  icon: Icons.lock_outline,
                                  obscureText: _controller.obscurePassword,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _controller.obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.white54,
                                      size: 18,
                                    ),
                                    onPressed: _controller.togglePasswordVisibility,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: GradientButton(
                                    text: 'Iniciar Sesión',
                                    onPressed: _controller.isLoading ? null : _handleLogin,
                                    isLoading: _controller.isLoading,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('¿No tienes cuenta? ',
                                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                                    GestureDetector(
                                      onTap: _showRegisterDialog,
                                      child: const Text('Registrarse',
                                        style: TextStyle(color: AppTheme.ayanamiBlue, fontSize: 13, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.ayanamiBlue.withOpacity(0.6), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.ayanamiBlue, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppTheme.reiOrangeRed, fontSize: 11),
      ),
      validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
    );
  }

  Widget _registerField(String label, TextEditingController ctrl, IconData icon,
      {TextInputType keyboard = TextInputType.text, String hint = ''}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4A5568))),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            keyboardType: keyboard,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              hintText: hint.isNotEmpty ? hint : 'Ingresa $label',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(icon, size: 20, color: AppTheme.ayanamiBlue.withOpacity(0.6)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
              filled: true,
              fillColor: Colors.grey.withOpacity(0.04),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppTheme.ayanamiBlue.withOpacity(0.5), width: 1.5)),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.reiOrangeRed, width: 1)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Este campo es obligatorio';
              if (label.toLowerCase().contains('email')) {
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Email inválido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _registerPassField(String label, TextEditingController ctrl, bool obscure, VoidCallback toggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4A5568))),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            obscureText: !obscure,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              hintText: 'Mínimo 8 caracteres',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.lock_outline_rounded, size: 20, color: AppTheme.ayanamiBlue.withOpacity(0.6)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: Colors.grey),
                onPressed: toggle,
              ),
              filled: true,
              fillColor: Colors.grey.withOpacity(0.04),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppTheme.ayanamiBlue.withOpacity(0.5), width: 1.5)),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.reiOrangeRed, width: 1)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Contraseña requerida';
              if (v.length < 8) return 'Mínimo 8 caracteres';
              return null;
            },
          ),
        ],
      ),
    );
  }
}