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
  String? _overrideUrl;
  int _attempt = 0;
  bool _resolving = false;

  @override
  void didUpdateWidget(covariant HerbImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _attempt = 0;
      _overrideUrl = null;
      _resolving = false;
    }
  }

  int? _cachePx(BuildContext context, double? logical) {
    if (logical == null || !logical.isFinite || logical <= 0) return null;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logical * dpr).round().clamp(48, 1200);
  }

  String get _sourceUrl => ImageUrl.normalize(ImageUrl.tidy(widget.url));

  String _urlForAttempt() {
    if (_overrideUrl != null && _overrideUrl!.isNotEmpty) {
      return _overrideUrl!;
    }

    final tidy = _sourceUrl;
    if (tidy.isEmpty) return '';

    if (ImageUrl.isApiMediaUrl(tidy)) return tidy;

    if (_attempt == 0) return ImageUrl.proxied(tidy);
    if (_attempt == 1) {
      final proxied = ImageUrl.proxied(tidy);
      final sep = proxied.contains('?') ? '&' : '?';
      return '$proxied${sep}_t=${DateTime.now().millisecondsSinceEpoch}';
    }
    if (_attempt >= 3) return tidy;
    return ImageUrl.proxied(tidy);
  }

  Future<void> _resolveViaApi() async {
    if (_resolving || !mounted) return;
    final tidy = _sourceUrl;
    if (tidy.isEmpty) return;

    _resolving = true;
    try {
      final resolved = await ImageResolveService.resolve(tidy);
      if (!mounted) return;
      if (resolved != null && resolved.isNotEmpty) {
        setState(() {
          _overrideUrl = resolved;
          _attempt = 0;
        });
        return;
      }
    } finally {
      _resolving = false;
    }

    if (!mounted) return;
    if (_attempt < 3) {
      setState(() => _attempt = 3);
    }
  }

  void _handleError() {
    if (!mounted) return;
    final tidy = _sourceUrl;

    if (_attempt == 0) {
      setState(() => _attempt = 1);
      return;
    }

    if (_attempt == 1 && !_resolving) {
      _resolveViaApi();
      return;
    }

    if (_attempt < 3 && tidy.isNotEmpty && !ImageUrl.needsResolution(tidy)) {
      setState(() => _attempt = 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayUrl = _urlForAttempt();
    final imageWidth = widget.fullWidth ? double.infinity : widget.width;
    final hasUrl = _sourceUrl.isNotEmpty;

    Widget child;
    if (!hasUrl || displayUrl.isEmpty) {
      child = _placeholder(imageWidth, icon: Icons.eco_rounded);
    } else {
      child = CachedNetworkImage(
        key: ValueKey('$displayUrl#$_attempt#${_overrideUrl ?? ''}'),
        imageUrl: displayUrl,
        width: imageWidth,
        height: widget.height,
        fit: widget.fit,
        fadeInDuration: const Duration(milliseconds: 280),
        fadeOutDuration: const Duration(milliseconds: 120),
        memCacheWidth: _cachePx(
          context,
          widget.width ?? (widget.fullWidth ? 600 : null),
        ),
        memCacheHeight: _cachePx(context, widget.height),
        placeholder: (context, url) => _placeholder(imageWidth, loading: true),
        errorWidget: (context, url, error) {
          if (_attempt < 3 || _resolving) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _handleError());
            return _placeholder(imageWidth, loading: true);
          }
          return _placeholder(imageWidth, icon: Icons.image_not_supported_outlined);
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.emerald50,
            AppColors.emerald100.withValues(alpha: 0.6),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.emerald700.withValues(alpha: 0.7),
              ),
            )
          : Icon(icon ?? Icons.eco_rounded, color: AppColors.emerald700, size: 28),
    );
  }
}
