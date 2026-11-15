import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import '../widgets/admin_ui.dart';

/// Locked to the sole admin account — email is never shown in the UI.
const _adminEmail = 'mimeanidawa@gmail.com';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _passFocus = FocusNode();
  bool _obscurePass = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _passFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMsg = null);
    FocusScope.of(context).unfocus();

    final success = await context.read<AdminProvider>().login(
          _adminEmail,
          _passCtrl.text.trim(),
        );
    if (!success && mounted) {
      setState(() => _errorMsg =
          context.read<AdminProvider>().loginError ??
          'Nenosiri si sahihi. Jaribu tena.');
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AdminBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8 : 0),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),

                        // Brand mark
                        Animate(
                          effects: const [
                            FadeEffect(duration: Duration(milliseconds: 500)),
                            ScaleEffect(
                              begin: Offset(0.88, 0.88),
                              end: Offset(1, 1),
                              duration: Duration(milliseconds: 550),
                              curve: Curves.easeOutBack,
                            ),
                          ],
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              gradient: AdminColors.primaryGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AdminColors.emerald.withValues(alpha: 0.35),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              color: Color(0xFF052E16),
                              size: 40,
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        Animate(
                          delay: const Duration(milliseconds: 80),
                          effects: const [
                            FadeEffect(duration: Duration(milliseconds: 450)),
                            SlideEffect(
                              begin: Offset(0, 0.12),
                              end: Offset.zero,
                              duration: Duration(milliseconds: 450),
                            ),
                          ],
                          child: Column(
                            children: [
                              Text(
                                'Asilia',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AdminColors.textPrimary,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.4,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ingia kwa nenosiri la admin',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AdminColors.textMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        Animate(
                          delay: const Duration(milliseconds: 160),
                          effects: const [
                            FadeEffect(duration: Duration(milliseconds: 450)),
                            SlideEffect(
                              begin: Offset(0, 0.1),
                              end: Offset.zero,
                              duration: Duration(milliseconds: 450),
                            ),
                          ],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Nenosiri',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AdminColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _passCtrl,
                                focusNode: _passFocus,
                                obscureText: _obscurePass,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.go,
                                onFieldSubmitted: (_) {
                                  if (!provider.isLoading) _login();
                                },
                                style: GoogleFonts.plusJakartaSans(
                                  color: AdminColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: _obscurePass ? 2 : 0,
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Weka nenosiri' : null,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AdminColors.card,
                                  hintText: '••••••••',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    color: AdminColors.textDim,
                                    letterSpacing: 2,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_rounded,
                                    size: 20,
                                    color: AdminColors.emerald,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () =>
                                        setState(() => _obscurePass = !_obscurePass),
                                    icon: Icon(
                                      _obscurePass
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      size: 20,
                                      color: AdminColors.textMuted,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 18,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: AdminColors.cardBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: AdminColors.cardBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: AdminColors.emerald.withValues(alpha: 0.7),
                                      width: 1.5,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: AdminColors.error),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AdminColors.error,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),

                              if (_errorMsg != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AdminColors.redGlow,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AdminColors.error.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: AdminColors.error,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _errorMsg!,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: AdminColors.error,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(duration: 200.ms).shake(
                                      hz: 3,
                                      duration: 320.ms,
                                      offset: const Offset(4, 0),
                                    ),
                              ],

                              const SizedBox(height: 24),

                              AdminPrimaryButton(
                                label: 'Ingia',
                                loading: provider.isLoading,
                                onPressed: _login,
                                icon: Icons.arrow_forward_rounded,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 36),

                        Animate(
                          delay: const Duration(milliseconds: 280),
                          effects: const [
                            FadeEffect(duration: Duration(milliseconds: 500)),
                          ],
                          child: Text(
                            'Admin · Dawa Asili',
                            style: GoogleFonts.plusJakartaSans(
                              color: AdminColors.textDim,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
