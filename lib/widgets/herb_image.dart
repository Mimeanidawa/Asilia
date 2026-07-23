import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/image_url.dart';

class HerbImage extends StatefulWidget {
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
  State<HerbImage> createState() => _HerbImageState();
}

class _HerbImageState extends State<HerbImage> {
  /// 0 = prefer direct (or proxy on web), 1 = fallback to the other.
  int _attempt = 0;

  @override
  void didUpdateWidget(covariant HerbImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _attempt = 0;
    }
  }

  int? _cachePx(BuildContext context, double? logical) {
    if (logical == null || !logical.isFinite || logical <= 0) return null;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logical * dpr).round().clamp(48, 1600);
  }

  String _urlForAttempt() {
    final tidy = ImageUrl.tidy(widget.url);
    if (tidy.isEmpty) return '';
    // Web needs the API proxy (CORS). Native/desktop load the CDN directly
    // (Postimages is slow via Railway proxy). Fall back to the other on error.
    if (kIsWeb) {
      return _attempt == 0 ? ImageUrl.proxied(tidy) : tidy;
    }
    return _attempt == 0 ? tidy : ImageUrl.proxied(tidy);
  }

  @override
  Widget build(BuildContext context) {
    final displayUrl = _urlForAttempt();
    final imageWidth = widget.fullWidth ? double.infinity : widget.width;

    Widget child;
    if (displayUrl.isEmpty) {
      child = _placeholder(imageWidth, icon: Icons.eco);
    } else {
      child = CachedNetworkImage(
        imageUrl: displayUrl,
        width: imageWidth,
        height: widget.height,
        fit: widget.fit,
        fadeInDuration: const Duration(milliseconds: 120),
        memCacheWidth: _cachePx(context, widget.width ?? (widget.fullWidth ? 600 : null)),
        memCacheHeight: _cachePx(context, widget.height),
        placeholder: (context, url) => _placeholder(imageWidth, loading: true),
        errorWidget: (context, url, error) {
          if (_attempt == 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _attempt = 1);
            });
            return _placeholder(imageWidth, loading: true);
          }
          return _placeholder(imageWidth, icon: Icons.eco);
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: widget.fullWidth && widget.height != null
          ? SizedBox(width: double.infinity, height: widget.height, child: child)
          : child,
    );
  }

  Widget _placeholder(double? width, {bool loading = false, IconData? icon}) {
    return Container(
      width: width,
      height: widget.height,
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
