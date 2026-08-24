import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/admin_colors.dart';
import '../widgets/admin_ui.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 2600), widget.onDone);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Animate(
                    effects: const [
                      ScaleEffect(
                        begin: Offset(0.6, 0.6),
                        end: Offset(1, 1),
                        duration: Duration(milliseconds: 700),
                        curve: Curves.easeOutBack,
                      ),
                      FadeEffect(duration: Duration(milliseconds: 400)),
                    ],
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, child) {
                        return Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AdminColors.emerald.withValues(
                                  alpha: 0.15 + _pulse.value * 0.15,
                                ),
                                blurRadius: 40 + _pulse.value * 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: AdminColors.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: Color(0xFF052E16),
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Animate(
                    delay: const Duration(milliseconds: 350),
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 500)),
                      SlideEffect(
                        begin: Offset(0, 0.2),
                        end: Offset.zero,
                        duration: Duration(milliseconds: 500),
                      ),
                    ],
                    child: Column(
                      children: [
                        Text(
                          'Asilia Admin',
                          style: GoogleFonts.plusJakartaSans(
                            color: AdminColors.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dawa Asili · Control Panel',
                          style: GoogleFonts.plusJakartaSans(
                            color: AdminColors.textMuted,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 56),
                  Animate(
                    delay: const Duration(milliseconds: 700),
                    effects: const [FadeEffect(duration: Duration(milliseconds: 500))],
                    child: SizedBox(
                      width: 140,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          backgroundColor: AdminColors.cardBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.emerald),
                          minHeight: 3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Animate(
                delay: const Duration(milliseconds: 500),
                effects: const [FadeEffect(duration: Duration(milliseconds: 500))],
                child: Text(
                  'v1.0.1',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: AdminColors.textDim,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
