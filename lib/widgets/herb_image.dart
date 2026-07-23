import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/image_url.dart';

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

  int? _cachePx(BuildContext context, double? logical) {
    if (logical == null || !logical.isFinite || logical <= 0) return null;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logical * dpr).round().clamp(48, 1600);
  }

  @override
  Widget build(BuildContext context) {
    final displayUrl = ImageUrl.display(url);
    final imageWidth = fullWidth ? double.infinity : width;

    Widget child;
    if (displayUrl.isEmpty) {
      child = _placeholder(imageWidth, icon: Icons.eco);
    } else {
      // Always load via API image proxy — avoids ImgBB/Postimages hotlink + CORS blocks.
      child = CachedNetworkImage(
        imageUrl: displayUrl,
        width: imageWidth,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 120),
        memCacheWidth: _cachePx(context, width ?? (fullWidth ? 600 : null)),
        memCacheHeight: _cachePx(context, height),
        placeholder: (context, url) => _placeholder(imageWidth, loading: true),
        errorWidget: (context, url, error) =>
            _placeholder(imageWidth, icon: Icons.eco),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: fullWidth && height != null
          ? SizedBox(width: double.infinity, height: height, child: child)
          : child,
    );
  }

  Widget _placeholder(double? width, {bool loading = false, IconData? icon}) {
    return Container(
      width: width,
      height: height,
      color: AppColors.emerald50,
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon ?? Icons.eco, color: AppColors.emerald700),
    );
  }
}
