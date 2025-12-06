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
  int get score =>
      totalQuestions == 0 ? 0 : ((correctCount / totalQuestions) * 100).round();

  /// 정답률 (0.0-1.0)
  double get accuracy =>
      totalQuestions == 0 ? 0.0 : correctCount / totalQuestions;

  /// 별점 (0.0-5.0, 0.5 단위)
  double get stars {
    // 10문제 기준: 1문제당 0.5개씩
    // 정답 개수에 비례하여 계산
    return (correctCount * 5.0) / totalQuestions;
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
    if (score == 100) return '완벽합니다! 성경 마스터이시네요! 🏆';
    if (score >= 90) return '훌륭해요! 성경 박사 수준이에요! 📚';
    if (score >= 80) return '아주 잘하셨어요! 좋은 실력이에요! ✨';
    if (score >= 70) return '잘하셨어요! 조금만 더 노력하면 완벽해요! 💪';
    if (score >= 60) return '괜찮아요! 꾸준히 하면 더 좋아질 거예요! 😊';
    if (score >= 50) return '절반은 맞췄어요! 포기하지 마세요! 🌟';
    if (score >= 40) return '조금 아쉬워요! 다시 한번 도전해보세요! 🔥';
    if (score >= 30) return '더 공부하면 충분히 잘할 수 있어요! 📝';
    if (score >= 20) return '많은 연습이 필요해요! 성경을 더 읽어보세요! 📖';
    if (score >= 10) return '기초부터 차근차근 배워봐요! 🌱';
    return '괜찮아요! 처음부터 다시 시작해봐요! 🚀';
  }
}
