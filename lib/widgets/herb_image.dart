import 'package:cached_network_image/cached_network_image.dart';
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
  String? _resolvedShareUrl;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _maybeResolveShareUrl();
  }

  @override
  void didUpdateWidget(covariant HerbImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _resolvedShareUrl = null;
      _resolving = false;
      _maybeResolveShareUrl();
    }
  }

  void _maybeResolveShareUrl() {
    final tidy = ImageUrl.tidy(widget.url);
    if (tidy.isEmpty || !ImageUrl.needsResolution(tidy)) return;

    _resolving = true;
    ImageUrl.resolve(tidy).then((resolved) {
      if (!mounted || ImageUrl.tidy(widget.url) != tidy) return;
      setState(() {
        _resolvedShareUrl = resolved;
        _resolving = false;
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _resolving = false);
    });
  }

  int? _cachePx(double? logical) {
    if (logical == null || !logical.isFinite || logical <= 0) return null;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logical * dpr).round().clamp(48, 1600);
  }

  @override
  Widget build(BuildContext context) {
    final tidy = ImageUrl.tidy(widget.url);
    final displayUrl = _resolvedShareUrl ?? tidy;
    final imageWidth = widget.fullWidth ? double.infinity : widget.width;

    Widget child;
    if (displayUrl.isEmpty) {
      child = _placeholder(imageWidth, icon: Icons.eco);
    } else if (_resolving && _resolvedShareUrl == null) {
      child = _placeholder(imageWidth, loading: true);
    } else {
      // No custom headers — browsers forbid User-Agent and extra Accept
      // triggers CORS preflight that blocks many image CDNs (incl. admin web).
      child = CachedNetworkImage(
        imageUrl: displayUrl,
        width: imageWidth,
        height: widget.height,
        fit: widget.fit,
        fadeInDuration: const Duration(milliseconds: 120),
        memCacheWidth: _cachePx(widget.width ?? (widget.fullWidth ? 600 : null)),
        memCacheHeight: _cachePx(widget.height),
        placeholder: (context, url) => _placeholder(imageWidth, loading: true),
        errorWidget: (context, url, error) =>
            _placeholder(imageWidth, icon: Icons.eco),
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
