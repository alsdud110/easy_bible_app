import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'const/book_full_name.dart';

/// bible.json을 Map<String, String>으로 반환
Future<Map<String, String>> loadBibleJson() async {
  final jsonString = await rootBundle.loadString('assets/bible.json');
  final Map<String, dynamic> raw = json.decode(jsonString);
  return raw.map((k, v) => MapEntry(k, v as String));
}

/// 소제목 데이터 모델
class BibleSubtitle {
  final String book;
  final String chapter;
  final String verse;
  final String subtitle;

  BibleSubtitle({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.subtitle,
  });

  factory BibleSubtitle.fromJson(Map<String, dynamic> json) {
    return BibleSubtitle(
      book: json['book'] as String,
      chapter: json['chapter'] as String,
      verse: json['verse'] as String,
      subtitle: json['subtitle'] as String,
    );
  }

  /// "책장:절" 형태의 키 생성 (예: "창1:1")
  /// fullName을 shortName으로 변환하여 사용
  String get key {
    final shortName = bookShortName[book] ?? book;
    return '$shortName$chapter:$verse';
  }
}

/// bible_subtitles.json을 로드하여 Map<String, String>으로 반환
/// Key: "책장:절" (예: "창1:1"), Value: 소제목
Future<Map<String, String>> loadBibleSubtitles() async {
  final jsonString = await rootBundle.loadString('assets/bible_subtitles.json');
  final List<dynamic> rawList = json.decode(jsonString);

  final Map<String, String> subtitles = {};
  for (final item in rawList) {
    final subtitle = BibleSubtitle.fromJson(item as Map<String, dynamic>);
    subtitles[subtitle.key] = subtitle.subtitle;
  }

  return subtitles;
}
