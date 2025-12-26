import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 앱 버전 체크 서비스
/// Firebase Remote Config를 사용하여 최신 버전 정보를 가져오고 현재 버전과 비교
class AppVersionService {
  static final AppVersionService _instance = AppVersionService._internal();
  factory AppVersionService() => _instance;
  AppVersionService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  PackageInfo? _packageInfo;

  /// Remote Config 초기화
  Future<void> initialize() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      _packageInfo = await PackageInfo.fromPlatform();

      // Remote Config 설정
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1), // 1시간마다 체크
        ),
      );

      // 기본값 설정
      await _remoteConfig!.setDefaults({
        'minimum_version': '1.0.0', // 최소 지원 버전
        'latest_version': '1.0.0', // 최신 버전
        'force_update': false, // 강제 업데이트 여부
        'update_message_ko': '새로운 버전이 출시되었습니다.\n업데이트하시겠습니까?',
        'force_update_message_ko': '필수 업데이트가 있습니다.\n앱을 사용하려면 업데이트가 필요합니다.',
      });

      // Remote Config 가져오기
      await _remoteConfig!.fetchAndActivate();
      print('✅ AppVersionService 초기화 완료');
    } catch (e) {
      print('⚠️ AppVersionService 초기화 실패: $e');
    }
  }

  /// 현재 앱 버전
  String get currentVersion => _packageInfo?.version ?? '1.0.0';

  /// Remote Config에서 가져온 최소 지원 버전
  String get minimumVersion =>
      _remoteConfig?.getString('minimum_version') ?? '1.0.0';

  /// Remote Config에서 가져온 최신 버전
  String get latestVersion =>
      _remoteConfig?.getString('latest_version') ?? '1.0.0';

  /// 강제 업데이트 여부
  bool get forceUpdate => _remoteConfig?.getBool('force_update') ?? false;

  /// 업데이트 메시지 (선택적 업데이트)
  String get updateMessage =>
      _remoteConfig?.getString('update_message_ko') ??
      '새로운 버전이 출시되었습니다.\n업데이트하시겠습니까?';

  /// 강제 업데이트 메시지
  String get forceUpdateMessage =>
      _remoteConfig?.getString('force_update_message_ko') ??
      '필수 업데이트가 있습니다.\n앱을 사용하려면 업데이트가 필요합니다.';

  /// 버전 비교 (v1 > v2면 양수, v1 < v2면 음수, 같으면 0)
  int _compareVersions(String v1, String v2) {
    final v1Parts = v1.split('.').map(int.parse).toList();
    final v2Parts = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      final v2Part = i < v2Parts.length ? v2Parts[i] : 0;

      if (v1Part > v2Part) return 1;
      if (v1Part < v2Part) return -1;
    }
    return 0;
  }

  /// 업데이트가 필요한지 체크
  /// returns: null (업데이트 불필요), UpdateType.optional (선택적), UpdateType.required (필수)
  UpdateType? checkUpdateRequired() {
    try {
      // 최소 버전보다 낮으면 강제 업데이트
      if (_compareVersions(currentVersion, minimumVersion) < 0) {
        print('⚠️ 현재 버전($currentVersion)이 최소 버전($minimumVersion)보다 낮음 - 강제 업데이트 필요');
        return UpdateType.required;
      }

      // Remote Config에서 강제 업데이트 플래그가 켜져 있으면 강제 업데이트
      if (forceUpdate && _compareVersions(currentVersion, latestVersion) < 0) {
        print('⚠️ 강제 업데이트 플래그 활성화 - 강제 업데이트 필요');
        return UpdateType.required;
      }

      // 최신 버전보다 낮으면 선택적 업데이트
      if (_compareVersions(currentVersion, latestVersion) < 0) {
        print('ℹ️ 현재 버전($currentVersion)이 최신 버전($latestVersion)보다 낮음 - 선택적 업데이트 가능');
        return UpdateType.optional;
      }

      print('✅ 현재 최신 버전 사용 중');
      return null;
    } catch (e) {
      print('❌ 버전 체크 오류: $e');
      return null;
    }
  }

  /// 앱스토어/플레이스토어 URL
  String get storeUrl {
    if (_packageInfo == null) return '';

    // iOS
    if (_packageInfo!.packageName.contains('ios')) {
      return 'https://apps.apple.com/app/id6754250799';
    }
    // Android
    return 'https://play.google.com/store/apps/details?id=${_packageInfo!.packageName}';
  }
}

/// 업데이트 타입
enum UpdateType {
  optional, // 선택적 업데이트
  required, // 필수 업데이트 (강제)
}
