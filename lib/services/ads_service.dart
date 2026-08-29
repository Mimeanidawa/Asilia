import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ads_config.dart';
import 'user_service.dart';

enum _FullscreenAdKind { interstitial, rewarded }

/// Central AdMob helper — banner, interstitial, and rewarded ads.
class AdsService extends ChangeNotifier {
  final Random _random = Random();

  bool _initialized = false;
  bool _initializing = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;
  int _interstitialBackoff = 4;
  int _rewardedBackoff = 4;

  bool get isReady => _initialized && AdsConfig.isSupportedPlatform;
  bool get isInitializing => _initializing;

  bool shouldShowAds(UserService user) {
    if (!AdsConfig.isSupportedPlatform) return false;
    if (user.isLoggedIn && user.user?.isPremiumActive == true) return false;
    return true;
  }

  Future<void> initialize() async {
    if (!AdsConfig.isSupportedPlatform) return;
    if (_initialized || _initializing) return;
    _initializing = true;
    notifyListeners();
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      unawaited(preload());
    } catch (e) {
      debugPrint('AdsService init failed: $e');
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  Future<void> preload() async {
    if (!_initialized) await initialize();
    if (!_initialized) return;
    _loadInterstitial();
    _loadRewarded();
  }

  void _loadInterstitial() {
    if (_loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdsConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
          _interstitialBackoff = 4;
          ad.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed: $error');
          _interstitial = null;
          _loadingInterstitial = false;
          _scheduleInterstitialRetry();
        },
      ),
    );
  }

  void _loadRewarded() {
    if (_loadingRewarded || _rewarded != null) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: AdsConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
          _rewardedBackoff = 4;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded failed: $error');
          _rewarded = null;
          _loadingRewarded = false;
          _scheduleRewardedRetry();
        },
      ),
    );
  }

  void _scheduleInterstitialRetry() {
    final delay = Duration(seconds: _interstitialBackoff);
    _interstitialBackoff = (_interstitialBackoff + 2).clamp(4, 30);
    Future<void>.delayed(delay, () {
      if (_interstitial == null && !_loadingInterstitial) _loadInterstitial();
    });
  }

  void _scheduleRewardedRetry() {
    final delay = Duration(seconds: _rewardedBackoff);
    _rewardedBackoff = (_rewardedBackoff + 2).clamp(4, 30);
    Future<void>.delayed(delay, () {
      if (_rewarded == null && !_loadingRewarded) _loadRewarded();
    });
  }

  bool get hasInterstitial => _interstitial != null;
  bool get hasRewarded => _rewarded != null;
  bool get hasFullscreenAd => hasInterstitial || hasRewarded;
  bool get isLoadingFullscreen =>
      _loadingInterstitial || _loadingRewarded || _initializing;

  _FullscreenAdKind _pickRandomKind() {
    final hasI = _interstitial != null;
    final hasR = _rewarded != null;
    if (hasI && hasR) {
      return _random.nextBool()
          ? _FullscreenAdKind.interstitial
          : _FullscreenAdKind.rewarded;
    }
    if (hasI) return _FullscreenAdKind.interstitial;
    if (hasR) return _FullscreenAdKind.rewarded;
    return _random.nextBool()
        ? _FullscreenAdKind.interstitial
        : _FullscreenAdKind.rewarded;
  }

  Future<void> _waitForFullscreenAd({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_interstitial != null || _rewarded != null) return;
      _loadInterstitial();
      _loadRewarded();
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
  }

  /// Shows a random fullscreen ad (interstitial or rewarded).
  Future<bool> showMakalaEntryAd({
    required VoidCallback onCompleted,
    VoidCallback? onFailed,
    bool grantRewardOnDismiss = true,
  }) async {
    if (!_initialized) await initialize();
    if (!_initialized) {
      onFailed?.call();
      return false;
    }

    await _waitForFullscreenAd();

    final first = _pickRandomKind();
    final second = first == _FullscreenAdKind.interstitial
        ? _FullscreenAdKind.rewarded
        : _FullscreenAdKind.interstitial;

    for (final kind in [first, second]) {
      if (kind == _FullscreenAdKind.interstitial && _interstitial != null) {
        return _showInterstitial(onCompleted: onCompleted, onFailed: onFailed);
      }
      if (kind == _FullscreenAdKind.rewarded && _rewarded != null) {
        return _showRewarded(
          onCompleted: onCompleted,
          onFailed: onFailed,
          grantOnDismiss: grantRewardOnDismiss,
        );
      }
    }

    onFailed?.call();
    return false;
  }

  Future<bool> _showInterstitial({
    required VoidCallback onCompleted,
    VoidCallback? onFailed,
  }) async {
    final ad = _interstitial;
    if (ad == null) {
      onFailed?.call();
      return false;
    }
    _interstitial = null;

    final done = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
        onCompleted();
        if (!done.isCompleted) done.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial show failed: $error');
        ad.dispose();
        _loadInterstitial();
        onFailed?.call();
        if (!done.isCompleted) done.complete(false);
      },
    );

    try {
      await ad.show();
    } catch (e) {
      debugPrint('Interstitial show error: $e');
      ad.dispose();
      _loadInterstitial();
      onFailed?.call();
      if (!done.isCompleted) done.complete(false);
      return false;
    }
    return done.future;
  }

  Future<bool> _showRewarded({
    required VoidCallback onCompleted,
    VoidCallback? onFailed,
    bool grantOnDismiss = true,
  }) async {
    final ad = _rewarded;
    if (ad == null) {
      onFailed?.call();
      return false;
    }
    _rewarded = null;

    final done = Completer<bool>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (earned || grantOnDismiss) {
          onCompleted();
          if (!done.isCompleted) done.complete(true);
        } else {
          onFailed?.call();
          if (!done.isCompleted) done.complete(false);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded show failed: $error');
        ad.dispose();
        _loadRewarded();
        onFailed?.call();
        if (!done.isCompleted) done.complete(false);
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          earned = true;
        },
      );
    } catch (e) {
      debugPrint('Rewarded show error: $e');
      ad.dispose();
      _loadRewarded();
      onFailed?.call();
      if (!done.isCompleted) done.complete(false);
      return false;
    }
    return done.future;
  }

  @override
  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
    super.dispose();
  }
}
