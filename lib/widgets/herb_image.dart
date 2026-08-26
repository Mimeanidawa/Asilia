import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/category_visual.dart';
import '../utils/image_url.dart';

enum _LoadPhase { primary, bust, resolved, direct, failed }

/// Network image with spinner while loading and multi-step fallbacks.
class HerbImage extends StatefulWidget {
  const HerbImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.fit = BoxFit.cover,
    this.fullWidth = false,
    this.fallbackLabel = '',
    this.category,
    this.fitToImage = false,
  });

  final String url;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final bool fullWidth;
  final String fallbackLabel;
  final String? category;
  final bool fitToImage;

  @override
  State<HerbImage> createState() => _HerbImageState();
}

class _HerbImageState extends State<HerbImage> {
  _LoadPhase _phase = _LoadPhase.primary;
  String? _resolvedUrl;
  bool _resolving = false;
  bool _errorQueued = false;

  static bool get _usePlainNetwork {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();
    _warmResolveIfNeeded();
  }

  @override
  void didUpdateWidget(covariant HerbImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _phase = _LoadPhase.primary;
      _resolvedUrl = null;
      _resolving = false;
      _errorQueued = false;
      _warmResolveIfNeeded();
    }
  }

  String get _sourceUrl => ImageUrl.normalize(ImageUrl.tidy(widget.url));

  void _warmResolveIfNeeded() {
    final tidy = _sourceUrl;
    if (tidy.isEmpty) return;
    if (ImageUrl.isApiMediaUrl(tidy)) return;
    if (!ImageUrl.needsResolution(tidy)) return;
    _resolveViaApi(prefer: true);
  }

  String _urlForPhase() {
    final tidy = _sourceUrl;
    if (tidy.isEmpty) return '';

    // Our hosted media — always hit it directly (no proxy hop).
    if (ImageUrl.isApiMediaUrl(tidy) && !tidy.contains('/api/images/proxy')) {
      final media = ImageUrl.forceHttps(tidy);
      if (_phase == _LoadPhase.bust) {
        final sep = media.contains('?') ? '&' : '?';
        return '$media${sep}_t=${DateTime.now().millisecondsSinceEpoch}';
      }
      return media;
    }

    switch (_phase) {
      case _LoadPhase.primary:
        if (ImageUrl.looksLikeDirectImage(tidy)) return tidy;
        return ImageUrl.proxied(tidy);
      case _LoadPhase.bust:
        final primary = ImageUrl.looksLikeDirectImage(tidy)
            ? tidy
            : ImageUrl.proxied(tidy);
        final sep = primary.contains('?') ? '&' : '?';
        return '$primary${sep}_t=${DateTime.now().millisecondsSinceEpoch}';
      case _LoadPhase.resolved:
        return _resolvedUrl ?? ImageUrl.proxied(tidy);
      case _LoadPhase.direct:
        return tidy;
      case _LoadPhase.failed:
        return '';
    }
  }

  Future<void> _resolveViaApi({bool prefer = false}) async {
    if (_resolving || !mounted) return;
    final tidy = _sourceUrl;
    if (tidy.isEmpty) return;

    _resolving = true;
    if (mounted) setState(() {});
    try {
      final resolved = await ImageResolveService.resolve(tidy);
      if (!mounted) return;
      if (resolved != null && resolved.isNotEmpty) {
        if (prefer &&
            _phase != _LoadPhase.primary &&
            _phase != _LoadPhase.bust) {
          return;
        }
        setState(() {
          _resolvedUrl = resolved;
          _phase = _LoadPhase.resolved;
          _errorQueued = false;
        });
        return;
      }
    } finally {
      _resolving = false;
    }

    if (!mounted) return;
    if (!prefer) {
      setState(() {
        _phase = _LoadPhase.direct;
        _errorQueued = false;
      });
    } else {
      setState(() {});
    }
  }

  void _handleError() {
    if (!mounted || _phase == _LoadPhase.failed || _errorQueued) return;
    _errorQueued = true;

    switch (_phase) {
      case _LoadPhase.primary:
        setState(() {
          _phase = _LoadPhase.bust;
          _errorQueued = false;
        });
      case _LoadPhase.bust:
        _resolveViaApi();
      case _LoadPhase.resolved:
        setState(() {
          _phase = _LoadPhase.direct;
          _errorQueued = false;
        });
      case _LoadPhase.direct:
        setState(() {
          _phase = _LoadPhase.failed;
          _errorQueued = false;
        });
      case _LoadPhase.failed:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayUrl = _urlForPhase();
    final hasUrl = _sourceUrl.isNotEmpty && displayUrl.isNotEmpty;
    final failed = _phase == _LoadPhase.failed || _sourceUrl.isEmpty;
    final boxWidth = widget.fullWidth ? double.infinity : widget.width;
    final boxHeight = widget.height;

    Widget child;
    if (failed || !hasUrl) {
      child = SoftImageFallback(category: widget.category);
    } else {
      child = _photo(displayUrl, fit: widget.fit);
    }

    if (widget.fitToImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: hasUrl && !failed
            ? _photo(displayUrl, width: double.infinity, fit: BoxFit.fitWidth)
            : SizedBox(
                width: double.infinity,
                height: 180,
                child: failed
                    ? SoftImageFallback(category: widget.category)
                    : const ImageLoadingSpinner(),
              ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: boxWidth,
        height: boxHeight,
        child: child,
      ),
    );
  }

  Widget _photo(String url, {double? width, BoxFit? fit}) {
    final resolvedFit = fit ?? widget.fit;
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;

    // Only set cacheWidth (not both) so Flutter preserves aspect ratio while decoding.
    int? cacheW;
    if (widget.width != null && widget.width!.isFinite) {
      cacheW = (widget.width! * dpr).round().clamp(96, 1800);
    } else if (widget.fullWidth) {
      final screenW = MediaQuery.maybeOf(context)?.size.width ?? 400;
      cacheW = (screenW * dpr).round().clamp(96, 1920);
    }

    final headers = const <String, String>{
      'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
    };

    if (_usePlainNetwork) {
      return Image.network(
        url,
        key: ValueKey('$url#${_phase.name}'),
        width: width ?? (widget.fullWidth ? double.infinity : widget.width),
        height: widget.height,
        fit: resolvedFit,
        alignment: Alignment.center,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        cacheWidth: cacheW,
        headers: headers,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          final total = progress.expectedTotalBytes;
          final loaded = progress.cumulativeBytesLoaded;
          final value = (total != null && total > 0) ? loaded / total : null;
          return ImageLoadingSpinner(progress: value);
        },
        errorBuilder: (context, error, stack) {
          if (_phase != _LoadPhase.failed) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _handleError());
          }
          if (_phase == _LoadPhase.failed) {
            return SoftImageFallback(category: widget.category);
          }
          return const ImageLoadingSpinner();
        },
      );
    }

    return CachedNetworkImage(
      key: ValueKey('$url#${_phase.name}'),
      imageUrl: url,
      httpHeaders: headers,
      width: width ?? (widget.fullWidth ? double.infinity : widget.width),
      height: widget.height,
      fit: resolvedFit,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      memCacheWidth: cacheW,
      fadeInDuration: const Duration(milliseconds: 180),
      fadeOutDuration: const Duration(milliseconds: 40),
      placeholder: (context, url) => const ImageLoadingSpinner(),
      progressIndicatorBuilder: (context, url, progress) {
        return ImageLoadingSpinner(progress: progress.progress);
      },
      errorWidget: (context, url, error) {
        if (_phase != _LoadPhase.failed) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _handleError());
        }
        if (_phase == _LoadPhase.failed) {
          return SoftImageFallback(category: widget.category);
        }
        return const ImageLoadingSpinner();
      },
    );
  }
}

class ImageLoadingSpinner extends StatelessWidget {
  const ImageLoadingSpinner({super.key, this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.emerald50,
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            value: progress,
            color: AppColors.emerald700,
            backgroundColor: AppColors.emerald200.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class SoftImageFallback extends StatelessWidget {
  const SoftImageFallback({super.key, this.category});

  final String? category;

  @override
  Widget build(BuildContext context) {
    final icon = CategoryVisual.iconFor(category);
    return ColoredBox(
      color: AppColors.emerald50,
      child: Center(
        child: Icon(
          icon,
          size: 26,
          color: AppColors.emerald700.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
