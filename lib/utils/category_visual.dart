import 'package:flutter/material.dart';

/// Shared iconography and cover art for content categories.
class CategoryVisual {
  CategoryVisual._();

  static IconData iconFor(String? key) {
    switch ((key ?? '').toLowerCase().replaceAll(' ', '_')) {
      case 'mizizi':
        return Icons.grass_rounded;
      case 'miti':
        return Icons.park_rounded;
      case 'matunda':
        return Icons.spa_rounded;
      case 'mimea':
      case 'lishe':
        return Icons.eco_rounded;
      case 'vyakula':
        return Icons.restaurant_rounded;
      case 'wanawake':
        return Icons.favorite_rounded;
      case 'watoto':
        return Icons.child_care_rounded;
      case 'wanaume':
        return Icons.fitness_center_rounded;
      case 'darasa_huru':
        return Icons.school_rounded;
      case 'jifunze':
        return Icons.menu_book_rounded;
      case 'dodoso':
        return Icons.forum_rounded;
      default:
        return Icons.auto_stories_rounded;
    }
  }

  static List<Color> gradientFor(String? key) {
    switch ((key ?? '').toLowerCase().replaceAll(' ', '_')) {
      case 'mizizi':
        return const [Color(0xFF3D5A32), Color(0xFF1B3A24)];
      case 'miti':
        return const [Color(0xFF1A4532), Color(0xFF0C2A1B)];
      case 'matunda':
        return const [Color(0xFFB8894A), Color(0xFF7A4E1D)];
      case 'mimea':
        return const [Color(0xFF1E6A49), Color(0xFF0E3B28)];
      case 'lishe':
        return const [Color(0xFF2A6278), Color(0xFF1E4A5C)];
      case 'vyakula':
        return const [Color(0xFFC2783A), Color(0xFF8A4E1C)];
      case 'wanawake':
        return const [Color(0xFFB44A78), Color(0xFF7A2E52)];
      case 'watoto':
        return const [Color(0xFF6B4CA0), Color(0xFF3D2A68)];
      case 'wanaume':
        return const [Color(0xFF2F5FA0), Color(0xFF1A3A68)];
      case 'darasa_huru':
        return const [Color(0xFF1A4532), Color(0xFF0C2A1B)];
      default:
        return const [Color(0xFF1A4532), Color(0xFF0C2A1B)];
    }
  }
}

/// Soft cover used only when there is truly no photo — no letter glyphs.
class BrandedCover extends StatelessWidget {
  const BrandedCover({
    super.key,
    required this.label,
    this.category,
  });

  final String label;
  final String? category;

  @override
  Widget build(BuildContext context) {
    final colors = CategoryVisual.gradientFor(category);
    final icon = CategoryVisual.iconFor(category);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.88), size: 32),
      ),
    );
  }
}

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback onTap;
  final BorderRadius? borderRadius;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.985 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
