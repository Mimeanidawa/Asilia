import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../config/ads_config.dart';
import '../services/ads_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';

/// Anchored bottom banner for free users while reading makala or browsing.
class MakalaBannerAd extends StatelessWidget {
  const MakalaBannerAd({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MakalaBannerSlot(inline: false);
  }
}

/// Mid-article / mid-lesson inline banner.
class MakalaInlineBannerAd extends StatelessWidget {
  const MakalaInlineBannerAd({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MakalaBannerSlot(inline: true);
  }
}

/// Feed card banner ad that sits naturally within post lists / home screen.
///
/// Reserves its space while the first ad request is in flight so the feed
/// does not jump, and collapses completely if the ad cannot be served.
class HomeFeedBannerAd extends StatelessWidget {
  const HomeFeedBannerAd({
    super.key,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  /// Outer spacing. Pass horizontal values to align with page gutters.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserService>();
    final ads = context.watch<AdsService>();
    if (!ads.shouldShowAds(user)) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: const _MakalaBannerSlot(inline: true, feed: true),
    );
  }
}

enum _BannerPhase { idle, loading, loaded, failed }

class _MakalaBannerSlot extends StatefulWidget {
  const _MakalaBannerSlot({required this.inline, this.feed = false});

  final bool inline;

  /// Feed placement: tighter card, reserved space while loading.
  final bool feed;

  @override
  State<_MakalaBannerSlot> createState() => _MakalaBannerSlotState();
}

class _MakalaBannerSlotState extends State<_MakalaBannerSlot>
    with AutomaticKeepAliveClientMixin {
  BannerAd? _banner;
  _BannerPhase _phase = _BannerPhase.idle;
  int _retry = 0;
  int _generation = 0;
  bool _loadStarted = false;
  bool _everFailed = false;
  Timer? _retryTimer;
  double? _layoutWidth;
  int? _requestedWidth;

  /// Inline slots sit inside a card with 8px padding plus a 1px border.
  static const double _inlineCardPadding = 9;

  @override
  bool get wantKeepAlive => true;

  double get _slotHeight {
    final banner = _banner;
    if (banner != null) return banner.size.height.toDouble();
    return widget.inline ? 50.0 : 50.0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
    }
  }

  Future<void> _ensureLoaded() async {
    if (!mounted) return;

    final ads = context.read<AdsService>();
    final user = context.read<UserService>();
    if (!ads.shouldShowAds(user)) {
      _clearBanner();
      return;
    }

    if (!AdsConfig.isSupportedPlatform) {
      return;
    }

    if (_phase == _BannerPhase.loaded && _banner != null) return;
    if (_phase == _BannerPhase.loading) return;
    if (_targetAdWidth() == null) return;

    _loadStarted = true;
    await _load();
  }

  int? _targetAdWidth() {
    final layoutWidth = _layoutWidth;
    if (layoutWidth == null) return null;
    final width = widget.inline
        ? layoutWidth - _inlineCardPadding * 2
        : layoutWidth;
    final truncated = width.truncate();
    return truncated > 0 ? truncated : null;
  }

