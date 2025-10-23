import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'bible_key_converter.dart';
import '../providers/language_provider.dart';

/// 언어별 성경 JSON 로드 및 관리
class BibleLoader {
  static Map<String, String>? _koreanBible;
  static Map<String, String>? _englishBible;

  /// 한글 성경 로드
  static Future<Map<String, String>> loadKoreanBible() async {
    if (_koreanBible != null) return _koreanBible!;

    final jsonString = await rootBundle.loadString('assets/bible.json');
    final Map<String, dynamic> raw = json.decode(jsonString);
    _koreanBible = raw.map((k, v) => MapEntry(k, v as String));

    return _koreanBible!;
  }

  /// 영어 성경 로드
  static Future<Map<String, String>> loadEnglishBible() async {
    if (_englishBible != null) return _englishBible!;

    final jsonString = await rootBundle.loadString('assets/bible_kjv.json');
    final Map<String, dynamic> raw = json.decode(jsonString);
    _englishBible = raw.map((k, v) => MapEntry(k, v as String));

    return _englishBible!;
  }

  /// 언어에 따라 적절한 성경 로드
  static Future<Map<String, String>> loadBible(BibleLanguage language) async {
    switch (language) {
      case BibleLanguage.korean:
        return await loadKoreanBible();
      case BibleLanguage.english:
        return await loadEnglishBible();
    }
  }

  /// 캐시 초기화 (메모리 절약이 필요할 경우)
  static void clearCache() {
    _koreanBible = null;
    _englishBible = null;
  }
}

/// 특정 책의 특정 장에 대한 구절 추출
class BibleVerseExtractor {
  /// 한글 성경에서 구절 추출
  /// 예: extractVerses('창', 1) → {1: "태초에...", 2: "땅이..."}
  static Future<Map<int, String>> extractKoreanVerses(
    String bookName,
    int chapter,
  ) async {
    final bible = await BibleLoader.loadKoreanBible();
    return _extractVerses(bible, bookName, chapter);
  }

  /// 영어 성경에서 구절 추출
  /// 예: extractVerses('Gen', 1) → {1: "In the beginning...", 2: "And the earth..."}
  static Future<Map<int, String>> extractEnglishVerses(
    String bookName,
    int chapter,
  ) async {
    final bible = await BibleLoader.loadEnglishBible();
    return _extractVerses(bible, bookName, chapter);
  }

  /// 언어에 따라 구절 추출
  static Future<Map<int, String>> extractVerses(
    BibleLanguage language,
    String bookName,
    int chapter,
  ) async {
    switch (language) {
      case BibleLanguage.korean:
        return await extractKoreanVerses(bookName, chapter);
      case BibleLanguage.english:
        // 한글 책 이름이 들어올 수 있으므로 영어로 변환
        final englishBookName = BookNameConverter.koreanToEnglish(bookName);
        return await extractEnglishVerses(englishBookName, chapter);
    }
  }

  /// 내부 구현: 성경 맵에서 특정 책과 장의 구절들 추출
  static Map<int, String> _extractVerses(
    Map<String, String> bible,
    String bookName,
    int chapter,
  ) {
    final result = <int, String>{};
    final prefix = '$bookName$chapter:';

    for (var entry in bible.entries) {
      if (entry.key.startsWith(prefix)) {
        final verseNumStr = entry.key.substring(prefix.length);
        final verseNum = int.tryParse(verseNumStr);
        if (verseNum != null) {
          result[verseNum] = entry.value;
        }
      }
    }

    return result;
  }
}

/// 하위 호환성을 위한 기존 함수
@Deprecated('Use BibleLoader.loadKoreanBible() instead')
Future<Map<String, String>> loadBibleJson() async {
  return await BibleLoader.loadKoreanBible();
}
