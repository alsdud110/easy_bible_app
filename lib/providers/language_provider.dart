import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 성경 언어를 관리하는 Provider
class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'bible_language';

  BibleLanguage _currentLanguage = BibleLanguage.korean;

  BibleLanguage get currentLanguage => _currentLanguage;

  bool get isKorean => _currentLanguage == BibleLanguage.korean;
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
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.toString());
    } catch (e) {
      debugPrint('언어 저장 실패: $e');
    }
  }

  /// 언어 토글 (한글 ↔ 영어)
  Future<void> toggleLanguage() async {
    final newLanguage = _currentLanguage == BibleLanguage.korean
        ? BibleLanguage.english
        : BibleLanguage.korean;
    await setLanguage(newLanguage);
  }
}

/// 지원하는 성경 언어
enum BibleLanguage {
  korean,
  english,
}

extension BibleLanguageExtension on BibleLanguage {
  String get displayName {
    switch (this) {
      case BibleLanguage.korean:
        return '한글';
      case BibleLanguage.english:
        return 'English';
    }
  }

  String get code {
    switch (this) {
      case BibleLanguage.korean:
        return 'ko';
      case BibleLanguage.english:
        return 'en';
    }
  }
}
