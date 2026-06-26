import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../controllers/recovery_controller.dart';
import '../widgets/gradient_button.dart';
import '../theme/app_theme.dart';

class VerifyPinScreen extends StatefulWidget {
  final RecoveryController controller;
  const VerifyPinScreen({super.key, required this.controller});

  @override
  State<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends State<VerifyPinScreen> {
  late final RecoveryController _c;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _c = widget.controller;
    _c.addListener(_onChanged);
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _c.verifyPin();
    if (ok && mounted) {
      context.go('/reset-password', extra: _c);
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
                colors: const [Color(0xFF6DABE4), Color(0xFF2A4365), Color(0xFF1A2744)],
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
                        child: const Icon(Icons.pin_rounded, size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Verificar PIN',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa el PIN de 6 dígitos enviado a tu correo',
                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.75)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Si no lo encuentras, revisa la bandeja de spam',
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45), fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                        ),
                        child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _buildPinField(),
                                  if (_c.errorMessage != null) ...[
                                    const SizedBox(height: 12),
                                    _buildError(_c.errorMessage!),
                                  ],
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: GradientButton(
                                      text: 'Verificar PIN',
                                      onPressed: _c.isLoading ? null : _handleVerify,
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
                                      'Volver al inicio',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
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
          ),
        ],
      ),
    );
  }

  Widget _buildPinField() {
    return TextFormField(
      controller: _c.pinController,
      maxLength: 6,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      autofocus: true,
      style: const TextStyle(color: Colors.white, fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        counterText: '',
        labelText: 'PIN',
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(Icons.pin_outlined, color: AppTheme.ayanamiBlue.withValues(alpha: 0.6), size: 20),
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
        if (v == null || v.trim().isEmpty) return 'PIN requerido';
        if (v.trim().length != 6) return 'Debe tener 6 dígitos';
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
