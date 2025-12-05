import 'quiz_question.dart';

/// 퀴즈 답변 기록
class QuizAnswer {
  final QuizQuestion question;
  final dynamic userAnswer; // bool (OX) or int (객관식 index)
  final bool isCorrect;
  final DateTime answeredAt;

  QuizAnswer({
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    required this.answeredAt,
  });
}

/// 퀴즈 결과
class QuizResult {
  final List<QuizAnswer> answers;
  final QuizType quizType;
  final Difficulty difficulty;
  final DateTime completedAt;

  QuizResult({
    required this.answers,
    required this.quizType,
    required this.difficulty,
    required this.completedAt,
  });

  /// 총 문제 수
  int get totalQuestions => answers.length;

  /// 정답 수
  int get correctCount => answers.where((a) => a.isCorrect).length;

  /// 오답 수
  int get incorrectCount => totalQuestions - correctCount;

  /// 점수 (0-100)
  int get score => totalQuestions == 0
      ? 0
      : ((correctCount / totalQuestions) * 100).round();

  /// 정답률 (0.0-1.0)
  double get accuracy => totalQuestions == 0
      ? 0.0
      : correctCount / totalQuestions;

  /// 별점 (0-5)
  int get stars {
    if (score >= 90) return 5;
    if (score >= 80) return 4;
    if (score >= 70) return 3;
    if (score >= 60) return 2;
    if (score >= 50) return 1;
    return 0;
  }

  /// 난이도별 통계
  Map<Difficulty, Map<String, int>> get difficultyStats {
    final stats = <Difficulty, Map<String, int>>{};

    for (var difficulty in Difficulty.values) {
      final difficultyAnswers = answers.where(
        (a) => a.question.difficulty == difficulty,
      );

      stats[difficulty] = {
        'total': difficultyAnswers.length,
        'correct': difficultyAnswers.where((a) => a.isCorrect).length,
      };
    }

    return stats;
  }

  /// 평가 메시지
  String get feedbackMessage {
    if (score >= 90) return '완벽해요! 성경 박사시네요! 🎉';
    if (score >= 80) return '훌륭해요! 성경을 잘 알고 계시네요! 👏';
    if (score >= 70) return '잘하셨어요! 조금만 더 공부하면 완벽해요! 💪';
    if (score >= 60) return '괜찮아요! 계속 도전해보세요! 😊';
    if (score >= 50) return '아쉬워요! 다시 한번 도전해보세요! 🔥';
    return '포기하지 마세요! 성경을 더 읽어보세요! 📖';
  }
}
