import 'dart:io';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdManager {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  /// 플랫폼별 전면 광고 단위 ID
  static String get _adUnitId {
    // 테스트 광고 ID (개발 중에는 이걸 사용)
    // if (Platform.isAndroid) {
    //   return 'ca-app-pub-3940256099942544/1033173712';
    // } else if (Platform.isIOS) {
    //   return 'ca-app-pub-3940256099942544/4411468910';
    // }

    // 실제 광고 단위 ID (프로덕션)
    if (Platform.isAndroid) {
      // 테스트 광고 ID (개발 중에는 이걸 사용)
      // return 'ca-app-pub-3940256099942544/1033173712';
      return 'ca-app-pub-7446781962805745/7065140136';
    } else if (Platform.isIOS) {
      // 테스트 광고 ID (개발 중에는 이걸 사용)
      // return 'ca-app-pub-3940256099942544/4411468910';
      return 'ca-app-pub-7446781962805745/6600545202';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// 광고가 로드되었는지 확인
  bool get isAdLoaded => _isAdLoaded;

  /// 광고 로드
  Future<void> loadAd() async {
    print('🔄 전면 광고 로드 시작...');

    await InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          _retryCount = 0;
          print('✅ 전면 광고 로드 성공');

          // 광고 이벤트 리스너 설정
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('📺 전면 광고 표시됨');
            },
            onAdDismissedFullScreenContent: (ad) {
              print('✅ 전면 광고 닫힘');
              ad.dispose();
              _isAdLoaded = false;
              // 다음 광고를 위해 미리 로드
              loadAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('❌ 전면 광고 표시 실패: ${error.message}');
              print('   에러 코드: ${error.code}');
              ad.dispose();
              _isAdLoaded = false;
              loadAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('❌ 전면 광고 로드 실패: ${error.message}');
          print('   에러 코드: ${error.code}');
          print('   도메인: ${error.domain}');
          _isAdLoaded = false;
          _retryCount++;

          // 재시도 횟수 제한
          if (_retryCount <= _maxRetries) {
            final delay = Duration(seconds: 5 * _retryCount);
            print('🔄 $delay 후 재시도 ($_retryCount/$_maxRetries)');
            Future.delayed(delay, () {
              print('🔄 전면 광고 재시도 중... ($_retryCount/$_maxRetries)');
              loadAd();
            });
          } else {
            print('⚠️ 최대 재시도 횟수 도달. 다음 요청 시 다시 시도합니다.');
          }
        },
      ),
    );
  }

  /// 광고 표시
  Future<void> showAd() async {
    if (_interstitialAd == null || !_isAdLoaded) {
      print('⚠️ 전면 광고가 아직 로드되지 않았습니다');
      return;
    }

    final completer = Completer<void>();

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('📺 전면 광고 표시됨');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('✅ 전면 광고 닫힘');
        ad.dispose();
        _isAdLoaded = false;
        completer.complete();
        // 다음 광고를 위해 미리 로드
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ 전면 광고 표시 실패: ${error.message}');
        ad.dispose();
        _isAdLoaded = false;
        completer.complete();
        loadAd();
      },
    );

    _interstitialAd!.show();

    // 광고가 닫힐 때까지 기다림
    return await completer.future;
  }

  /// 광고 리소스 해제
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
  }
}
