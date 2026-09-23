import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/remote_app_config.dart';
import '../theme/app_colors.dart';

/// Full-screen gate — blocks all app content until the user updates.
class ForceUpdateGate extends StatelessWidget {
  const ForceUpdateGate({
    super.key,
    required this.config,
    required this.currentVersion,
    required this.currentBuild,
  });

  final AppUpdateConfig config;
  final String currentVersion;
  final int currentBuild;

  String get _title =>
      config.title.trim().isNotEmpty ? config.title.trim() : 'Update Required';

  String get _message {
    if (config.message.trim().isNotEmpty) return config.message.trim();
    return 'A new version of Dawa Asili is available. Update now to continue.';
  }

  String? get _requiredLabel {
    final parts = <String>[];
    if (config.minVersion.trim().isNotEmpty) {
      parts.add('v${config.minVersion.trim()}');
    }
    if (config.minBuild > 0) parts.add('build ${config.minBuild}');
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  String get _currentLabel {
    final v = currentVersion.trim();
    if (v.isEmpty && currentBuild <= 0) return 'Unknown';
    if (v.isEmpty) return 'build $currentBuild';
    if (currentBuild > 0) return 'v$v · build $currentBuild';
    return 'v$v';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.forest,
        ),
        child: Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF041510),
                  AppColors.forest,
                  Color(0xFF0F2E26),
                  AppColors.emerald900,
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -size.width * 0.25,
                  right: -size.width * 0.2,
                  child: _glowOrb(size.width * 0.7, AppColors.emerald400, 0.12),
                ),
                Positioned(
                  bottom: -size.width * 0.3,
                  left: -size.width * 0.25,
                  child: _glowOrb(size.width * 0.8, AppColors.amber, 0.08),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        _iconBadge()
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .scale(
                              begin: const Offset(0.92, 0.92),
                              curve: Curves.easeOutCubic,
                            ),
                        const SizedBox(height: 32),
                        Text(
                          _title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fraunces(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 80.ms, duration: 450.ms)
                            .slideY(begin: 0.08, curve: Curves.easeOutCubic),
                        const SizedBox(height: 14),
                        Text(
                          _message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            height: 1.55,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 140.ms, duration: 450.ms)
                            .slideY(begin: 0.06, curve: Curves.easeOutCubic),
                        const SizedBox(height: 28),
                        _versionRow()
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms),
                        const Spacer(flex: 3),
                        _updateButton()
                            .animate()
                            .fadeIn(delay: 260.ms, duration: 450.ms)
                            .slideY(begin: 0.12, curve: Curves.easeOutCubic),
                        const SizedBox(height: 14),
                        Text(
                          'You must update before using the app',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.38),
                          ),
                        ).animate().fadeIn(delay: 320.ms, duration: 400.ms),
                        const SizedBox(height: 24),
                      ],
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

  Widget _glowOrb(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }

  Widget _iconBadge() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald400.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Image.asset(
          'assets/app_icon.png',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: AppColors.emerald800,
            child: const Icon(
              Icons.system_update_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
        ),
      ),
    );
  }

  Widget _versionRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        _versionChip(
          label: 'Your version',
          value: _currentLabel,
          accent: Colors.white.withValues(alpha: 0.12),
        ),
        if (_requiredLabel != null)
          _versionChip(
            label: 'Required',
            value: _requiredLabel!,
            accent: AppColors.amber.withValues(alpha: 0.22),
            valueColor: AppColors.amberLight,
          ),
      ],
    );
  }

  Widget _versionChip({
    required String label,
    required String value,
    required Color accent,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _updateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.amber, Color(0xFFD4925E)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.amber.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => openPlayStore(config.storeUrl),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: const Color(0xFF1A1205),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.open_in_new_rounded, size: 20),
          label: Text(
            'Update Now',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> openPlayStore(String storeUrl) async {
  final uri = Uri.tryParse(
    storeUrl.trim().isEmpty
        ? 'https://play.google.com/store/apps/details?id=com.asilia'
        : storeUrl.trim(),
  );
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
