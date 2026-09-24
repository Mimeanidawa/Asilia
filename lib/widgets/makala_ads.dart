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
class HomeFeedBannerAd extends StatelessWidget {
  const HomeFeedBannerAd({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserService>();
    final ads = context.watch<AdsService>();
    if (!ads.shouldShowAds(user)) return const SizedBox.shrink();

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: _MakalaBannerSlot(inline: true),
    );
  }
}

enum _BannerPhase { idle, loading, loaded, failed }

class _MakalaBannerSlot extends StatefulWidget {
  const _MakalaBannerSlot({required this.inline});

  final bool inline;

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
  Timer? _retryTimer;

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

    _loadStarted = true;
    await _load();
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
      setState(() => _phase = _BannerPhase.failed);
      _scheduleRetry(gen);
      return;
    }

    final previous = _banner;
    _banner = null;
    previous?.dispose();

    bool success = false;
    final adUnitId = AdsConfig.bannerAdUnitId;

    if (mounted) {
      try {
        final screenWidth = MediaQuery.sizeOf(context).width.truncate();
        if (screenWidth > 0) {
          final adWidth = widget.inline ? (screenWidth - 32).clamp(300, 728) : screenWidth;
          final adaptiveSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(adWidth);
          if (adaptiveSize != null && mounted && gen == _generation) {
            success = await _loadWithSize(
              adaptiveSize,
              gen,
              adUnitId: adUnitId,
            );
          }
        }
      } catch (e) {
        debugPrint('Adaptive banner size error: $e');
      }
    }

    // If adaptive banner did not fill, fallback to standard AdSize.banner (320x50)
    if (!success && mounted && gen == _generation) {
      success = await _loadWithSize(
        AdSize.banner,
        gen,
        adUnitId: adUnitId,
      );
    }

    if (!mounted || gen != _generation) return;

    if (!success) {
      setState(() => _phase = _BannerPhase.failed);
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

    final banner = _banner;
    final showNativeAd = AdsConfig.isSupportedPlatform &&
        _phase == _BannerPhase.loaded &&
        banner != null;

    if (!showNativeAd) {
      return const SizedBox.shrink();
    }

    return _ModernAdContainer(
      inline: widget.inline,
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
  });

  final bool inline;
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
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.08)),
        boxShadow: AppColors.elevationSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
