import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';

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
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: Stack(
        children: [
          // Background radial glow
          Positioned(
            top: -60,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AdminColors.emerald.withOpacity(0.12), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AdminColors.amber.withOpacity(0.08), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    // Logo
                    Animate(
                      effects: const [
                        FadeEffect(duration: Duration(milliseconds: 500)),
                        SlideEffect(
                          begin: Offset(0, -0.2),
                          end: Offset.zero,
                          duration: Duration(milliseconds: 500),
                        ),
                      ],
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: AdminColors.emeraldGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AdminColors.emerald.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.eco_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Animate(
                      delay: const Duration(milliseconds: 100),
                      effects: const [
                        FadeEffect(duration: Duration(milliseconds: 500)),
                        SlideEffect(begin: Offset(0, 0.1), end: Offset.zero, duration: Duration(milliseconds: 500)),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back',
                            style: GoogleFonts.inter(
                              color: AdminColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sign in to the Asilia Admin Panel',
                            style: GoogleFonts.inter(
                              color: AdminColors.textDim,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Form fields
                    Animate(
                      delay: const Duration(milliseconds: 200),
                      effects: const [
                        FadeEffect(duration: Duration(milliseconds: 500)),
                        SlideEffect(begin: Offset(0, 0.1), end: Offset.zero, duration: Duration(milliseconds: 500)),
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: GoogleFonts.inter(
                              color: AdminColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 14),
                            validator: (v) => v == null || v.isEmpty ? 'Enter your email' : null,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.email_outlined, color: AdminColors.textDim, size: 18),
                              hintText: 'mimeanidawa@gmail.com',
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Password',
                            style: GoogleFonts.inter(
                              color: AdminColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 14),
                            validator: (v) => v == null || v.isEmpty ? 'Enter your password' : null,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AdminColors.textDim, size: 18),
                              hintText: '••••••••',
                              suffixIcon: GestureDetector(
                                onTap: () => setState(() => _obscurePass = !_obscurePass),
                                child: Icon(
                                  _obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: AdminColors.textDim,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          if (_errorMsg != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AdminColors.redGlow,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AdminColors.red.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AdminColors.red, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMsg!,
                                      style: GoogleFonts.inter(color: AdminColors.red, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: provider.isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminColors.emerald,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: provider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Sign In',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
