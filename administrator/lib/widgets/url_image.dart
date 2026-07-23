import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../utils/image_url.dart';

/// Network image with proxy fallback for admin URL previews.
class UrlImage extends StatefulWidget {
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
  State<UrlImage> createState() => _UrlImageState();
}

class _UrlImageState extends State<UrlImage> {
  int _attempt = 0;

  @override
  void didUpdateWidget(covariant UrlImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _attempt = 0;
  }

  String _urlForAttempt() {
    final tidy = ImageUrl.tidy(widget.url);
    if (tidy.isEmpty) return '';
    if (kIsWeb) {
      return _attempt == 0 ? ImageUrl.proxied(tidy) : tidy;
    }
    return _attempt == 0 ? tidy : ImageUrl.proxied(tidy);
  }

  @override
  Widget build(BuildContext context) {
    final displayUrl = _urlForAttempt();

    Widget child;
    if (displayUrl.isEmpty) {
      child = _placeholder(icon: Icons.image_not_supported_rounded);
    } else {
      child = CachedNetworkImage(
        imageUrl: displayUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        fadeInDuration: const Duration(milliseconds: 120),
        placeholder: (context, url) => _placeholder(loading: true),
        errorWidget: (context, url, error) {
          if (_attempt == 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _attempt = 1);
            });
            return _placeholder(loading: true);
          }
          return _placeholder(icon: Icons.image_not_supported_rounded);
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: child,
    );
  }

  Widget _placeholder({bool loading = false, IconData? icon}) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 120,
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
