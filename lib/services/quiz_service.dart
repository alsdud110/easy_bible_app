import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/quiz_question.dart';

/// 퀴즈 데이터를 관리하는 서비스
class QuizService {
  static final QuizService _instance = QuizService._internal();
  factory QuizService() => _instance;
  QuizService._internal();

  // 캐시된 문제들 (난이도별)
  final Map<String, List<QuizQuestion>> _cachedQuestions = {};

  /// 난이도별 파일 경로 가져오기
  String _getFilePath(QuizType type, Difficulty difficulty) {
    final typePrefix = type == QuizType.ox ? 'ox' : 'multiple';
    final difficultyName = difficulty.name; // easy, medium, hard
    return 'assets/quiz/question_${typePrefix}_$difficultyName.json';
  }

  /// 캐시 키 생성
  String _getCacheKey(QuizType type, Difficulty difficulty) {
    return '${type.name}_${difficulty.name}';
  }

  /// 특정 난이도의 문제 로드
  Future<List<QuizQuestion>> loadQuestionsByDifficulty({
    required QuizType type,
    required Difficulty difficulty,
  }) async {
    final cacheKey = _getCacheKey(type, difficulty);

    // 캐시 확인
    if (_cachedQuestions.containsKey(cacheKey)) {
      return _cachedQuestions[cacheKey]!;
    }

    try {
      final filePath = _getFilePath(type, difficulty);
      final jsonString = await rootBundle.loadString(filePath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final questionsList = jsonData['questions'] as List;

      final questions = questionsList
          .map((q) => QuizQuestion.fromJson(q, type))
          .toList();

      // 캐시 저장
      _cachedQuestions[cacheKey] = questions;

      return questions;
    } catch (e) {
      throw Exception('퀴즈 문제 로드 실패 ($type, $difficulty): $e');
    }
  }

  /// 모든 난이도의 문제 로드
  Future<List<QuizQuestion>> loadAllQuestions(QuizType type) async {
    final allQuestions = <QuizQuestion>[];

    for (var difficulty in Difficulty.values) {
      final questions = await loadQuestionsByDifficulty(
        type: type,
        difficulty: difficulty,
      );
      allQuestions.addAll(questions);
    }

    return allQuestions;
  }

  /// 난이도와 유형에 맞는 퀴즈 문제 가져오기 (랜덤 10문제)
  Future<List<QuizQuestion>> getQuizQuestions({
    required QuizType type,
    required Difficulty difficulty,
    int count = 10,
  }) async {
    final questions = await loadQuestionsByDifficulty(
      type: type,
      difficulty: difficulty,
    );

    // 셔플
    final shuffledQuestions = List<QuizQuestion>.from(questions);
    shuffledQuestions.shuffle();

    // 요청한 개수만큼 반환 (최대 available 개수)
    final availableCount = shuffledQuestions.length;
    final selectedCount = count > availableCount ? availableCount : count;

    return shuffledQuestions.take(selectedCount).toList();
  }

  /// 모든 난이도 섞어서 가져오기
  Future<List<QuizQuestion>> getMixedQuizQuestions({
    required QuizType type,
    int count = 10,
  }) async {
    final allQuestions = await loadAllQuestions(type);

    // 셔플
    allQuestions.shuffle();

    // 요청한 개수만큼 반환
    final availableCount = allQuestions.length;
    final selectedCount = count > availableCount ? availableCount : count;

    return allQuestions.take(selectedCount).toList();
  }

  /// 난이도별 문제 개수 확인
  Future<Map<Difficulty, int>> getQuestionCountByDifficulty(
    QuizType type,
  ) async {
    final counts = <Difficulty, int>{};

    for (var difficulty in Difficulty.values) {
      final questions = await loadQuestionsByDifficulty(
        type: type,
        difficulty: difficulty,
      );
      counts[difficulty] = questions.length;
    }

    return counts;
  }

  /// 캐시 클리어
  void clearCache() {
    _cachedQuestions.clear();
  }
}
