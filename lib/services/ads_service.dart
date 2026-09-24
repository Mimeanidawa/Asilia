import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ads_config.dart';
import 'user_service.dart';

/// Central AdMob helper — banner, interstitial, and rewarded ads.
class AdsService extends ChangeNotifier {
  bool _initialized = false;
  bool _initializing = false;
  Future<void>? _initFuture;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  RewardedInterstitialAd? _rewardedInterstitial;
  bool _loadingInterstitial = false;
  bool _loadingRewarded = false;
  bool _loadingRewardedInterstitial = false;
  int _interstitialBackoff = 4;
  int _rewardedBackoff = 4;
  int _interstitialFailures = 0;
  int _rewardedFailures = 0;

  bool get isReady => _initialized && AdsConfig.isSupportedPlatform;
  bool get isInitializing => _initializing;

  bool shouldShowAds(UserService user) {
    if (!AdsConfig.isSupportedPlatform) return false;
    if (user.isLoggedIn && user.user?.isPremiumActive == true) return false;
    return true;
  }

  /// All callers share one init future so nobody loads ads before the SDK is ready.
  Future<void> initialize() {
    if (!AdsConfig.isSupportedPlatform) return Future.value();
    if (_initialized) return Future.value();
    return _initFuture ??= _initOnce();
  }

