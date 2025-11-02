import 'dart:io';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdManager {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  /// 플랫폼별 보상형 광고 단위 ID
  static String get _adUnitId {
    if (Platform.isAndroid) {
      // Android 테스트 광고 (테스트 완료 후 실제 광고로 변경 필요!)
      return 'ca-app-pub-3940256099942544/5224354917'; // 테스트용
      // return 'ca-app-pub-7446781962805745/2448103937'; // 실제 광고 단위
    } else if (Platform.isIOS) {
      // iOS 테스트 광고 (테스트 완료 후 실제 광고로 변경 필요!)
      return 'ca-app-pub-3940256099942544/1712485313'; // iOS 테스트용
      // return 'ca-app-pub-7446781962805745/3097064524'; // 실제 광고 단위
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// 광고가 로드되었는지 확인
  bool get isAdLoaded => _isAdLoaded;

  /// 광고 로드
  Future<void> loadAd() async {
    await RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
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
              ad.dispose();
              _isAdLoaded = false;
              loadAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('❌ 보상형 광고 로드 실패: ${error.message}');
          _isAdLoaded = false;
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
