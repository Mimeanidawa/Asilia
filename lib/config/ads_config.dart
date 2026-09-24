import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// AdMob unit IDs for Dawa Asili (com.asilia).
class AdsConfig {
  AdsConfig._();

  static const appId = 'ca-app-pub-5619803043988422~5910823254';

  /// Banner Ad Unit ID configured to always use ca-app-pub-5619803043988422/5266940940
  static const _prodBanner = 'ca-app-pub-5619803043988422/5266940940';
  static const _prodInterstitial = 'ca-app-pub-5619803043988422/4538031831';
  static const _prodRewarded = 'ca-app-pub-5619803043988422/6738031217';

  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Always returns ca-app-pub-5619803043988422/5266940940
  static String getBannerAdUnitId({bool adaptive = false}) {
    return _prodBanner;
  }

  static String get bannerAdUnitId => _prodBanner;

  static String get interstitialAdUnitId => _prodInterstitial;

  static String get rewardedAdUnitId => _prodRewarded;
}
