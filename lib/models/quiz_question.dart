/// 퀴즈 유형
enum QuizType {
  ox,
  multipleChoice;

  String get displayName {
    switch (this) {
      case QuizType.ox:
        return 'OX 퀴즈';
      case QuizType.multipleChoice:
        return '객관식';
    }
  }

  String get icon {
    switch (this) {
      case QuizType.ox:
        return '⭕️';
      case QuizType.multipleChoice:
        return '📝';
    }
  }
}

/// 난이도
enum Difficulty {
  easy,
  medium,
  hard;

  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return '쉬움';
      case Difficulty.medium:
        return '보통';
      case Difficulty.hard:
        return '어려움';
    }
  }

  String get emoji {
    switch (this) {
      case Difficulty.easy:
        return '🌱';
      case Difficulty.medium:
        return '🌿';
      case Difficulty.hard:
        return '🌳';
    }
  }
}

/// 퀴즈 문제 모델
class QuizQuestion {
  final String id;
  final Difficulty difficulty;
  final String question;
  final String? reference;
  final String? explanation;

  // OX 퀴즈용
  final bool? answer;

  // 객관식용
  final List<String>? options;
  final int? correctIndex;

  QuizQuestion({
    required this.id,
    required this.difficulty,
    required this.question,
    this.reference,
    this.explanation,
    this.answer,
    this.options,
    this.correctIndex,
  });

  /// OX 퀴즈인지 확인
  bool get isOX => answer != null;

  /// 객관식 퀴즈인지 확인
  bool get isMultipleChoice => options != null && correctIndex != null;

  /// QuizType 반환
  QuizType get type => isOX ? QuizType.ox : QuizType.multipleChoice;

  /// JSON에서 생성
  factory QuizQuestion.fromJson(Map<String, dynamic> json, QuizType type) {
    final difficultyStr = json['difficulty'] as String;
    final difficulty = Difficulty.values.firstWhere(
      (e) => e.name == difficultyStr,
      orElse: () => Difficulty.easy,
    );

    if (type == QuizType.ox) {
      return QuizQuestion(
        id: json['id'] as String,
        difficulty: difficulty,
        question: json['question'] as String,
        reference: json['reference'] as String?,
        explanation: json['explanation'] as String?,
        answer: json['answer'] as bool,
      );
    } else {
      return QuizQuestion(
        id: json['id'] as String,
        difficulty: difficulty,
        question: json['question'] as String,
        reference: json['reference'] as String?,
        explanation: json['explanation'] as String?,
        options: (json['options'] as List).cast<String>(),
        correctIndex: json['correctIndex'] as int,
      );
    }
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    if (isOX) {
      return {
        'id': id,
        'difficulty': difficulty.name,
        'question': question,
        'reference': reference,
        'explanation': explanation,
        'answer': answer,
      };
    } else {
      return {
        'id': id,
        'difficulty': difficulty.name,
        'question': question,
        'reference': reference,
        'explanation': explanation,
        'options': options,
        'correctIndex': correctIndex,
      };
    }
  }
}
