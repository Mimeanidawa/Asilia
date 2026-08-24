import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../utils/image_url.dart';

/// Network image that loads via the Asilia API proxy/media cache.
class UrlImage extends StatefulWidget {
  const UrlImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.showBorder = false,
  });

  final String url;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final bool showBorder;

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

  String _displayUrl() {
    final tidy = ImageUrl.tidy(widget.url);
    if (tidy.isEmpty) return '';
    if (ImageUrl.isApiMediaUrl(tidy)) return tidy;
    if (_attempt == 0) return ImageUrl.display(tidy);
    final proxied = ImageUrl.display(tidy);
    return '$proxied&_retry=$_attempt';
  }

  int? _memCacheSize(double? logicalSize) {
    if (logicalSize == null || !logicalSize.isFinite) return null;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return (logicalSize * ratio).round().clamp(64, 2048);
  }

  @override
  Widget build(BuildContext context) {
    final displayUrl = _displayUrl();
    final w = widget.width;
    final h = widget.height;

    Widget child;
    if (displayUrl.isEmpty) {
      child = _placeholder(icon: Icons.image_not_supported_rounded);
    } else {
      child = CachedNetworkImage(
        key: ValueKey('$displayUrl#$_attempt'),
        imageUrl: displayUrl,
        width: w,
        height: h,
        fit: widget.fit,
        memCacheWidth: _memCacheSize(w),
        memCacheHeight: _memCacheSize(h),
        fadeInDuration: const Duration(milliseconds: 220),
        fadeOutDuration: const Duration(milliseconds: 120),
        placeholder: (context, url) => _placeholder(loading: true),
        errorWidget: (context, url, error) {
          if (_attempt < 2) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _attempt += 1);
            });
            return _placeholder(loading: true);
          }
          return _placeholder(icon: Icons.broken_image_outlined);
        },
      );
    }

    final radius = BorderRadius.circular(widget.borderRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: widget.showBorder
            ? Border.all(color: AdminColors.textDim.withValues(alpha: 0.12))
            : null,
        boxShadow: widget.showBorder
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: child,
      ),
    );
  }

  Widget _placeholder({bool loading = false, IconData? icon}) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AdminColors.card,
            AdminColors.card.withValues(alpha: 0.65),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: AdminColors.emerald,
                strokeWidth: 2,
              ),
            )
          : Icon(
              icon ?? Icons.image_outlined,
              color: AdminColors.textDim,
              size: 28,
            ),
    );
  }
}
