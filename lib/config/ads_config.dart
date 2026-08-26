import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// AdMob unit IDs for Dawa Asili (com.asilia).
///
/// Debug/profile builds use Google's sample units so you never click live ads
/// during development. Release builds use your production IDs.
class AdsConfig {
  AdsConfig._();

  static const appId = 'ca-app-pub-5619803043988422~5910823254';

  static const _prodBanner = 'ca-app-pub-5619803043988422/5266940940';
  static const _prodInterstitial = 'ca-app-pub-5619803043988422/4538031831';
  static const _prodRewarded = 'ca-app-pub-5619803043988422/6738031217';

  /// Google sample units (safe for local testing).
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300972871';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  static bool get useTestAds => kDebugMode;

  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  static String get bannerAdUnitId {
    if (!useTestAds) return _prodBanner;
    return Platform.isIOS ? _testBannerIos : _testBannerAndroid;
  }

  static String get interstitialAdUnitId {
    if (!useTestAds) return _prodInterstitial;
    return Platform.isIOS ? _testInterstitialIos : _testInterstitialAndroid;
  }

  static String get rewardedAdUnitId {
    if (!useTestAds) return _prodRewarded;
    return Platform.isIOS ? _testRewardedIos : _testRewardedAndroid;
  }
}
