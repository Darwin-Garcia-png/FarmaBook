import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controllers/recovery_controller.dart';
import '../widgets/gradient_button.dart';
import '../theme/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  final RecoveryController controller;
  const ResetPasswordScreen({super.key, required this.controller});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final RecoveryController _c;
  late final FocusNode _passwordFocusNode;
  late final FocusNode _confirmFocusNode;

  @override
  void initState() {
    super.initState();
    _c = widget.controller;
    _c.addListener(_onChanged);
    _passwordFocusNode = FocusNode();
    _confirmFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleReset() async {
    final ok = await _c.setNewPassword();
    if (ok && mounted) {
      _c.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Contraseña actualizada correctamente'),
          backgroundColor: AppTheme.greenMetal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                        ),
                        child: const Icon(Icons.password_rounded, size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nueva Contraseña',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa tu nueva contraseña',
                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.75)),
                      ),
                      const SizedBox(height: 32),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                            ),
                            child: Form(
                              key: _c.formKey,
                              child: Column(
                                children: [
                                  _buildPasswordField(
                                    focusNode: _passwordFocusNode,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_confirmFocusNode),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildConfirmField(
                                    focusNode: _confirmFocusNode,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _handleReset(),
                                  ),
                                  if (_c.errorMessage != null) ...[
                                    const SizedBox(height: 12),
                                    _buildError(_c.errorMessage!),
                                  ],
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: GradientButton(
                                      text: 'Cambiar Contraseña',
                                      onPressed: _c.isLoading ? null : _handleReset,
                                      isLoading: _c.isLoading,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: () {
                                      _c.reset();
                                      context.go('/login');
                                    },
                                    child: Text(
                                      'Volver al inicio de sesión',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                                    ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required FocusNode focusNode,
    required TextInputAction textInputAction,
    required ValueChanged<String> onFieldSubmitted,
  }) {
    return TextFormField(
      controller: _c.passwordController,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      obscureText: !_c.obscurePassword,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Nueva contraseña',
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(Icons.lock_outline, color: AppTheme.ayanamiBlue.withValues(alpha: 0.6), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _c.obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white54, size: 18,
          ),
          onPressed: _c.togglePasswordVisibility,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.ayanamiBlue, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppTheme.reiOrangeRed, fontSize: 11),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Contraseña requerida';
        if (v.length < 8) return 'Mínimo 8 caracteres';
        if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Debe tener al menos una mayúscula';
        if (!RegExp(r'[0-9]').hasMatch(v)) return 'Debe tener al menos un número';
        return null;
      },
    );
  }

  Widget _buildConfirmField({
    required FocusNode focusNode,
    required TextInputAction textInputAction,
    required ValueChanged<String> onFieldSubmitted,
  }) {
    return TextFormField(
      controller: _c.confirmPasswordController,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      obscureText: !_c.obscureConfirm,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Confirmar contraseña',
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(Icons.lock_outline, color: AppTheme.ayanamiBlue.withValues(alpha: 0.6), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _c.obscureConfirm ? Icons.visibility_off : Icons.visibility,
            color: Colors.white54, size: 18,
          ),
          onPressed: _c.toggleConfirmVisibility,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.ayanamiBlue, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppTheme.reiOrangeRed, fontSize: 11),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Confirmar contraseña';
        if (v != _c.passwordController.text) return 'Las contraseñas no coinciden';
        return null;
      },
    );
  }

  Widget _buildError(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.reiOrangeRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.reiOrangeRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.reiOrangeRed, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }
}
