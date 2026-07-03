import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/admin_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), widget.onDone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AdminColors.emerald.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AdminColors.amber.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Animate(
                  effects: const [
                    ScaleEffect(
                      begin: Offset(0.5, 0.5),
                      end: Offset(1, 1),
                      duration: Duration(milliseconds: 700),
                      curve: Curves.elasticOut,
                    ),
                    FadeEffect(duration: Duration(milliseconds: 400)),
                  ],
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: AdminColors.emeraldGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AdminColors.emerald.withOpacity(0.4),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Animate(
                  delay: const Duration(milliseconds: 400),
                  effects: const [
                    FadeEffect(duration: Duration(milliseconds: 500)),
                    SlideEffect(
                      begin: Offset(0, 0.3),
                      end: Offset.zero,
                      duration: Duration(milliseconds: 500),
                    ),
                  ],
                  child: Column(
                    children: [
                      Text(
                        'Asilia Admin',
                        style: GoogleFonts.inter(
                          color: AdminColors.textPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Control Panel · Dawa Asili',
                        style: GoogleFonts.inter(
                          color: AdminColors.textDim,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 64),
                Animate(
                  delay: const Duration(milliseconds: 900),
                  effects: const [FadeEffect(duration: Duration(milliseconds: 600))],
                  child: SizedBox(
                    width: 120,
                    child: LinearProgressIndicator(
                      backgroundColor: AdminColors.cardBorder,
                      valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.emerald),
                      borderRadius: BorderRadius.circular(4),
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
              delay: const Duration(milliseconds: 600),
              effects: const [FadeEffect(duration: Duration(milliseconds: 500))],
              child: Text(
                'v1.0.0',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
