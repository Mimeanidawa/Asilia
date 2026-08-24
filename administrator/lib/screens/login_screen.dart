import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import '../widgets/admin_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'mimeanidawa@gmail.com');
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMsg = null);
    final success = await context.read<AdminProvider>().login(
          _emailCtrl.text.trim(),
          _passCtrl.text.trim(),
        );
    if (!success && mounted) {
      setState(() => _errorMsg =
          context.read<AdminProvider>().loginError ??
          'Invalid email or password. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return AdminBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Animate(
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 500)),
                      SlideEffect(
                        begin: Offset(0, -0.15),
                        end: Offset.zero,
                        duration: Duration(milliseconds: 500),
                      ),
                    ],
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AdminColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AdminColors.emerald.withValues(alpha: 0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.eco_rounded, color: Color(0xFF052E16), size: 28),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Asilia Admin',
                              style: GoogleFonts.plusJakartaSans(
                                color: AdminColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              'Control Panel',
                              style: GoogleFonts.plusJakartaSans(
                                color: AdminColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  Animate(
                    delay: const Duration(milliseconds: 100),
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 500)),
                      SlideEffect(begin: Offset(0, 0.08), end: Offset.zero, duration: Duration(milliseconds: 500)),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back',
                          style: GoogleFonts.plusJakartaSans(
                            color: AdminColors.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to manage your platform',
                          style: GoogleFonts.plusJakartaSans(
                            color: AdminColors.textMuted,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  Animate(
                    delay: const Duration(milliseconds: 200),
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 500)),
                      SlideEffect(begin: Offset(0, 0.08), end: Offset.zero, duration: Duration(milliseconds: 500)),
                    ],
                    child: AdminSurface(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: GoogleFonts.plusJakartaSans(
                              color: AdminColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.plusJakartaSans(
                              color: AdminColors.textPrimary,
                              fontSize: 14,
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Enter your email' : null,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
                              hintText: 'admin@example.com',
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Password',
                            style: GoogleFonts.plusJakartaSans(
                              color: AdminColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            style: GoogleFonts.plusJakartaSans(
                              color: AdminColors.textPrimary,
                              fontSize: 14,
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Enter your password' : null,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                              hintText: '••••••••',
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                icon: Icon(
                                  _obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  size: 18,
                                  color: AdminColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                          if (_errorMsg != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AdminColors.redGlow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AdminColors.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AdminColors.error, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMsg!,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AdminColors.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          AdminPrimaryButton(
                            label: 'Sign In',
                            loading: provider.isLoading,
                            onPressed: _login,
                            icon: Icons.arrow_forward_rounded,
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
    );
  }
}
