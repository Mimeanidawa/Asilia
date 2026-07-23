import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../utils/image_url.dart';

/// Network image that loads via the Asilia API proxy/media cache.
class UrlImage extends StatelessWidget {
  const UrlImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
  });

  final String url;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final displayUrl = ImageUrl.display(url);

    Widget child;
    if (displayUrl.isEmpty) {
      child = _placeholder(icon: Icons.image_not_supported_rounded);
    } else {
      child = CachedNetworkImage(
        imageUrl: displayUrl,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 120),
        placeholder: (context, url) => _placeholder(loading: true),
        errorWidget: (context, url, error) =>
            _placeholder(icon: Icons.image_not_supported_rounded),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );
  }

  Widget _placeholder({bool loading = false, IconData? icon}) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 120,
      color: AdminColors.card,
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AdminColors.emerald,
                strokeWidth: 2,
              ),
            )
          : Icon(icon ?? Icons.image_outlined, color: AdminColors.textDim),
    );
  }
}
