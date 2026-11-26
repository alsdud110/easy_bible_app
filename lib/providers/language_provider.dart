import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/feature_flags.dart';
import '../models/subscription_plan.dart';

/// 성경 언어를 관리하는 Provider
class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'bible_language';

  BibleLanguage _currentLanguage = BibleLanguage.korean;
  // 영어에서 한글로 돌아올 때 쓰던 한글 번역본으로 복귀
  BibleLanguage _lastKoreanLanguage = BibleLanguage.korean;

  BibleLanguage get currentLanguage => _currentLanguage;

  bool get isKorean => _currentLanguage != BibleLanguage.english;
  bool get isEnglish => _currentLanguage == BibleLanguage.english;

  LanguageProvider() {
    _loadLanguage();
  }

  /// SharedPreferences에서 저장된 언어 불러오기
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageString = prefs.getString(_languageKey);

      if (languageString != null) {
        _currentLanguage = BibleLanguage.values.firstWhere(
          (e) => e.toString() == languageString,
          orElse: () => BibleLanguage.korean,
        );
        if (isKorean) _lastKoreanLanguage = _currentLanguage;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('언어 불러오기 실패: $e');
    }
  }

  /// 언어 변경 및 저장
  Future<void> setLanguage(BibleLanguage language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;
    if (isKorean) _lastKoreanLanguage = language;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.toString());
    } catch (e) {
      debugPrint('언어 저장 실패: $e');
    }
  }

  /// 언어 토글: 'Eng/한' 버튼이라 한글 번역본 ↔ 영어만 오감
  Future<void> toggleLanguage() => setLanguage(nextLanguage);

  /// toggleLanguage() 호출 시 전환될 언어를 미리 확인 (부수효과 없음).
  /// 프리미엄 잠금 체크 등 전환 전에 확인이 필요한 UI에서 사용합니다.
  BibleLanguage get nextLanguage =>
      isKorean ? BibleLanguage.english : _lastKoreanLanguage;
}

/// 지원하는 성경 버전
enum BibleLanguage {
  korean,  // 개역개정
  snb,     // 표준새번역개정판
  english, // KJV
}

extension BibleLanguageExtension on BibleLanguage {
  String get displayName {
    switch (this) {
      case BibleLanguage.korean:
        return '개역개정';
      case BibleLanguage.snb:
        return '표준새번역';
      case BibleLanguage.english:
        return 'English';
    }
  }

  String get code {
    switch (this) {
      case BibleLanguage.korean:
        return 'ko';
      case BibleLanguage.snb:
        return 'snb';
      case BibleLanguage.english:
        return 'en';
    }
  }

  /// 프리미엄(구독) 사용자에게만 제공하는 번역본인지 여부.
  /// 잠금 정책은 subscription_plan.dart의 premiumBibleLanguageCodes만 수정하면 됩니다.
  bool get isPremiumOnly =>
      kPremiumFeatureEnabled && premiumBibleLanguageCodes.contains(code);
}