  void _onLayoutWidth(double maxWidth) {
    final width = maxWidth.isFinite ? maxWidth : MediaQuery.sizeOf(context).width;
    if (width <= 0 || width == _layoutWidth) return;
    _layoutWidth = width;

    final target = _targetAdWidth();
    final requested = _requestedWidth;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final needsResize = requested != null &&
          target != null &&
          (target - requested).abs() >= 8;
      if (needsResize) {
        unawaited(_load());
      } else if (!_loadStarted) {
        unawaited(_ensureLoaded());
      }
    });
  }

  Future<void> _load() async {
    final gen = ++_generation;
    final ads = context.read<AdsService>();
    final user = context.read<UserService>();

    if (!ads.shouldShowAds(user)) {
      _clearBanner();
      return;
    }

    if (!AdsConfig.isSupportedPlatform) {
      return;
    }

    setState(() => _phase = _BannerPhase.loading);

    try {
      await ads.initialize();
    } catch (_) {}

    if (!mounted || gen != _generation) return;

    if (!ads.isReady) {
      setState(() {
        _phase = _BannerPhase.failed;
        _everFailed = true;
      });
      _scheduleRetry(gen);
      return;
    }

    final previous = _banner;
    _banner = null;
    previous?.dispose();

    bool success = false;
    final adUnitId = AdsConfig.bannerAdUnitId;
    final adWidth = _targetAdWidth();
    if (adWidth == null) {
      setState(() => _phase = _BannerPhase.idle);
      _loadStarted = false;
      return;
    }
    _requestedWidth = adWidth;

    try {
      final adaptiveSize = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(adWidth);
      if (adaptiveSize != null && mounted && gen == _generation) {
        success = await _loadWithSize(
          adaptiveSize,
          gen,
          adUnitId: adUnitId,
        );
      }
    } catch (e) {
      debugPrint('Adaptive banner size error: $e');
    }

    // Standard 320x50 fallback, only when it fits the slot.
    if (!success &&
        adWidth >= AdSize.banner.width &&
        mounted &&
        gen == _generation) {
      success = await _loadWithSize(
        AdSize.banner,
        gen,
        adUnitId: adUnitId,
      );
    }

    if (!mounted || gen != _generation) return;

    if (!success) {
      setState(() {
        _phase = _BannerPhase.failed;
        _everFailed = true;
      });
      _scheduleRetry(gen);
    }
  }

  Future<bool> _loadWithSize(
    AdSize size,
    int gen, {
    required String adUnitId,
  }) async {
    final completer = Completer<bool>();

    final banner = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || gen != _generation) {
            ad.dispose();
            if (!completer.isCompleted) completer.complete(false);
            return;
          }
          setState(() {
            _banner = ad as BannerAd;
            _phase = _BannerPhase.loaded;
            _retry = 0;
          });
          if (!completer.isCompleted) completer.complete(true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load ($adUnitId, ${size.width}x${size.height}): $error');
          ad.dispose();
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    try {
      unawaited(banner.load());
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          banner.dispose();
          return false;
        },
      );
    } catch (e) {
      debugPrint('BannerAd load error: $e');
      banner.dispose();
      if (!completer.isCompleted) completer.complete(false);
      return false;
    }
  }

  void _scheduleRetry(int gen) {
    _retryTimer?.cancel();
    _retry++;
    final seconds = (_retry * 5).clamp(4, 20);
    _retryTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted || gen != _generation) return;
      if (_phase == _BannerPhase.loaded && _banner != null) return;
      unawaited(_load());
    });
  }

  void _clearBanner() {
    _generation++;
    _retryTimer?.cancel();
    _banner?.dispose();
    _banner = null;
    _loadStarted = false;
    if (mounted) setState(() => _phase = _BannerPhase.idle);
  }

  @override
  void dispose() {
    _generation++;
    _retryTimer?.cancel();
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = context.watch<UserService>();
    final ads = context.watch<AdsService>();

    if (!ads.shouldShowAds(user)) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _onLayoutWidth(constraints.maxWidth);
        return _buildBanner();
      },
    );
  }

  Widget _buildBanner() {
    final banner = _banner;
    final showNativeAd = AdsConfig.isSupportedPlatform &&
        _phase == _BannerPhase.loaded &&
        banner != null;

    if (!showNativeAd) {
      final waiting = widget.feed &&
          !_everFailed &&
          AdsConfig.isSupportedPlatform &&
          (_phase == _BannerPhase.idle || _phase == _BannerPhase.loading);
      if (waiting) {
        return _ModernAdContainer(
          inline: true,
          feed: true,
          height: _slotHeight,
          child: SizedBox(height: _slotHeight, width: double.infinity),
        );
      }
      return const SizedBox.shrink();
    }

    return _ModernAdContainer(
      inline: widget.inline,
      feed: widget.feed,
      height: _slotHeight,
      child: Center(
        child: SizedBox(
          width: banner.size.width.toDouble(),
          height: banner.size.height.toDouble(),
          child: AdWidget(
            key: ObjectKey(banner),
            ad: banner,
          ),
        ),
      ),
    );
  }
}

class _ModernAdContainer extends StatelessWidget {
  const _ModernAdContainer({
    required this.inline,
    required this.height,
    required this.child,
    this.feed = false,
  });

  final bool inline;
  final bool feed;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!inline) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.forest.withValues(alpha: 0.08)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.forest.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTangazoPill(),
              const SizedBox(height: 2),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: height),
                child: child,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: feed ? double.infinity : null,
      margin: feed ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.07)),
        boxShadow: AppColors.elevationSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox.shrink(),
              _buildTangazoPill(),
            ],
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildTangazoPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.emerald50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.emerald200.withValues(alpha: 0.6)),
      ),
      child: const Text(
        'TANGAZO',
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          color: AppColors.emerald800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
