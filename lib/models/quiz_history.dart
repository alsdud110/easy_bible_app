import 'quiz_question.dart';
import 'quiz_result.dart';

/// 퀴즈 히스토리 아이템 - 저장용 모델
class QuizHistoryItem {
  final String id; // 고유 ID
  final QuizType quizType;
  final Difficulty difficulty;
  final DateTime completedAt;
  final int totalQuestions;
  final int correctCount;
  final int score;
  final List<QuizAnswerRecord> answerRecords;

  QuizHistoryItem({
    required this.id,
    required this.quizType,
    required this.difficulty,
    required this.completedAt,
    required this.totalQuestions,
    required this.correctCount,
    required this.score,
    required this.answerRecords,
  });

  /// QuizResult로부터 생성
  factory QuizHistoryItem.fromQuizResult(QuizResult result) {
    return QuizHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      quizType: result.quizType,
      difficulty: result.difficulty,
      completedAt: result.completedAt,
      totalQuestions: result.totalQuestions,
      correctCount: result.correctCount,
      score: result.score,
      answerRecords: result.answers
          .map((answer) => QuizAnswerRecord.fromQuizAnswer(answer))
          .toList(),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quizType': quizType.name,
      'difficulty': difficulty.name,
      'completedAt': completedAt.toIso8601String(),
      'totalQuestions': totalQuestions,
      'correctCount': correctCount,
      'score': score,
      'answerRecords': answerRecords.map((r) => r.toJson()).toList(),
    };
  }

  /// JSON에서 생성
  factory QuizHistoryItem.fromJson(Map<String, dynamic> json) {
    return QuizHistoryItem(
      id: json['id'] as String,
      quizType: QuizType.values.firstWhere(
        (e) => e.name == json['quizType'],
        orElse: () => QuizType.ox,
      ),
      difficulty: Difficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => Difficulty.easy,
      ),
      completedAt: DateTime.parse(json['completedAt'] as String),
      totalQuestions: json['totalQuestions'] as int,
      correctCount: json['correctCount'] as int,
      score: json['score'] as int,
      answerRecords: (json['answerRecords'] as List)
          .map((r) => QuizAnswerRecord.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 오답 수
  int get incorrectCount => totalQuestions - correctCount;

  /// 정답률
  double get accuracy =>
      totalQuestions == 0 ? 0.0 : correctCount / totalQuestions;

  /// 정답만 필터링
  List<QuizAnswerRecord> get correctAnswers =>
      answerRecords.where((r) => r.isCorrect).toList();

  /// 오답만 필터링
  List<QuizAnswerRecord> get incorrectAnswers =>
      answerRecords.where((r) => !r.isCorrect).toList();
}

/// 퀴즈 답변 기록 - 저장용 모델
class QuizAnswerRecord {
  final QuizQuestion question;
  final dynamic userAnswer; // bool (OX) or int (객관식 index)
  final bool isCorrect;
  final DateTime answeredAt;

  QuizAnswerRecord({
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    required this.answeredAt,
  });

  /// QuizAnswer로부터 생성
  factory QuizAnswerRecord.fromQuizAnswer(QuizAnswer answer) {
    return QuizAnswerRecord(
      question: answer.question,
      userAnswer: answer.userAnswer,
      isCorrect: answer.isCorrect,
      answeredAt: answer.answeredAt,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'question': question.toJson(),
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }

  /// JSON에서 생성
  factory QuizAnswerRecord.fromJson(Map<String, dynamic> json) {
    final questionJson = json['question'] as Map<String, dynamic>;

    // QuizType 판단 (answer 필드 유무로 확인)
    final quizType = questionJson.containsKey('answer') && questionJson['answer'] != null
        ? QuizType.ox
        : QuizType.multipleChoice;

    return QuizAnswerRecord(
      question: QuizQuestion.fromJson(questionJson, quizType),
      userAnswer: json['userAnswer'],
      isCorrect: json['isCorrect'] as bool,
      answeredAt: DateTime.parse(json['answeredAt'] as String),
    );
  }

  /// 사용자 답변 텍스트 가져오기
  String get userAnswerText {
    if (question.isOX) {
      return userAnswer == true ? 'O' : 'X';
    } else {
      final labels = ['A', 'B', 'C', 'D'];
      final index = userAnswer as int;
      if (question.options != null && index < question.options!.length) {
        return '${labels[index]}. ${question.options![index]}';
      }
      return '선택 없음';
    }
  }

  /// 정답 텍스트 가져오기
  String get correctAnswerText {
    if (question.isOX) {
      return question.answer == true ? 'O' : 'X';
    } else {
      final labels = ['A', 'B', 'C', 'D'];
      if (question.correctIndex != null &&
          question.options != null &&
          question.correctIndex! < question.options!.length) {
        return '${labels[question.correctIndex!]}. ${question.options![question.correctIndex!]}';
      }
      return '정답 없음';
    }
  }
}
