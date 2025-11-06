import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  /// ✅ 플랫폼별 광고 단위 ID
  static String get _adUnitId {
    if (Platform.isAndroid) {
      // Android 실제 광고 단위
      return 'ca-app-pub-7446781962805745/4003972619';
    } else if (Platform.isIOS) {
      // iOS 실제 광고 단위
      return 'ca-app-pub-7446781962805745/8072089412';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner, // 320x50
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
          print('✅ 배너 광고 로드 성공');
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ 배너 광고 로드 실패: ${error.message}');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd != null && _isLoaded) {
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    // 광고 로딩 중이거나 실패했을 때는 빈 공간
    return const SizedBox.shrink();
  }
}