  Future<void> _initOnce() async {
    if (_initialized) return;
    _initializing = true;
    notifyListeners();
    try {
      final status = await MobileAds.instance.initialize();
      debugPrint('MobileAds initialized: ${status.adapterStatuses}');
      _initialized = true;
      // Warm fullscreen inventory; banners load in-slot for fastest first paint.
      unawaited(preload());
    } catch (e, st) {
      debugPrint('AdsService init failed: $e\n$st');
      _initFuture = null;
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  Future<void> preload() async {
    await initialize();
    if (!_initialized) return;
    _interstitialFailures = 0;
    _rewardedFailures = 0;
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
          debugPrint('Interstitial loaded');
          _interstitial = ad;
          _loadingInterstitial = false;
          _interstitialBackoff = 4;
          _interstitialFailures = 0;
          ad.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed: $error');
          _interstitial = null;
          _loadingInterstitial = false;
          _scheduleInterstitialRetry(error);
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
          debugPrint('Rewarded video loaded successfully');
          _rewarded = ad;
          _loadingRewarded = false;
          _rewardedBackoff = 4;
          _rewardedFailures = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded failed: $error');
          _rewarded = null;
          _loadingRewarded = false;
          _scheduleRewardedRetry(error);
          if (_rewardedInterstitial == null && !_loadingRewardedInterstitial) {
            _loadRewardedInterstitial();
          }
        },
      ),
    );
  }

  void _loadRewardedInterstitial() {
    if (_loadingRewardedInterstitial || _rewardedInterstitial != null) return;
    _loadingRewardedInterstitial = true;
    RewardedInterstitialAd.load(
      adUnitId: AdsConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded interstitial loaded successfully');
          _rewardedInterstitial = ad;
          _loadingRewardedInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded interstitial failed: $error');
          _rewardedInterstitial = null;
          _loadingRewardedInterstitial = false;
        },
      ),
    );
  }

  void _scheduleInterstitialRetry([LoadAdError? error]) {
    _interstitialFailures++;
    final isNetwork = error != null &&
        (error.code == 0 ||
            error.message.toLowerCase().contains('unable to resolve host') ||
            error.message.toLowerCase().contains('connect'));

    if (isNetwork && _interstitialFailures > 4) return;
    if (_interstitialFailures > 6) return;

    final delay = isNetwork
        ? Duration(seconds: (_interstitialFailures * 3).clamp(3, 20))
        : Duration(seconds: _interstitialBackoff);
    _interstitialBackoff = (_interstitialBackoff + 4).clamp(4, 30);

    Future<void>.delayed(delay, () {
      if (_interstitial == null && !_loadingInterstitial) _loadInterstitial();
    });
  }

  void _scheduleRewardedRetry([LoadAdError? error]) {
    _rewardedFailures++;
    final isNetwork = error != null &&
        (error.code == 0 ||
            error.message.toLowerCase().contains('unable to resolve host') ||
            error.message.toLowerCase().contains('connect'));

    if (isNetwork && _rewardedFailures > 4) return;
    if (_rewardedFailures > 6) return;

    final delay = isNetwork
        ? Duration(seconds: (_rewardedFailures * 3).clamp(3, 20))
        : Duration(seconds: _rewardedBackoff);
    _rewardedBackoff = (_rewardedBackoff + 4).clamp(4, 30);

    Future<void>.delayed(delay, () {
      if (_rewarded == null && !_loadingRewarded) _loadRewarded();
    });
  }

  bool get hasInterstitial => _interstitial != null;
  bool get hasRewarded => _rewarded != null || _rewardedInterstitial != null;
  bool get hasFullscreenAd => hasInterstitial || hasRewarded;
  bool get isLoadingFullscreen =>
      _loadingInterstitial || _loadingRewarded || _loadingRewardedInterstitial || _initializing;

  Future<void> _waitForFullscreenAd({
    Duration timeout = const Duration(milliseconds: 3500),
  }) async {
    // If a rewarded ad is already ready, proceed immediately
    if (_rewarded != null || _rewardedInterstitial != null) return;

    // Trigger loads if not already in flight
    _loadRewarded();
    if (_interstitial == null) _loadInterstitial();

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      // Prioritize rewarded ad: if it arrives, return immediately
      if (_rewarded != null || _rewardedInterstitial != null) return;

      // If rewarded ad loading completed (failed), but interstitial is ready, fallback
      if (!_loadingRewarded && !_loadingRewardedInterstitial && _interstitial != null) {
        return;
      }

      // If all ad loads finished and none succeeded, exit early without waiting
      if (!_loadingRewarded &&
          !_loadingRewardedInterstitial &&
          !_loadingInterstitial &&
          _rewarded == null &&
          _rewardedInterstitial == null &&
          _interstitial == null) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  /// Shows fullscreen ad, prioritizing Rewarded Video ads first.
  Future<bool> showMakalaEntryAd({
    required VoidCallback onCompleted,
    VoidCallback? onFailed,
    VoidCallback? onAdStarted,
    bool grantRewardOnDismiss = true,
  }) async {
    await initialize();
    if (!_initialized) {
      onFailed?.call();
      return false;
    }

    await _waitForFullscreenAd();

    // 1. Prioritize Rewarded Video ad
    if (_rewarded != null) {
      debugPrint('AdsService: Showing Rewarded Video ad');
      return _showRewarded(
        onCompleted: onCompleted,
        onFailed: () {
          if (_interstitial != null) {
            _showInterstitial(
              onCompleted: onCompleted,
              onFailed: onFailed,
              onAdStarted: onAdStarted,
            );
          } else {
            onFailed?.call();
          }
        },
        onAdStarted: onAdStarted,
        grantOnDismiss: grantRewardOnDismiss,
      );
    }

    // 2. Prioritize Rewarded Interstitial ad if available
    if (_rewardedInterstitial != null) {
      debugPrint('AdsService: Showing Rewarded Interstitial ad');
      return _showRewardedInterstitial(
        onCompleted: onCompleted,
        onFailed: () {
          if (_interstitial != null) {
            _showInterstitial(
              onCompleted: onCompleted,
              onFailed: onFailed,
              onAdStarted: onAdStarted,
            );
          } else {
            onFailed?.call();
          }
        },
        onAdStarted: onAdStarted,
        grantOnDismiss: grantRewardOnDismiss,
      );
    }

    // 3. Fallback to Interstitial ad only if rewarded ad is not available
    if (_interstitial != null) {
      debugPrint('AdsService: Fallback to Interstitial ad (rewarded was not ready)');
      return _showInterstitial(
        onCompleted: onCompleted,
        onFailed: onFailed,
        onAdStarted: onAdStarted,
      );
    }

    onFailed?.call();
    return false;
  }

  Future<bool> _showInterstitial({
    required VoidCallback onCompleted,
    VoidCallback? onFailed,
    VoidCallback? onAdStarted,
  }) async {
    final ad = _interstitial;
    if (ad == null) {
      onFailed?.call();
      return false;
    }
    _interstitial = null;

    final done = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Interstitial ad showed on screen');
        onAdStarted?.call();
      },
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
    VoidCallback? onAdStarted,
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
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Rewarded ad showed on screen');
        onAdStarted?.call();
      },
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

  Future<bool> _showRewardedInterstitial({
    required VoidCallback onCompleted,
    VoidCallback? onFailed,
    VoidCallback? onAdStarted,
    bool grantOnDismiss = true,
  }) async {
    final ad = _rewardedInterstitial;
    if (ad == null) {
      onFailed?.call();
      return false;
    }
    _rewardedInterstitial = null;

    final done = Completer<bool>();
    var earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('RewardedInterstitial ad showed on screen');
        onAdStarted?.call();
      },
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
        debugPrint('RewardedInterstitial show failed: $error');
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
      debugPrint('RewardedInterstitial show error: $e');
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
    _rewardedInterstitial?.dispose();
    super.dispose();
  }
}
