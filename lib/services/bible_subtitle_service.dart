import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/bible_subtitle.dart';

class BibleSubtitleService {
  static final BibleSubtitleService _instance = BibleSubtitleService._internal();
  factory BibleSubtitleService() => _instance;
  BibleSubtitleService._internal();

  // 개역개정 소제목
  List<BibleSubtitle>? _subtitles;
  Map<String, Map<int, Map<int, String>>>? _subtitleMap;

  // 표준새번역 소제목
  List<BibleSubtitle>? _snbSubtitles;
  Map<String, Map<int, Map<int, String>>>? _snbSubtitleMap;

  /// 개역개정 소제목 데이터 로드
  Future<void> loadSubtitles() async {
    if (_subtitles != null) return;
    _subtitles = [];
    _subtitleMap = {};
    try {
      final String jsonString =
          await rootBundle.loadString('assets/bible_subtitles.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _subtitles = jsonList.map((json) => BibleSubtitle.fromJson(json)).toList();
      _buildMap(_subtitles!, _subtitleMap!);
    } catch (e) {
      print('소제목 로드 오류: $e');
    }
  }

  /// 표준새번역 소제목 데이터 로드
  Future<void> loadSnbSubtitles() async {
    if (_snbSubtitles != null) return;
    _snbSubtitles = [];
    _snbSubtitleMap = {};
    try {
      final String jsonString =
          await rootBundle.loadString('assets/bible_subtitles_snb.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _snbSubtitles = jsonList.map((json) => BibleSubtitle.fromJson(json)).toList();
      _buildMap(_snbSubtitles!, _snbSubtitleMap!);
    } catch (e) {
      print('SNB 소제목 로드 오류: $e');
    }
  }

  void _buildMap(List<BibleSubtitle> list, Map<String, Map<int, Map<int, String>>> map) {
    for (final subtitle in list) {
      map.putIfAbsent(subtitle.book, () => {});
      map[subtitle.book]!.putIfAbsent(subtitle.chapter, () => {});
      map[subtitle.book]![subtitle.chapter]![subtitle.verse] = subtitle.subtitle;
    }
  }

  /// 특정 절에 대한 소제목 가져오기
  String? getSubtitle(String bookName, int chapter, int verse) {
    if (_subtitleMap == null) return null;
    return _subtitleMap![bookName]?[chapter]?[verse];
  }

  /// SNB 특정 절에 대한 소제목 가져오기
  String? getSnbSubtitle(String bookName, int chapter, int verse) {
    if (_snbSubtitleMap == null) return null;
    return _snbSubtitleMap![bookName]?[chapter]?[verse];
  }

  /// 특정 장의 모든 소제목 가져오기 (verse를 키로)
  Map<int, String> getSubtitlesForChapter(String bookName, int chapter) {
    if (_subtitleMap == null) return {};
    return _subtitleMap![bookName]?[chapter] ?? {};
  }

  /// SNB 특정 장의 모든 소제목 가져오기
  Map<int, String> getSnbSubtitlesForChapter(String bookName, int chapter) {
    if (_snbSubtitleMap == null) return {};
    return _snbSubtitleMap![bookName]?[chapter] ?? {};
  }
}
