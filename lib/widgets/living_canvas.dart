import 'package:flutter/material.dart';

/// Slow botanical wash behind the user app.
/// Colors drift between cream, leaf, and warm paper so the canvas
/// feels alive without competing with the content.
class LivingCanvas extends StatefulWidget {
  const LivingCanvas({super.key, required this.child});

  final Widget child;

  @override
  State<LivingCanvas> createState() => _LivingCanvasState();
}

class _LivingCanvasState extends State<LivingCanvas>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  static const _washes = <List<Color>>[
    [Color(0xFFF6E7D4), Color(0xFFD5E6DC), Color(0xFFE4CDB4)],
    [Color(0xFFE7F2EB), Color(0xFFC9DDD2), Color(0xFFF0DCC4)],
    [Color(0xFFF3E4D2), Color(0xFFD2E4DA), Color(0xFFE8D2B8)],
    [Color(0xFFF8EBD8), Color(0xFFD7E8DE), Color(0xFFE9F3EC)],
  ];

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  Color _mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, child) {
        final span = _drift.value * _washes.length;
        final index = span.floor() % _washes.length;
        final next = (index + 1) % _washes.length;
        final t = Curves.easeInOut.transform(span - span.floor());
        final wave = Curves.easeInOut.transform(
          (0.5 + 0.5 * (2 * _drift.value - 1).abs()),
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.8 + wave * 0.6, -1),
              end: Alignment(0.9 - wave * 0.4, 1),
              colors: [
                _mix(_washes[index][0], _washes[next][0], t),
                _mix(_washes[index][1], _washes[next][1], t),
                _mix(_washes[index][2], _washes[next][2], t),
              ],
              stops: const [0.0, 0.48, 1.0],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: -80 + (wave * 36),
                right: -40 + (wave * 24),
                child: _Glow(
                  size: 240,
                  color: const Color(0xFF0F6E56).withValues(alpha: 0.2),
                ),
              ),
              Positioned(
                bottom: 40 - (wave * 28),
                left: -70 + (wave * 20),
                child: _Glow(
                  size: 220,
                  color: const Color(0xFFC47A3A).withValues(alpha: 0.18),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
