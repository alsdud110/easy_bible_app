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
  int _retryCount = 0;
  static const int _maxRetries = 3;

  /// ✅ 플랫폼별 광고 단위 ID
  static String get _adUnitId {
    // 🧪 테스트 모드: 필요시 true로 변경
    const bool useTestAds = false;

    if (useTestAds) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111'; // Android 테스트 배너 광고
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716'; // iOS 테스트 배너 광고
      }
    }

    // 실제 광고 단위 ID
    if (Platform.isAndroid) {
      return 'ca-app-pub-7446781962805745/4003972619';
    } else if (Platform.isIOS) {
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
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
          _retryCount = 0; // 성공 시 재시도 카운트 리셋
          print('✅ 배너 광고 로드 성공');
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ 배너 광고 로드 실패: ${error.message}');
          print('   에러 코드: ${error.code}');
          print('   도메인: ${error.domain}');
          ad.dispose();
          _bannerAd = null;
          _retryCount++;

          // 재시도 횟수 제한 (무한 루프 방지)
          if (_retryCount <= _maxRetries) {
            // 지수 백오프: 3초, 6초, 12초
            final delay = Duration(seconds: 3 * _retryCount);
            print('🔄 $delay 후 재시도 ($_retryCount/$_maxRetries)');
            Future.delayed(delay, () {
              if (mounted) {
                print('🔄 배너 광고 재시도 중... ($_retryCount/$_maxRetries)');
                _loadAd();
              }
            });
          } else {
            print('⚠️ 최대 재시도 횟수 도달. 광고가 표시되지 않습니다.');
          }
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
      final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble() + bottomPadding,
        alignment: Alignment.topCenter,
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
