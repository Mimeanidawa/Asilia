import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/admin_colors.dart';
import '../utils/image_url.dart';

/// Network image that resolves share-page URLs (ibb.co / postimg) like the main app.
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
  String? _resolved;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _maybeResolve();
  }

  @override
  void didUpdateWidget(covariant UrlImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _resolved = null;
      _resolving = false;
      _maybeResolve();
    }
  }

  void _maybeResolve() {
    final tidy = ImageUrl.tidy(widget.url);
    if (tidy.isEmpty || !ImageUrl.needsResolution(tidy)) return;
    _resolving = true;
    ImageUrl.resolve(tidy).then((resolved) {
      if (!mounted || ImageUrl.tidy(widget.url) != tidy) return;
      setState(() {
        _resolved = resolved;
        _resolving = false;
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _resolving = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tidy = ImageUrl.tidy(widget.url);
    final displayUrl = _resolved ?? tidy;

    Widget child;
    if (displayUrl.isEmpty) {
      child = _placeholder(icon: Icons.image_not_supported_rounded);
    } else if (_resolving && _resolved == null) {
      child = _placeholder(loading: true);
    } else {
      child = CachedNetworkImage(
        imageUrl: displayUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        fadeInDuration: const Duration(milliseconds: 120),
        placeholder: (context, url) => _placeholder(loading: true),
        errorWidget: (context, url, error) =>
            _placeholder(icon: Icons.image_not_supported_rounded),
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
