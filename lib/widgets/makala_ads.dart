import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../config/ads_config.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
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
    return 60.0;
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
      // On platforms where AdMob is not supported (Web, Desktop),
      // we show the built-in botanical promotional banner so ads display reliably.
      if (mounted) setState(() => _phase = _BannerPhase.loaded);
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
      if (mounted) setState(() => _phase = _BannerPhase.loaded);
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

    final success = await _loadWithSize(AdSize.banner, gen);
    if (!mounted || gen != _generation) return;

    if (!success) {
      setState(() => _phase = _BannerPhase.failed);
      _scheduleRetry(gen);
    }
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
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    try {
      unawaited(banner.load());
      return await completer.future.timeout(
        const Duration(seconds: 20),
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
    // Moderate backoff: 8s, 16s, 30s
    final seconds = (_retry * 8).clamp(8, 30);
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

    return _ModernAdContainer(
      inline: widget.inline,
      height: _slotHeight,
      child: showNativeAd
          ? Center(
              child: SizedBox(
                width: banner.size.width.toDouble(),
                height: banner.size.height.toDouble(),
                child: AdWidget(ad: banner),
              ),
            )
          : const _BotanicalSponsorBanner(),
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
          color: AppColors.surfaceElevated,
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
        color: AppColors.surfaceElevated,
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

/// A clean, beautiful in-app fallback botanical sponsor ad for desktop/web or when
/// waiting for network fill. Promotes Dawa Asili education & herbal health tips.
class _BotanicalSponsorBanner extends StatelessWidget {
  const _BotanicalSponsorBanner();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final app = context.read<AppProvider>();
        app.navigate(AppScreen.askExpert);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.emerald50,
              AppColors.cream,
            ],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.forest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.spa_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Elimu ya Mimea & Dawa Asili',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forest,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Boresha afya yako kiasili kila siku na wataalamu wetu.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.gray600,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.emerald700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Fungua',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
