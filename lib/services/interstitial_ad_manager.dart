import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdManager {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  /// 앱 어디선가 전면 광고가 화면에 떠 있는 동안 true.
  /// 전면 광고는 별도 화면(Activity)으로 뜨기 때문에 Flutter 쪽에서는
  /// 잠깐 백그라운드로 갔다 온 것처럼 보일 수 있는데, main.dart의
  /// "오래 백그라운드에 있었으면 홈으로 리셋" 로직이 이걸 진짜
  /// 백그라운드 전환으로 착각하지 않도록 이 플래그로 알려줍니다.
  static bool isAnyAdShowing = false;

  /// 플랫폼별 전면 광고 단위 ID
  ///
  /// 디버그(개발) 빌드에서는 항상 Google 공식 테스트 광고 단위를 사용합니다.
  /// 실제 광고 단위로 반복 테스트하면 AdMob에서 무효 트래픽으로 보고 계정에
  /// 경고/제재가 갈 수 있어서, 릴리즈 빌드에서만 실제 광고 단위를 씁니다.
  static String get _adUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/1033173712';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/4411468910';
    }

    // 실제 광고 단위 ID (릴리즈 빌드)
    if (Platform.isAndroid) {
      return 'ca-app-pub-7446781962805745/7065140136';
    } else if (Platform.isIOS) {
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
    isAnyAdShowing = true;

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
        _clearAdShowingFlagAfterGracePeriod();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ 전면 광고 표시 실패: ${error.message}');
        ad.dispose();
        _isAdLoaded = false;
        completer.complete();
        loadAd();
        _clearAdShowingFlagAfterGracePeriod();
      },
    );

    _interstitialAd!.show();

    // 광고가 닫힐 때까지 기다림
    return await completer.future;
  }

  /// 전면 광고가 닫힌 직후, Flutter의 AppLifecycleState.resumed 이벤트가
  /// (플랫폼에 따라) 살짝 늦게 들어오는 경우가 있어서 isAnyAdShowing을
  /// 바로 내리지 않고 잠깐 유예 시간을 둔 뒤 내립니다.
  /// 이 여유가 없으면 main.dart의 "오래 백그라운드 → 홈으로 리셋" 로직이
  /// 광고 때문에 생긴 resumed 이벤트를 진짜 복귀로 착각해서, 광고를 닫자마자
  /// 결과 화면 대신 홈 화면으로 튕기는 버그가 생겼었습니다.
  void _clearAdShowingFlagAfterGracePeriod() {
    Future.delayed(const Duration(milliseconds: 1200), () {
      isAnyAdShowing = false;
    });
  }

  /// 광고 리소스 해제
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
  }
}
