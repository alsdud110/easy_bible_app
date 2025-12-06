import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_history.dart';
import '../models/quiz_result.dart';

/// 퀴즈 히스토리 관리 서비스
class QuizHistoryService {
  static const String _historyKey = 'quiz_history';
  static const int _maxHistoryItems = 50; // 최근 50개의 퀴즈 결과 저장

  /// 퀴즈 결과를 히스토리에 저장
  Future<void> saveQuizResult(QuizResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    // 새 히스토리 아이템 생성
    final historyItem = QuizHistoryItem.fromQuizResult(result);

    // 최신 항목을 맨 앞에 추가
    history.insert(0, historyItem);

    // 최대 개수 제한
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    // SharedPreferences에 저장
    final jsonList = history.map((h) => h.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  /// 전체 히스토리 가져오기
  Future<List<QuizHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => QuizHistoryItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // 파싱 에러 시 빈 리스트 반환
      return [];
    }
  }

  /// 특정 ID의 히스토리 아이템 가져오기
  Future<QuizHistoryItem?> getHistoryById(String id) async {
    final history = await getHistory();
    try {
      return history.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 특정 유형의 히스토리만 가져오기
  Future<List<QuizHistoryItem>> getHistoryByType(
      {required String quizType}) async {
    final history = await getHistory();
    return history.where((item) => item.quizType.name == quizType).toList();
  }

  /// 특정 난이도의 히스토리만 가져오기
  Future<List<QuizHistoryItem>> getHistoryByDifficulty(
      {required String difficulty}) async {
    final history = await getHistory();
    return history
        .where((item) => item.difficulty.name == difficulty)
        .toList();
  }

  /// 통계 정보 가져오기
  Future<QuizStatistics> getStatistics() async {
    final history = await getHistory();

    if (history.isEmpty) {
      return QuizStatistics.empty();
    }

    int totalQuizzes = history.length;
    int totalQuestions = 0;
    int totalCorrect = 0;

    for (var item in history) {
      totalQuestions += item.totalQuestions;
      totalCorrect += item.correctCount;
    }

    double averageScore = history.isEmpty
        ? 0.0
        : history.map((h) => h.score).reduce((a, b) => a + b) / totalQuizzes;

    return QuizStatistics(
      totalQuizzes: totalQuizzes,
      totalQuestions: totalQuestions,
      totalCorrect: totalCorrect,
      averageScore: averageScore,
    );
  }

  /// 히스토리 삭제
  Future<void> deleteHistory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    history.removeWhere((item) => item.id == id);

    final jsonList = history.map((h) => h.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  /// 전체 히스토리 삭제
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}

/// 퀴즈 통계 정보
class QuizStatistics {
  final int totalQuizzes;
  final int totalQuestions;
  final int totalCorrect;
  final double averageScore;

  QuizStatistics({
    required this.totalQuizzes,
    required this.totalQuestions,
    required this.totalCorrect,
    required this.averageScore,
  });

  factory QuizStatistics.empty() {
    return QuizStatistics(
      totalQuizzes: 0,
      totalQuestions: 0,
      totalCorrect: 0,
      averageScore: 0.0,
    );
  }

  int get totalIncorrect => totalQuestions - totalCorrect;

  double get accuracy =>
      totalQuestions == 0 ? 0.0 : totalCorrect / totalQuestions;
}
