import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/bible_data.dart';
import '../providers/language_provider.dart';
import '../utils/bible_key_converter.dart';

class BibleSearchResult {
  final String reference;
  final String text;
  final int bookIndex;
  final String bookName;
  final int chapter;
  final int verse;

  BibleSearchResult({
    required this.reference,
    required this.text,
    required this.bookIndex,
    required this.bookName,
    required this.chapter,
    required this.verse,
  });
}

class BibleSearchResponse {
  final List<BibleSearchResult> results;
  final int totalCount;

  BibleSearchResponse({
    required this.results,
    required this.totalCount,
  });
}

class BibleSearchService {
  static Map<String, dynamic>? _cachedBibleData;
  static BibleLanguage? _cachedLanguage;

  /// 성경 전체에서 검색어를 찾아 결과 반환
  static Future<BibleSearchResponse> searchBible(
    String query,
    BibleLanguage language,
  ) async {
    if (query.trim().isEmpty) {
      return BibleSearchResponse(results: [], totalCount: 0);
    }

    // 캐시된 데이터가 없거나 언어가 다르면 다시 로드
    if (_cachedBibleData == null || _cachedLanguage != language) {
      await _loadBibleData(language);
    }

    final results = <BibleSearchResult>[];
    final lowerQuery = query.toLowerCase().trim();

    // 모든 구절을 순회하며 검색어 포함 여부 확인
    _cachedBibleData?.forEach((key, value) {
      final text = value as String;
      if (text.toLowerCase().contains(lowerQuery)) {
        final result = _parseKeyToResult(key, text, language);
        if (result != null) {
          results.add(result);
        }
      }
    });

    // 전체 개수와 최대 500개까지만 반환 (성능 고려)
    return BibleSearchResponse(
      results: results.take(500).toList(),
      totalCount: results.length,
    );
  }

  /// JSON 데이터 로드
  static Future<void> _loadBibleData(BibleLanguage language) async {
    final String assetPath = language == BibleLanguage.korean
        ? 'assets/bible.json'
        : 'assets/bible_kjv.json';

    final String data = await rootBundle.loadString(assetPath);
    _cachedBibleData = json.decode(data);
    _cachedLanguage = language;
  }

  /// 키를 파싱하여 BibleSearchResult로 변환
  /// 예: "창세기1:1" -> BibleSearchResult
  static BibleSearchResult? _parseKeyToResult(
    String key,
    String text,
    BibleLanguage language,
  ) {
    try {
      // 키 형식: "창세기1:1" 또는 "Genesis1:1"
      final match = RegExp(r'^(.+?)(\d+):(\d+)$').firstMatch(key);
      if (match == null) return null;

      final bookName = match.group(1)!;
      final chapter = int.parse(match.group(2)!);
      final verse = int.parse(match.group(3)!);

      // 책 이름으로 인덱스 찾기
      final bookIndex = _findBookIndex(bookName, language);
      if (bookIndex == -1) return null;

      final book = bibleBooks[bookIndex];
      final displayBookName = language == BibleLanguage.korean
          ? book.fullName
          : book.eng;

      final reference = language == BibleLanguage.korean
          ? '$displayBookName $chapter:$verse'
          : '$displayBookName $chapter:$verse';

      return BibleSearchResult(
        reference: reference,
        text: text,
        bookIndex: bookIndex,
        bookName: displayBookName,
        chapter: chapter,
        verse: verse,
      );
    } catch (e) {
      return null;
    }
  }

  /// 책 이름으로 인덱스 찾기
  static int _findBookIndex(String bookName, BibleLanguage language) {
    if (language == BibleLanguage.korean) {
      // 한글 책 이름으로 찾기
      return bibleBooks.indexWhere((book) => book.name == bookName);
    } else {
      // 영어 책 이름으로 찾기 (BookNameConverter 사용)
      for (int i = 0; i < bibleBooks.length; i++) {
        final koreanName = bibleBooks[i].name;
        final englishName = BookNameConverter.koreanToEnglish(koreanName);
        if (englishName == bookName) {
          return i;
        }
      }
      return -1;
    }
  }

  /// 캐시 클리어 (메모리 절약)
  static void clearCache() {
    _cachedBibleData = null;
    _cachedLanguage = null;
  }
}
