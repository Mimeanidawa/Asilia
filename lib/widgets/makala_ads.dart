import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../config/ads_config.dart';
import '../services/ads_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';

/// Anchored banner for free users while reading makala.
class MakalaBannerAd extends StatefulWidget {
  const MakalaBannerAd({super.key});

  @override
  State<MakalaBannerAd> createState() => _MakalaBannerAdState();
}

class _MakalaBannerAdState extends State<MakalaBannerAd> {
  BannerAd? _banner;
  bool _loaded = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _ensureBanner();
    }
  }

  Future<void> _ensureBanner() async {
    final ads = context.read<AdsService>();
    final user = context.read<UserService>();
    if (!ads.shouldShowAds(user) || !AdsConfig.isSupportedPlatform) {
      _disposeBanner();
      return;
    }
    if (_banner != null) return;

    await ads.initialize();
    if (!mounted) return;

    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (!mounted || size == null) return;

    final banner = BannerAd(
      adUnitId: AdsConfig.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _banner = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _banner = banner;
    await banner.load();
  }

  void _disposeBanner() {
    _banner?.dispose();
    _banner = null;
    if (_loaded && mounted) {
      setState(() => _loaded = false);
    } else {
      _loaded = false;
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
    if (!ads.shouldShowAds(user) || !_loaded || _banner == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: AppColors.surfaceElevated,
      elevation: 6,
      shadowColor: AppColors.forest.withValues(alpha: 0.12),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: _banner!.size.width.toDouble(),
          height: _banner!.size.height.toDouble(),
          child: AdWidget(ad: _banner!),
        ),
      ),
    );
  }
}

/// Mid-article banner (inline in the scroll body).
class MakalaInlineBannerAd extends StatefulWidget {
  const MakalaInlineBannerAd({super.key});

  @override
  State<MakalaInlineBannerAd> createState() => _MakalaInlineBannerAdState();
}

class _MakalaInlineBannerAdState extends State<MakalaInlineBannerAd> {
  BannerAd? _banner;
  bool _loaded = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    final ads = context.read<AdsService>();
    final user = context.read<UserService>();
    if (!ads.shouldShowAds(user) || !AdsConfig.isSupportedPlatform) return;
    if (_banner != null) return;

    await ads.initialize();
    if (!mounted) return;

    final banner = BannerAd(
      adUnitId: AdsConfig.bannerAdUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Inline banner failed: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _banner = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _banner = banner;
    await banner.load();
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
    if (!ads.shouldShowAds(user) || !_loaded || _banner == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Text(
              'Matangazo',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.gray400,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: _banner!.size.width.toDouble(),
              height: _banner!.size.height.toDouble(),
              child: AdWidget(ad: _banner!),
            ),
          ],
        ),
      ),
    );
  }
}
