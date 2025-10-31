import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 성경 본문 폰트 크기를 관리하는 기본 Provider
abstract class BaseFontSizeProvider extends ChangeNotifier {
  final String storageKey;
  FontSize _currentSize = FontSize.small;

  FontSize get currentSize => _currentSize;

  bool get isSmall => _currentSize == FontSize.small;
  bool get isMedium => _currentSize == FontSize.medium;
  bool get isLarge => _currentSize == FontSize.large;

  BaseFontSizeProvider(this.storageKey) {
    _loadFontSize();
  }

  /// SharedPreferences에서 저장된 폰트 크기 불러오기
  Future<void> _loadFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sizeString = prefs.getString(storageKey);

      if (sizeString != null) {
        _currentSize = FontSize.values.firstWhere(
          (e) => e.toString() == sizeString,
          orElse: () => FontSize.small,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('폰트 크기 불러오기 실패: $e');
    }
  }

  /// 폰트 크기 변경 및 저장
  Future<void> setFontSize(FontSize size) async {
    if (_currentSize == size) return;

    _currentSize = size;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, size.toString());
    } catch (e) {
      debugPrint('폰트 크기 저장 실패: $e');
    }
  }

  /// 폰트 크기 순환 (작게 → 보통 → 크게 → 작게)
  Future<void> cycleFontSize() async {
    FontSize newSize;
    switch (_currentSize) {
      case FontSize.small:
        newSize = FontSize.medium;
        break;
      case FontSize.medium:
        newSize = FontSize.large;
        break;
      case FontSize.large:
        newSize = FontSize.small;
        break;
    }
    await setFontSize(newSize);
  }
}

/// Bible 페이지용 폰트 크기 Provider
class BibleFontSizeProvider extends BaseFontSizeProvider {
  BibleFontSizeProvider() : super('bible_font_size');
}

/// Plan 페이지용 폰트 크기 Provider
class PlanFontSizeProvider extends BaseFontSizeProvider {
  PlanFontSizeProvider() : super('plan_font_size');
}

/// 지원하는 폰트 크기
enum FontSize {
  small,
  medium,
  large,
}

extension FontSizeExtension on FontSize {
  String get displayName {
    switch (this) {
      case FontSize.small:
        return '작게';
      case FontSize.medium:
        return '보통';
      case FontSize.large:
        return '크게';
    }
  }

  /// 한글 버튼 텍스트 (현재 모드)
  String get koreanLabel {
    switch (this) {
      case FontSize.small:
        return '작게';
      case FontSize.medium:
        return '보통';
      case FontSize.large:
        return '크게';
    }
  }

  /// 다음에 전환될 모드의 한글 라벨
  String get nextKoreanLabel {
    switch (this) {
      case FontSize.small:
        return '보통';
      case FontSize.medium:
        return '크게';
      case FontSize.large:
        return '작게';
    }
  }

  /// 한글 버튼 텍스트 크기 (현재 모드)
  double get koreanLabelSize {
    switch (this) {
      case FontSize.small:
        return 11.0;
      case FontSize.medium:
        return 13.0;
      case FontSize.large:
        return 15.0;
    }
  }

  /// 다음에 전환될 모드의 한글 라벨 크기
  double get nextKoreanLabelSize {
    switch (this) {
      case FontSize.small:
        return 13.0; // 다음은 medium
      case FontSize.medium:
        return 15.0; // 다음은 large
      case FontSize.large:
        return 11.0; // 다음은 small
    }
  }

  /// 영어 버튼 텍스트 (A) - 현재 모드
  String get englishLabel {
    return 'A';
  }

  /// 다음에 전환될 모드의 영어 라벨 (A)
  String get nextEnglishLabel {
    switch (this) {
      case FontSize.small:
        return 'A';
      case FontSize.medium:
        return 'AA';
      case FontSize.large:
        return 'a';
    }
  }

  /// 영어 버튼 텍스트 크기 (현재 모드)
  double get englishLabelSize {
    switch (this) {
      case FontSize.small:
        return 14.0;
      case FontSize.medium:
        return 18.0;
      case FontSize.large:
        return 22.0;
    }
  }

  /// 다음에 전환될 모드의 영어 라벨 크기
  double get nextEnglishLabelSize {
    switch (this) {
      case FontSize.small:
        return 18.0; // 다음은 medium
      case FontSize.medium:
        return 22.0; // 다음은 large
      case FontSize.large:
        return 14.0; // 다음은 small
    }
  }

  /// 절 번호 폰트 크기
  double get verseNumberSize {
    switch (this) {
      case FontSize.small:
        return 13.0;
      case FontSize.medium:
        return 15.0;
      case FontSize.large:
        return 17.0;
    }
  }

  /// 선택된 절 번호 폰트 크기
  double get verseNumberSelectedSize {
    switch (this) {
      case FontSize.small:
        return 13.01;
      case FontSize.medium:
        return 15.01;
      case FontSize.large:
        return 17.01;
    }
  }

  /// 본문 폰트 크기
  double get verseTextSize {
    switch (this) {
      case FontSize.small:
        return 15.0;
      case FontSize.medium:
        return 17.0;
      case FontSize.large:
        return 19.0;
    }
  }

  /// 선택된 본문 폰트 크기
  double get verseTextSelectedSize {
    switch (this) {
      case FontSize.small:
        return 15.01;
      case FontSize.medium:
        return 17.01;
      case FontSize.large:
        return 19.01;
    }
  }
}
