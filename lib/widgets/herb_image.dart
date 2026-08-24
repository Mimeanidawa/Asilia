import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/category_visual.dart';
import '../utils/image_url.dart';

enum _LoadPhase { proxy, proxyBust, resolved, direct, failed }

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

  /// Size to the photo itself so article images are shown in full, uncropped.
  final bool fitToImage;

  @override
  State<HerbImage> createState() => _HerbImageState();
}

class _HerbImageState extends State<HerbImage> {
  _LoadPhase _phase = _LoadPhase.proxy;
  String? _resolvedUrl;
  bool _resolving = false;

  static bool get _usePlainNetwork {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();
    _prefetchResolve();
  }

  @override
  void didUpdateWidget(covariant HerbImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _phase = _LoadPhase.proxy;
      _resolvedUrl = null;
      _resolving = false;
      _prefetchResolve();
    }
  }

  String get _sourceUrl => ImageUrl.normalize(ImageUrl.tidy(widget.url));

  String _urlForPhase() {
    final tidy = _sourceUrl;
    if (tidy.isEmpty) return '';

    if (ImageUrl.isApiMediaUrl(tidy) && !tidy.contains('/api/images/proxy')) {
      final media = ImageUrl.forceHttps(tidy);
      if (_phase == _LoadPhase.proxyBust) {
        final sep = media.contains('?') ? '&' : '?';
        return '$media${sep}_t=${DateTime.now().millisecondsSinceEpoch}';
      }
      return media;
    }

    switch (_phase) {
      case _LoadPhase.proxy:
        return ImageUrl.proxied(tidy);
      case _LoadPhase.proxyBust:
        final proxied = ImageUrl.proxied(tidy);
        final sep = proxied.contains('?') ? '&' : '?';
        return '$proxied${sep}_t=${DateTime.now().millisecondsSinceEpoch}';
      case _LoadPhase.resolved:
        return _resolvedUrl ?? ImageUrl.proxied(tidy);
      case _LoadPhase.direct:
        return tidy;
      case _LoadPhase.failed:
        return '';
    }
  }

  void _prefetchResolve() {
    final tidy = _sourceUrl;
    if (tidy.isEmpty) return;
    if (ImageUrl.isApiMediaUrl(tidy) && !tidy.contains('/api/images/proxy')) return;
    _resolveViaApi(preferIfBetter: true);
  }

  Future<void> _resolveViaApi({bool preferIfBetter = false}) async {
    if (_resolving || !mounted) return;
    final tidy = _sourceUrl;
    if (tidy.isEmpty) return;

    _resolving = true;
    try {
      final resolved = await ImageResolveService.resolve(tidy);
      if (!mounted) return;
      if (resolved != null &&
          resolved.isNotEmpty &&
          resolved != ImageUrl.proxied(tidy)) {
        if (preferIfBetter &&
            _phase != _LoadPhase.proxy &&
            _phase != _LoadPhase.proxyBust) {
          return;
        }
        setState(() {
          _resolvedUrl = resolved;
          _phase = _LoadPhase.resolved;
        });
        return;
      }
    } finally {
      _resolving = false;
    }

    if (!mounted || preferIfBetter) return;
    setState(() => _phase = _LoadPhase.direct);
  }

  void _handleError() {
    if (!mounted || _phase == _LoadPhase.failed) return;

    switch (_phase) {
      case _LoadPhase.proxy:
        setState(() => _phase = _LoadPhase.proxyBust);
      case _LoadPhase.proxyBust:
        if (!_resolving) _resolveViaApi();
      case _LoadPhase.resolved:
        setState(() => _phase = _LoadPhase.direct);
      case _LoadPhase.direct:
        setState(() => _phase = _LoadPhase.failed);
      case _LoadPhase.failed:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayUrl = _urlForPhase();
    final hasUrl = _sourceUrl.isNotEmpty && displayUrl.isNotEmpty;
    final failed = _phase == _LoadPhase.failed;
    final boxWidth = widget.fullWidth ? double.infinity : widget.width;
    final boxHeight = widget.height;

    if (widget.fitToImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: hasUrl && !failed
            ? _photo(
                displayUrl,
                width: double.infinity,
                fit: BoxFit.fitWidth,
              )
            : SizedBox(
                width: double.infinity,
                height: 180,
                child: BrandedCover(
                  label: widget.fallbackLabel,
                  category: widget.category,
                ),
              ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: boxWidth,
        height: boxHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BrandedCover(
              label: widget.fallbackLabel,
              category: widget.category,
            ),
            if (hasUrl && !failed)
              Positioned.fill(child: _photo(displayUrl, fit: widget.fit)),
          ],
        ),
      ),
    );
  }

  Widget _photo(String url, {double? width, BoxFit? fit}) {
    final resolvedFit = fit ?? widget.fit;
    if (_usePlainNetwork) {
      return Image.network(
        url,
        key: ValueKey('$url#${_phase.name}'),
        width: width,
        fit: resolvedFit,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox.shrink();
        },
        errorBuilder: (context, error, stack) {
          if (_phase != _LoadPhase.failed) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _handleError());
          }
          return const SizedBox.shrink();
        },
      );
    }

    return CachedNetworkImage(
      key: ValueKey('$url#${_phase.name}'),
      imageUrl: url,
      width: width,
      fit: resolvedFit,
      filterQuality: FilterQuality.high,
      fadeInDuration: const Duration(milliseconds: 380),
      fadeOutDuration: const Duration(milliseconds: 80),
      placeholder: (context, url) => const SizedBox.shrink(),
      errorWidget: (context, url, error) {
        if (_phase != _LoadPhase.failed) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _handleError());
        }
        return const SizedBox.shrink();
      },
    );
  }
}
