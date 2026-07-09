import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// Shimmer palette — high contrast so the sweep is clearly visible.
const _shimmerBase = Color(0xFFDDD8D0);
const _shimmerMid = Color(0xFFF0EBE3);
const _shimmerPeak = Color(0xFFFFFFFF);

/// Animated moving-light shimmer over skeleton placeholders.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return ClipRect(
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) {
              final t = _curve.value;
              // Wide diagonal band sweeps left → right
              return LinearGradient(
                begin: Alignment(-1.4 + t * 2.8, -0.4),
                end: Alignment(-0.4 + t * 2.8, 0.4),
                colors: const [
                  _shimmerBase,
                  _shimmerMid,
                  _shimmerPeak,
                  _shimmerMid,
                  _shimmerBase,
                ],
                stops: const [0.0, 0.38, 0.5, 0.62, 1.0],
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// A single skeleton block — white mask tinted by [ShimmerLoading] sweep.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
    this.margin,
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

/// Full-app bootstrap skeleton mirroring the home screen layout.
class AppLoadingSkeleton extends StatelessWidget {
  const AppLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ShimmerLoading(
          child: Column(
            children: [
              _buildHeaderSkeleton(),
              Expanded(
                child: ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  children: const [
                    _GreetingSkeleton(),
                    _CarouselSkeleton(),
                    _StatsSkeleton(),
                    _PathwaysSkeleton(),
                    DarasaCardSkeleton(),
                    _HorizontalCardsSkeleton(titleWidth: 140),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.forest.withValues(alpha: 0.04)),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SkeletonBox(width: 28, height: 28, borderRadius: BorderRadius.all(Radius.circular(8))),
          SkeletonBox(width: 100, height: 18, borderRadius: BorderRadius.all(Radius.circular(6))),
          SkeletonBox(width: 28, height: 28, borderRadius: BorderRadius.all(Radius.circular(8))),
        ],
      ),
    );
  }
}

class HomeContentSkeleton extends StatelessWidget {
  const HomeContentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: const [
          _CarouselSkeleton(),
          _StatsSkeleton(),
          _PathwaysSkeleton(),
          DarasaCardSkeleton(),
          _HorizontalCardsSkeleton(titleWidth: 160),
        ],
      ),
    );
  }
}

class DarasaHuruLoadingSkeleton extends StatelessWidget {
  const DarasaHuruLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        children: const [
          _FeaturedLessonSkeleton(),
          SizedBox(height: 24),
          SkeletonBox(width: 120, height: 14, margin: EdgeInsets.only(bottom: 8)),
          SkeletonBox(width: 180, height: 10, margin: EdgeInsets.only(bottom: 16)),
          _LessonTileSkeleton(),
          _LessonTileSkeleton(),
          _LessonTileSkeleton(),
        ],
      ),
    );
  }
}

class _GreetingSkeleton extends StatelessWidget {
  const _GreetingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 90, height: 22, margin: EdgeInsets.only(bottom: 6)),
          SkeletonBox(width: 200, height: 12, margin: EdgeInsets.only(bottom: 14)),
          SkeletonBox(height: 46, borderRadius: BorderRadius.all(Radius.circular(14))),
        ],
      ),
    );
  }
}

class _CarouselSkeleton extends StatelessWidget {
  const _CarouselSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: SkeletonBox(
        height: 210,
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: List.generate(4, (i) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 6, right: i == 3 ? 0 : 6),
              child: const Column(
                children: [
                  SkeletonBox(height: 18, borderRadius: BorderRadius.all(Radius.circular(6))),
                  SizedBox(height: 4),
                  SkeletonBox(height: 8, borderRadius: BorderRadius.all(Radius.circular(4))),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PathwaysSkeleton extends StatelessWidget {
  const _PathwaysSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 150, height: 14, margin: EdgeInsets.only(bottom: 6)),
              SkeletonBox(width: 220, height: 10),
            ],
          ),
        ),
        SizedBox(
          height: 118,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: const [
              SkeletonBox(width: 148, height: 118, borderRadius: BorderRadius.all(Radius.circular(18))),
              SizedBox(width: 12),
              SkeletonBox(width: 148, height: 118, borderRadius: BorderRadius.all(Radius.circular(18))),
              SizedBox(width: 12),
              SkeletonBox(width: 148, height: 118, borderRadius: BorderRadius.all(Radius.circular(18))),
            ],
          ),
        ),
      ],
    );
  }
}

class DarasaCardSkeleton extends StatelessWidget {
  const DarasaCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.forest.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(
              height: 248,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  SkeletonBox(width: 28, height: 28, borderRadius: BorderRadius.all(Radius.circular(14))),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 100, height: 10, margin: EdgeInsets.only(bottom: 4)),
                        SkeletonBox(width: 80, height: 8),
                      ],
                    ),
                  ),
                  SkeletonBox(width: 72, height: 32, borderRadius: BorderRadius.all(Radius.circular(12))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalCardsSkeleton extends StatelessWidget {
  const _HorizontalCardsSkeleton({required this.titleWidth});

  final double titleWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: titleWidth, height: 14, margin: const EdgeInsets.only(bottom: 6)),
              const SkeletonBox(width: 180, height: 10),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: const [
              SkeletonBox(width: 130, height: 160, borderRadius: BorderRadius.all(Radius.circular(16))),
              SizedBox(width: 12),
              SkeletonBox(width: 130, height: 160, borderRadius: BorderRadius.all(Radius.circular(16))),
              SizedBox(width: 12),
              SkeletonBox(width: 130, height: 160, borderRadius: BorderRadius.all(Radius.circular(16))),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturedLessonSkeleton extends StatelessWidget {
  const _FeaturedLessonSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(
            height: 180,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 80, height: 8, margin: EdgeInsets.only(bottom: 8)),
                SkeletonBox(height: 18, margin: EdgeInsets.only(bottom: 6)),
                SkeletonBox(width: 260, height: 18, margin: EdgeInsets.only(bottom: 10)),
                SkeletonBox(height: 11, margin: EdgeInsets.only(bottom: 4)),
                SkeletonBox(width: 220, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonTileSkeleton extends StatelessWidget {
  const _LessonTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 72, height: 72, borderRadius: BorderRadius.all(Radius.circular(12))),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 70, height: 8, margin: EdgeInsets.only(bottom: 6)),
                SkeletonBox(height: 12, margin: EdgeInsets.only(bottom: 4)),
                SkeletonBox(width: 180, height: 12, margin: EdgeInsets.only(bottom: 6)),
                SkeletonBox(width: 140, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
