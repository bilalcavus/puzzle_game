import 'dart:io';
import 'package:flutter/foundation.dart'; // ⬅️ ÖNEMLİ
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  // ============================
  // 🔹 BANNER
  // ============================
  BannerAd? bannerAd;
  bool isBannerLoaded = false;

  void loadBanner(VoidCallback onLoaded) {
    final bannerId = kDebugMode
        ? "ca-app-pub-3940256099942544/6300978111"
        : (Platform.isAndroid
            ? "ca-app-pub-7009157199599410/3095829364" // ANDROID PROD
            : "ca-app-pub-7009157199599410/2569215757"); // iOS PROD

    bannerAd = BannerAd(
      adUnitId: bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          isBannerLoaded = true;
          onLoaded();
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  // ============================
  // 🔹 INTERSTITIAL
  // ============================
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  void loadInterstitial() {
    if (_isLoading) return;
    _isLoading = true;

    final interstitialId = kDebugMode
        ? "ca-app-pub-3940256099942544/1033173712"
        : (Platform.isAndroid
            ? "ca-app-pub-7009157199599410/3344732068" // ANDROID PROD
            : "ca-app-pub-7009157199599410/9243926005"); // iOS PROD

    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (_) {
          _interstitialAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  /// ✅ Game Over'da çağrılır
  void showInterstitial({VoidCallback? onClosed}) {
    if (_interstitialAd == null) {
      onClosed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial();
        onClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial();
        onClosed?.call();
      },
    );

    _interstitialAd!.show();
  }
}
