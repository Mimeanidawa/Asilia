import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../config/ads_config.dart';
import '../services/ads_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';

/// Anchored banner for free users while reading makala.
class MakalaBannerAd extends StatelessWidget {
  const MakalaBannerAd({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MakalaBannerSlot(
      variant: _MakalaBannerVariant.bottomAnchored,
    );
  }
}

/// Mid-article banner (inline in the scroll body).
class MakalaInlineBannerAd extends StatelessWidget {
  const MakalaInlineBannerAd({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MakalaBannerSlot(variant: _MakalaBannerVariant.inlineRectangle);
  }
}

enum _MakalaBannerVariant { bottomAnchored, inlineRectangle }

enum _BannerLoadState { idle, loading, loaded, failed }

class _MakalaBannerSlot extends StatefulWidget {
  const _MakalaBannerSlot({required this.variant});

  final _MakalaBannerVariant variant;

  @override
  State<_MakalaBannerSlot> createState() => _MakalaBannerSlotState();
}

class _MakalaBannerSlotState extends State<_MakalaBannerSlot> {
  BannerAd? _banner;
  _BannerLoadState _state = _BannerLoadState.idle;
  int _retryCount = 0;
  int? _loadedWidth;
  int? _loadingWidth;
  int _loadGeneration = 0;
  bool _started = false;

  bool get _isBottom => widget.variant == _MakalaBannerVariant.bottomAnchored;

  double get _fallbackHeight {
    if (_isBottom) return AdSize.banner.height.toDouble();
    return AdSize.mediumRectangle.height.toDouble();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_started || !mounted) return;
    _started = true;

    final ads = context.read<AdsService>();
    final user = context.read<UserService>();
    if (!ads.shouldShowAds(user)) return;

    await ads.initialize();
    if (!mounted || !ads.isReady) return;

    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width > 0) _scheduleLoad(width);
  }

  void _scheduleLoad(int width) {
    if (_state == _BannerLoadState.loaded && _loadedWidth == width) return;
    if (_state == _BannerLoadState.loading && _loadingWidth == width) return;

    _loadingWidth = width;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadBanner(width);
    });
  }

  Future<void> _loadBanner(int width) async {
    final gen = ++_loadGeneration;

    final ads = context.read<AdsService>();
    final user = context.read<UserService>();
    if (!ads.shouldShowAds(user) || !AdsConfig.isSupportedPlatform) {
      if (gen == _loadGeneration) _disposeBanner();
      return;
    }

    _banner?.dispose();
    _banner = null;
    if (!mounted || gen != _loadGeneration) return;
    setState(() {
      _state = _BannerLoadState.loading;
      _loadingWidth = width;
    });

    await ads.initialize();
    if (!mounted || gen != _loadGeneration || !ads.isReady) return;

    final adSize = _isBottom ? await _resolveAdaptiveSize(width) : AdSize.mediumRectangle;
    if (!mounted || gen != _loadGeneration) return;

    final banner = BannerAd(
      adUnitId: AdsConfig.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || gen != _loadGeneration) {
            ad.dispose();
            return;
          }
          setState(() {
            _banner = ad as BannerAd;
            _state = _BannerLoadState.loaded;
            _loadedWidth = width;
            _loadingWidth = null;
            _retryCount = 0;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Makala banner failed (${widget.variant}): $error');
          ad.dispose();
          if (!mounted || gen != _loadGeneration) return;
          setState(() {
            _banner = null;
            _state = _BannerLoadState.failed;
            _loadingWidth = null;
          });
          _retryLater(width, gen);
        },
      ),
    );

    _banner = banner;
    try {
      await banner.load();
    } catch (e) {
      debugPrint('Makala banner load error: $e');
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _banner = null;
        _state = _BannerLoadState.failed;
        _loadingWidth = null;
      });
      _retryLater(width, gen);
    }
  }

  Future<AdSize> _resolveAdaptiveSize(int width) async {
    final safeWidth = width.clamp(320, 728);
    final adaptive = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      safeWidth,
    );
    if (adaptive != null) return adaptive;

    final large = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(safeWidth);
    if (large != null) return large;

    return AdSize.banner;
  }

  void _retryLater(int width, int gen) {
    _retryCount++;
    final delay = Duration(seconds: (3 * _retryCount).clamp(3, 20));
    Future<void>.delayed(delay, () {
      if (!mounted || gen != _loadGeneration) return;
      if (_state == _BannerLoadState.loaded) return;
      _scheduleLoad(width);
    });
  }

  void _disposeBanner() {
    _loadGeneration++;
    _banner?.dispose();
    _banner = null;
    _loadedWidth = null;
    _loadingWidth = null;
    if (mounted) setState(() => _state = _BannerLoadState.idle);
  }

  @override
  void dispose() {
    _loadGeneration++;
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserService>();
    final ads = context.read<AdsService>();
    if (!ads.shouldShowAds(user)) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.truncate();
        if (width > 0 &&
            _loadedWidth != width &&
            _state != _BannerLoadState.loading &&
            ads.isReady) {
          _scheduleLoad(width);
        }

        final banner = _banner;
        final height = banner != null
            ? banner.size.height.toDouble()
            : _fallbackHeight;

        final showAd = _state == _BannerLoadState.loaded && banner != null;
        final showSpinner =
            _state == _BannerLoadState.loading || _state == _BannerLoadState.idle;

        return _AdFrame(
          inline: !_isBottom,
          height: height,
          child: showAd
              ? Center(
                  child: SizedBox(
                    width: banner.size.width.toDouble(),
                    height: banner.size.height.toDouble(),
                    child: AdWidget(ad: banner),
                  ),
                )
              : showSpinner
                  ? _AdLoadingPlaceholder(height: height)
                  : _AdEmptyPlaceholder(height: height),
        );
      },
    );
  }
}

class _AdFrame extends StatelessWidget {
  const _AdFrame({
    required this.inline,
    required this.height,
    required this.child,
  });

  final bool inline;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final frame = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.emerald50,
        border: Border(
          top: inline
              ? BorderSide.none
              : BorderSide(color: AppColors.forest.withValues(alpha: 0.08)),
          bottom: BorderSide(color: AppColors.forest.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, inline ? 0 : 8, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.ads_click_rounded,
                  size: 12,
                  color: AppColors.gray400,
                ),
                const SizedBox(width: 4),
                Text(
                  'AD',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gray400,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(inline ? 12 : 0),
              child: ColoredBox(
                color: AppColors.cream,
                child: child,
              ),
            ),
          ),
          if (!inline) const SizedBox(height: 4),
        ],
      ),
    );

    if (inline) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: frame,
      );
    }
    return frame;
  }
}

class _AdLoadingPlaceholder extends StatelessWidget {
  const _AdLoadingPlaceholder({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      color: AppColors.cream,
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.forest.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _AdEmptyPlaceholder extends StatelessWidget {
  const _AdEmptyPlaceholder({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      color: AppColors.cream,
      child: Icon(
        Icons.image_outlined,
        size: 28,
        color: AppColors.forest.withValues(alpha: 0.15),
      ),
    );
  }
}
