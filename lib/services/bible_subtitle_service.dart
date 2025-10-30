import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/bible_subtitle.dart';

class BibleSubtitleService {
  static final BibleSubtitleService _instance = BibleSubtitleService._internal();
  factory BibleSubtitleService() => _instance;
  BibleSubtitleService._internal();

  List<BibleSubtitle>? _subtitles;
  Map<String, Map<int, Map<int, String>>>? _subtitleMap;

  /// 소제목 데이터 로드
  Future<void> loadSubtitles() async {
    if (_subtitles != null) return;

    try {
      final String jsonString =
          await rootBundle.loadString('assets/bible_subtitles.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      _subtitles =
          jsonList.map((json) => BibleSubtitle.fromJson(json)).toList();

      // Map 구조로 변환: {bookName: {chapter: {verse: subtitle}}}
      _subtitleMap = {};
      for (final subtitle in _subtitles!) {
        _subtitleMap!.putIfAbsent(subtitle.book, () => {});
        _subtitleMap![subtitle.book]!.putIfAbsent(subtitle.chapter, () => {});
        _subtitleMap![subtitle.book]![subtitle.chapter]![subtitle.verse] =
            subtitle.subtitle;
      }
    } catch (e) {
      print('소제목 로드 오류: $e');
      _subtitles = [];
      _subtitleMap = {};
    }
  }

  /// 특정 절에 대한 소제목 가져오기
  String? getSubtitle(String bookName, int chapter, int verse) {
    if (_subtitleMap == null) return null;
    return _subtitleMap![bookName]?[chapter]?[verse];
  }

  /// 특정 장의 모든 소제목 가져오기 (verse를 키로)
  Map<int, String> getSubtitlesForChapter(String bookName, int chapter) {
    if (_subtitleMap == null) return {};
    return _subtitleMap![bookName]?[chapter] ?? {};
  }
}
