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
  double? _slotWidth;

  bool get _isBottom => widget.variant == _MakalaBannerVariant.bottomAnchored;

  double get _loadingHeight {
    if (_isBottom) return 60;
    return AdSize.mediumRectangle.height.toDouble();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width;
    if (_slotWidth != width && _state != _BannerLoadState.loaded) {
      _slotWidth = width;
      _scheduleLoad(width.truncate());
    }
  }

  void _scheduleLoad(int width) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadBanner(width);
    });
  }

  Future<void> _loadBanner(int width) async {
    final ads = context.read<AdsService>();
    final user = context.read<UserService>();
    if (!ads.shouldShowAds(user) || !AdsConfig.isSupportedPlatform) {
      _disposeBanner(resetState: true);
      return;
    }

    if (_state == _BannerLoadState.loading) return;

    _disposeBanner(resetState: false);
    if (!mounted) return;
    setState(() => _state = _BannerLoadState.loading);

    await ads.initialize();
    if (!mounted) return;

    final adSize = await _resolveAdSize(width);
    if (!mounted || adSize == null) {
      setState(() => _state = _BannerLoadState.failed);
      _retryLater(width);
      return;
    }

    final banner = BannerAd(
      adUnitId: AdsConfig.bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _banner = ad as BannerAd;
            _state = _BannerLoadState.loaded;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Makala banner failed (${widget.variant}): $error');
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _banner = null;
            _state = _BannerLoadState.failed;
          });
          _retryLater(width);
        },
      ),
    );

    _banner = banner;
    await banner.load();
  }

  Future<AdSize?> _resolveAdSize(int width) async {
    if (!_isBottom) return AdSize.mediumRectangle;

    final adaptive =
        await AdSize.getAnchoredAdaptiveBannerAdSize(Orientation.portrait, width);
    if (adaptive != null) return adaptive;

    final large =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (large != null) return large;

    return AdSize.banner;
  }

  void _retryLater(int width) {
    if (_retryCount >= 3) return;
    _retryCount++;
    Future<void>.delayed(Duration(seconds: 4 * _retryCount), () {
      if (!mounted || _state == _BannerLoadState.loaded) return;
      _loadBanner(width);
    });
  }

  void _disposeBanner({required bool resetState}) {
    _banner?.dispose();
    _banner = null;
    if (resetState && mounted) {
      setState(() => _state = _BannerLoadState.idle);
    }
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ads = context.watch<AdsService>();
    final user = context.watch<UserService>();
    if (!ads.shouldShowAds(user)) return const SizedBox.shrink();

    switch (_state) {
      case _BannerLoadState.idle:
      case _BannerLoadState.failed:
        return const SizedBox.shrink();
      case _BannerLoadState.loading:
        return _AdFrame(
          inline: !_isBottom,
          height: _loadingHeight,
          child: _AdLoadingPlaceholder(height: _loadingHeight),
        );
      case _BannerLoadState.loaded:
        final banner = _banner;
        if (banner == null) return const SizedBox.shrink();
        return _AdFrame(
          inline: !_isBottom,
          height: banner.size.height.toDouble(),
          child: Center(
            child: SizedBox(
              width: banner.size.width.toDouble(),
              height: banner.size.height.toDouble(),
              child: AdWidget(ad: banner),
            ),
          ),
        );
    }
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
                  'MATANGAZO',
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
        padding: const EdgeInsets.only(bottom: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.forest.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Inapakia tangazo…',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}
