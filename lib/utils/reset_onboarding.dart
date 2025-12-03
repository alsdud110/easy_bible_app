import 'package:shared_preferences/shared_preferences.dart';

/// 온보딩을 다시 보고 싶을 때 이 함수를 호출하세요
///
/// 사용법:
/// ```dart
/// import 'utils/reset_onboarding.dart';
///
/// // 홈 화면의 디버그 버튼 등에서:
/// await resetOnboarding();
/// // 앱 재시작
/// ```
Future<void> resetOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('onboarding_completed');
  print('✅ 온보딩 리셋 완료! 앱을 재시작하면 온보딩이 다시 표시됩니다.');
}
