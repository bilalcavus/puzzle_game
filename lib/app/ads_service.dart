import 'dart:io';
import 'dart:ui';
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
    final bannerId = Platform.isAndroid
        ? "ca-app-pub-7009157199599410/3095829364" // ✅ ANDROID
        : "ca-app-pub-7009157199599410/2569215757"; // ✅ iOS

    bannerAd = BannerAd(
      adUnitId: bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          isBannerLoaded = true;
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  // ============================
  // 🔹 INTERSTITIAL (GAME OVER)
  // ============================
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  void loadInterstitial() {
    if (_isLoading) return;
    _isLoading = true;

    final interstitialId = Platform.isAndroid
        ? "ca-app-pub-7009157199599410/3344732068" // ✅ ANDROID
        : "ca-app-pub-7009157199599410/9243926005"; // ✅ iOS

    InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  /// ✅ Game Over'da otomatik çağır
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
        loadInterstitial(); // sıradaki reklamı hazırla
        onClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial();
        onClosed?.call();
      },
    );

    _interstitialAd!.show();
  }
}
