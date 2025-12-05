import 'package:flutter/material.dart';
import '../models/quiz_question.dart';
import '../models/quiz_result.dart';
import '../services/quiz_service.dart';

/// 퀴즈 상태 관리 Provider
class QuizProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();

  // 퀴즈 설정
  QuizType? _selectedType;
  Difficulty? _selectedDifficulty;

  // 퀴즈 진행 상태
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  List<QuizAnswer> _answers = [];
  bool _isLoading = false;

  // Getters
  QuizType? get selectedType => _selectedType;
  Difficulty? get selectedDifficulty => _selectedDifficulty;
  List<QuizQuestion> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  QuizQuestion? get currentQuestion =>
      _questions.isEmpty ? null : _questions[_currentQuestionIndex];
  List<QuizAnswer> get answers => _answers;
  bool get isLoading => _isLoading;
  int get totalQuestions => _questions.length;
  bool get isQuizComplete => _currentQuestionIndex >= _questions.length;
  double get progress => _questions.isEmpty
      ? 0.0
      : (_currentQuestionIndex + 1) / _questions.length;

  /// 퀴즈 유형 선택
  void selectType(QuizType type) {
    _selectedType = type;
    notifyListeners();
  }

  /// 난이도 선택
  void selectDifficulty(Difficulty difficulty) {
    _selectedDifficulty = difficulty;
    notifyListeners();
  }

  /// 퀴즈 시작
  Future<void> startQuiz({
    required QuizType type,
    required Difficulty difficulty,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedType = type;
      _selectedDifficulty = difficulty;
      _currentQuestionIndex = 0;
      _answers = [];

      // 문제 로드
      _questions = await _quizService.getQuizQuestions(
        type: type,
        difficulty: difficulty,
        count: 10,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 답변 제출
  void submitAnswer(dynamic userAnswer) {
    if (currentQuestion == null) return;

    final question = currentQuestion!;
    bool isCorrect;

    // 정답 확인
    if (question.isOX) {
      isCorrect = userAnswer == question.answer;
    } else {
      isCorrect = userAnswer == question.correctIndex;
    }

    // 답변 기록
    final answer = QuizAnswer(
      question: question,
      userAnswer: userAnswer,
      isCorrect: isCorrect,
      answeredAt: DateTime.now(),
    );

    _answers.add(answer);
    notifyListeners();
  }

  /// 다음 문제로
  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  /// 퀴즈 결과 가져오기
  QuizResult getResult() {
    return QuizResult(
      answers: _answers,
      quizType: _selectedType ?? QuizType.ox,
      difficulty: _selectedDifficulty ?? Difficulty.easy,
      completedAt: DateTime.now(),
    );
  }

  /// 퀴즈 리셋
  void resetQuiz() {
    _selectedType = null;
    _selectedDifficulty = null;
    _questions = [];
    _currentQuestionIndex = 0;
    _answers = [];
    _isLoading = false;
    notifyListeners();
  }

  /// 같은 설정으로 다시 시작
  Future<void> restartQuiz() async {
    if (_selectedType == null || _selectedDifficulty == null) return;

    await startQuiz(
      type: _selectedType!,
      difficulty: _selectedDifficulty!,
    );
  }
}
