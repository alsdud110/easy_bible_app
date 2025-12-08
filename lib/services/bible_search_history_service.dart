import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 성경 검색 기록 모델
class BibleSearchHistory {
  final String query;
  final DateTime timestamp;

  BibleSearchHistory({
    required this.query,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'query': query,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BibleSearchHistory.fromJson(Map<String, dynamic> json) {
    return BibleSearchHistory(
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// 성경 검색 기록 관리 서비스
class BibleSearchHistoryService {
  static const String _historyKey = 'bible_search_history';
  static const int _maxHistoryItems = 20; // 최근 20개의 검색 기록 저장

  /// 검색어를 히스토리에 저장
  Future<void> saveSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    // 중복 검색어 제거 (대소문자 구분 없이)
    history.removeWhere(
      (item) => item.query.toLowerCase() == query.trim().toLowerCase(),
    );

    // 새 검색어를 맨 앞에 추가
    final newHistory = BibleSearchHistory(
      query: query.trim(),
      timestamp: DateTime.now(),
    );
    history.insert(0, newHistory);

    // 최대 개수 제한
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    // SharedPreferences에 저장
    final jsonList = history.map((h) => h.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  /// 전체 히스토리 가져오기
  Future<List<BibleSearchHistory>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => BibleSearchHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // 파싱 에러 시 빈 리스트 반환
      return [];
    }
  }

  /// 특정 검색어 삭제
  Future<void> deleteHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    history.removeWhere(
      (item) => item.query.toLowerCase() == query.toLowerCase(),
    );

    final jsonList = history.map((h) => h.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  /// 전체 히스토리 삭제
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
