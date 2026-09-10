import 'dart:async';

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
    return const _MakalaBannerSlot(inline: false);
  }
}

/// Mid-article banner (inline in the scroll body).
class MakalaInlineBannerAd extends StatelessWidget {
  const MakalaInlineBannerAd({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MakalaBannerSlot(inline: true);
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
    // Standard banner is fastest + highest fill. Large only as visual reserve.
    return AdSize.banner.height.toDouble();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Kick again if user/ads eligibility flips after first frame.
    if (!_loadStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
    }
  }

  Future<void> _ensureLoaded() async {
    if (!mounted) return;

    final ads = context.read<AdsService>();
    final user = context.read<UserService>();
    if (!ads.shouldShowAds(user) || !AdsConfig.isSupportedPlatform) {
      _clearBanner();
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

    if (!ads.shouldShowAds(user) || !AdsConfig.isSupportedPlatform) {
      _clearBanner();
      return;
    }

    setState(() => _phase = _BannerPhase.loading);

    // Wait for SDK (shared future) — do not invent a second init path.
    await ads.initialize();
    if (!mounted || gen != _generation) return;
    if (!ads.isReady) {
      setState(() => _phase = _BannerPhase.failed);
      _scheduleRetry(gen);
      return;
    }

    // Dispose previous only after we know we will replace it.
    final previous = _banner;
    _banner = null;
    previous?.dispose();

    // Prefer standard banner first (fast + reliable fill), then large banner.
    final sizes = <AdSize>[
      AdSize.banner,
      AdSize.largeBanner,
      if (widget.inline) AdSize.mediumRectangle,
    ];

    for (final size in sizes) {
      if (!mounted || gen != _generation) return;
      final loaded = await _loadWithSize(size, gen);
      if (loaded) return;
    }

    if (!mounted || gen != _generation) return;
    setState(() => _phase = _BannerPhase.failed);
    _scheduleRetry(gen);
  }

  Future<bool> _loadWithSize(AdSize size, int gen) async {
    final completer = Completer<bool>();

    final banner = BannerAd(
      adUnitId: AdsConfig.bannerAdUnitId,
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
          debugPrint(
            'Banner failed (${widget.inline ? 'inline' : 'bottom'} '
            '${size.width}x${size.height}): $error',
          );
          ad.dispose();
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    try {
      // Kick the request; completion is signaled by the listener.
      unawaited(banner.load());
      return await completer.future.timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          banner.dispose();
          return false;
        },
      );
    } catch (e) {
      debugPrint('Banner load threw: $e');
      banner.dispose();
      if (!completer.isCompleted) completer.complete(false);
      return false;
    }
  }

  void _scheduleRetry(int gen) {
    _retryTimer?.cancel();
    _retry++;
    // Fast first retries: 1s, 2s, 4s, then up to 12s.
    final seconds = (1 << (_retry - 1).clamp(0, 3)).clamp(1, 12);
    _retryTimer = Timer(Duration(seconds: seconds), () {
      if (!mounted || gen != _generation) return;
      if (_phase == _BannerPhase.loaded) return;
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

    // If ads just became ready and we have not loaded yet, kick off.
    if (ads.isReady &&
        _phase != _BannerPhase.loaded &&
        _phase != _BannerPhase.loading &&
        !_loadStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
    }

    final banner = _banner;
    final height = _slotHeight;
    final showAd = _phase == _BannerPhase.loaded && banner != null;

    return _AdFrame(
      inline: widget.inline,
      height: height,
      child: showAd
          ? KeyedSubtree(
              key: ValueKey('ad-${banner.hashCode}-${banner.size.height}'),
              child: Center(
                child: SizedBox(
                  width: banner.size.width.toDouble(),
                  height: banner.size.height.toDouble(),
                  child: AdWidget(ad: banner),
                ),
              ),
            )
          : _phase == _BannerPhase.failed
              ? _AdRetryPlaceholder(
                  height: height,
                  onRetry: () {
                    _retry = 0;
                    unawaited(_load());
                  },
                )
              : _AdLoadingPlaceholder(height: height),
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
    final frame = ColoredBox(
      color: AppColors.emerald50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!inline)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.ads_click_rounded,
                    size: 11,
                    color: AppColors.gray400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AD',
                    style: TextStyle(
                      fontSize: 9,
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
            child: ColoredBox(
              color: AppColors.surfaceElevated,
              child: child,
            ),
          ),
          if (!inline) const SizedBox(height: 2),
        ],
      ),
    );

    if (!inline) {
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.forest.withValues(alpha: 0.08)),
          ),
        ),
        child: frame,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.forest.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: frame,
        ),
      ),
    );
  }
}

class _AdLoadingPlaceholder extends StatelessWidget {
  const _AdLoadingPlaceholder({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.forest.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _AdRetryPlaceholder extends StatelessWidget {
  const _AdRetryPlaceholder({required this.height, required this.onRetry});

  final double height;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Jaribu tena'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.emerald800,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
