import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/highlight_verse.dart';

class HighlightProvider with ChangeNotifier {
  List<HighlightVerse> _highlights = [];
  static const String _storageKey = 'bible_highlights';

  List<HighlightVerse> get highlights => List.unmodifiable(_highlights);

  HighlightProvider() {
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_storageKey);
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        _highlights = jsonList
            .map(
                (json) => HighlightVerse.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('하이라이트 로드 실패: $e');
    }
  }

  Future<void> _saveHighlights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String data = jsonEncode(
        _highlights.map((h) => h.toJson()).toList(),
      );
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('하이라이트 저장 실패: $e');
    }
  }

  Future<void> addHighlight(HighlightVerse highlight) async {
    // 초기화 색상인 경우 해당 범위의 하이라이트 삭제
    if (highlight.color == HighlightColor.clear) {
      await _removeHighlightsInRange(
        highlight.bookName,
        highlight.chapter,
        highlight.startVerse,
        highlight.endVerse,
      );
      return;
    }

    // 새로운 하이라이트 범위와 겹치는 기존 하이라이트 처리
    await _handleOverlappingHighlights(highlight);

    _highlights.add(highlight);
    notifyListeners();
    await _saveHighlights();
  }

  Future<void> _handleOverlappingHighlights(HighlightVerse newHighlight) async {
    final overlapping = _highlights
        .where((h) =>
            h.bookName == newHighlight.bookName &&
            h.chapter == newHighlight.chapter &&
            _isOverlapping(h, newHighlight))
        .toList();

    for (final existing in overlapping) {
      _highlights.remove(existing);

      // 겹치지 않는 부분을 새로운 하이라이트로 추가
      if (existing.startVerse < newHighlight.startVerse) {
        // 앞부분이 남는 경우
        _highlights.add(HighlightVerse(
          bookName: existing.bookName,
          chapter: existing.chapter,
          startVerse: existing.startVerse,
          endVerse: newHighlight.startVerse - 1,
          color: existing.color,
          createdAt: existing.createdAt,
        ));
      }

      if (existing.endVerse > newHighlight.endVerse) {
        // 뒷부분이 남는 경우
        _highlights.add(HighlightVerse(
          bookName: existing.bookName,
          chapter: existing.chapter,
          startVerse: newHighlight.endVerse + 1,
          endVerse: existing.endVerse,
          color: existing.color,
          createdAt: existing.createdAt,
        ));
      }
    }
  }

  bool _isOverlapping(HighlightVerse h1, HighlightVerse h2) {
    return !(h1.endVerse < h2.startVerse || h1.startVerse > h2.endVerse);
  }

  Future<void> _removeHighlightsInRange(
    String bookName,
    int chapter,
    int startVerse,
    int endVerse,
  ) async {
    final overlapping = _highlights
        .where((h) =>
            h.bookName == bookName &&
            h.chapter == chapter &&
            _isOverlapping(
              h,
              HighlightVerse(
                bookName: bookName,
                chapter: chapter,
                startVerse: startVerse,
                endVerse: endVerse,
                color: HighlightColor.clear,
                createdAt: DateTime.now(),
              ),
            ))
        .toList();

    for (final existing in overlapping) {
      _highlights.remove(existing);

      // 겹치지 않는 부분을 새로운 하이라이트로 추가
      if (existing.startVerse < startVerse) {
        _highlights.add(HighlightVerse(
          bookName: existing.bookName,
          chapter: existing.chapter,
          startVerse: existing.startVerse,
          endVerse: startVerse - 1,
          color: existing.color,
          createdAt: existing.createdAt,
        ));
      }

      if (existing.endVerse > endVerse) {
        _highlights.add(HighlightVerse(
          bookName: existing.bookName,
          chapter: existing.chapter,
          startVerse: endVerse + 1,
          endVerse: existing.endVerse,
          color: existing.color,
          createdAt: existing.createdAt,
        ));
      }
    }

    notifyListeners();
    await _saveHighlights();
  }

  Future<void> removeHighlight(
      String bookName, int chapter, int startVerse, int endVerse) async {
    _highlights.removeWhere((h) =>
        h.bookName == bookName &&
        h.chapter == chapter &&
        h.startVerse == startVerse &&
        h.endVerse == endVerse);
    notifyListeners();
    await _saveHighlights();
  }

  HighlightVerse? getVerseHighlight(String bookName, int chapter, int verse) {
    try {
      return _highlights.firstWhere(
        (h) => h.containsVerse(bookName, chapter, verse),
      );
    } catch (e) {
      return null;
    }
  }

  bool isVerseHighlighted(String bookName, int chapter, int verse) {
    return getVerseHighlight(bookName, chapter, verse) != null;
  }

  List<HighlightVerse> getChapterHighlights(String bookName, int chapter) {
    return _highlights
        .where((h) => h.bookName == bookName && h.chapter == chapter)
        .toList();
  }

  Future<void> clearAllHighlights() async {
    _highlights.clear();
    notifyListeners();
    await _saveHighlights();
  }
}
