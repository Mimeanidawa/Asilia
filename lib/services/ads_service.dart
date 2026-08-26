import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ads_config.dart';
import 'user_service.dart';

/// Central AdMob helper — interstitial + rewarded preload for makala gates.
class AdsService extends ChangeNotifier {
  bool _initialized = false;
  bool _initializing = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;
  int _interstitialFails = 0;
  int _rewardedFails = 0;

  bool get isReady => _initialized && AdsConfig.isSupportedPlatform;

  /// Premium membership skips all ads. Guests and free users see ads.
  bool shouldShowAds(UserService user) {
    if (!AdsConfig.isSupportedPlatform) return false;
    if (user.isLoggedIn && user.user?.isPremiumActive == true) return false;
    return true;
  }

  Future<void> initialize() async {
    if (!AdsConfig.isSupportedPlatform) return;
    if (_initialized || _initializing) return;
    _initializing = true;
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
          _interstitialFails = 0;
          ad.setImmersiveMode(true);
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed: $error');
          _interstitial = null;
          _loadingInterstitial = false;
          _interstitialFails++;
          if (_interstitialFails < 3) {
            Future<void>.delayed(const Duration(seconds: 4), _loadInterstitial);
          }
          notifyListeners();
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
          _rewardedFails = 0;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded failed: $error');
          _rewarded = null;
          _loadingRewarded = false;
          _rewardedFails++;
          if (_rewardedFails < 3) {
            Future<void>.delayed(const Duration(seconds: 4), _loadRewarded);
          }
          notifyListeners();
        },
      ),
    );
  }

  bool get hasInterstitial => _interstitial != null;
  bool get hasRewarded => _rewarded != null;
  bool get hasFullscreenAd => hasInterstitial || hasRewarded;
  bool get isLoadingFullscreen =>
      _loadingInterstitial || _loadingRewarded || _initializing;

  /// Shows interstitial if ready, otherwise rewarded. Returns true if an ad was shown.
  Future<bool> showMakalaEntryAd({
    required VoidCallback onCompleted,
    VoidCallback? onFailed,
  }) async {
    if (!_initialized) await initialize();

    if (_interstitial != null) {
      return _showInterstitial(onCompleted: onCompleted, onFailed: onFailed);
    }
    if (_rewarded != null) {
      return _showRewarded(onCompleted: onCompleted, onFailed: onFailed);
    }

    // Try a quick reload once.
    _loadInterstitial();
    _loadRewarded();
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (_interstitial != null) {
      return _showInterstitial(onCompleted: onCompleted, onFailed: onFailed);
    }
    if (_rewarded != null) {
      return _showRewarded(onCompleted: onCompleted, onFailed: onFailed);
    }

    onFailed?.call();
    return false;
  }

  Future<bool> showRewardedOnly({
    required VoidCallback onCompleted,
    VoidCallback? onFailed,
  }) async {
    if (!_initialized) await initialize();
    if (_rewarded == null) {
      _loadRewarded();
      await Future<void>.delayed(const Duration(milliseconds: 1200));
    }
    if (_rewarded == null) {
      onFailed?.call();
      return false;
    }
    return _showRewarded(onCompleted: onCompleted, onFailed: onFailed);
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
    }
    return done.future;
  }

  Future<bool> _showRewarded({
    required VoidCallback onCompleted,
    VoidCallback? onFailed,
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
        if (earned) {
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
