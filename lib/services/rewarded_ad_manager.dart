import 'dart:io';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdManager {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  /// 플랫폼별 보상형 광고 단위 ID
  static String get _adUnitId {
    // 실제 광고 단위 ID
    if (Platform.isAndroid) {
      return 'ca-app-pub-7446781962805745/2448103937';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-7446781962805745/3097064524';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// 광고가 로드되었는지 확인
  bool get isAdLoaded => _isAdLoaded;

  /// 광고 로드
  Future<void> loadAd() async {
    print('🔄 보상형 광고 로드 시작...');

    await RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
          _retryCount = 0; // 성공 시 재시도 카운트 리셋
          print('✅ 보상형 광고 로드 성공');

          // 광고 이벤트 리스너 설정
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              print('📺 보상형 광고 표시됨');
            },
            onAdDismissedFullScreenContent: (ad) {
              print('✅ 보상형 광고 닫힘');
              ad.dispose();
              _isAdLoaded = false;
              // 다음 광고를 위해 미리 로드
              loadAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('❌ 보상형 광고 표시 실패: ${error.message}');
              print('   에러 코드: ${error.code}');
              ad.dispose();
              _isAdLoaded = false;
              loadAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('❌ 보상형 광고 로드 실패: ${error.message}');
          print('   에러 코드: ${error.code}');
          print('   도메인: ${error.domain}');
          _isAdLoaded = false;
          _retryCount++;

          // 재시도 횟수 제한 (무한 루프 방지)
          if (_retryCount <= _maxRetries) {
            // 지수 백오프: 5초, 10초, 20초
            final delay = Duration(seconds: 5 * _retryCount);
            print('🔄 $delay 후 재시도 ($_retryCount/$_maxRetries)');
            Future.delayed(delay, () {
              print('🔄 보상형 광고 재시도 중... ($_retryCount/$_maxRetries)');
              loadAd();
            });
          } else {
            print('⚠️ 최대 재시도 횟수 도달. 다음 요청 시 다시 시도합니다.');
          }
        },
      ),
    );
  }

  /// 광고 표시 및 보상 처리
  Future<bool> showAd() async {
    if (_rewardedAd == null || !_isAdLoaded) {
      print('⚠️ 광고가 아직 로드되지 않았습니다');
      return false;
    }

    bool rewarded = false;

    _rewardedAd!.setImmersiveMode(true);

    // 광고가 닫힐 때까지 기다리기 위한 Completer
    final completer = Completer<bool>();

    // 광고 이벤트 리스너 재설정
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('📺 보상형 광고 표시됨');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('✅ 보상형 광고 닫힘');
        ad.dispose();
        _isAdLoaded = false;
        // 광고가 닫히면 보상 여부 반환
        completer.complete(rewarded);
        // 다음 광고를 위해 미리 로드
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ 보상형 광고 표시 실패: ${error.message}');
        ad.dispose();
        _isAdLoaded = false;
        completer.complete(false);
        loadAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        print('🎁 보상 획득: ${reward.amount} ${reward.type}');
        rewarded = true;
      },
    );

    // 광고가 닫힐 때까지 기다림
    return await completer.future;
  }

  /// 광고 리소스 해제
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoaded = false;
  }
}
