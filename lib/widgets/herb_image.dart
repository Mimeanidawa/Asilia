import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class HerbImage extends StatelessWidget {
  const HerbImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.fullWidth = false,
  });

  final String url;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final imageWidth = fullWidth ? double.infinity : width;

    final image = CachedNetworkImage(
      imageUrl: url,
      width: imageWidth,
      height: height,
      fit: fit,
      placeholder: (_, __) => Container(
        width: imageWidth,
        height: height,
        color: AppColors.emerald50,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        width: imageWidth,
        height: height,
        color: AppColors.emerald50,
        child: const Icon(Icons.eco, color: AppColors.emerald700),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: fullWidth && height != null
          ? SizedBox(width: double.infinity, height: height, child: image)
          : image,
    );
  }
}
