import 'dart:convert';

import 'package:easy_bible_app/services/quiz_history_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 정답 데이터를 고친 뒤 예전 기록을 열면 지금 정답으로 다시 채점되는지 확인
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('예전 기록의 틀린 정답을 지금 데이터로 바로잡음', () async {
    // mc_hard_085(첫째 대접)는 예전 데이터에서 정답이 1("강과 물")이었고, 지금은 3("땅")
    final record = {
      'question': {
        'id': 'mc_hard_085',
        'difficulty': 'hard',
        'question': '요한계시록에서 일곱 대접 재앙이 내릴 때, 첫 번째 재앙은 무엇과 관련이 있는가?',
        'reference': '요한계시록 16:1-2',
        'explanation': '예전 해설',
        'options': ['바다', '강과 물', '하늘', '땅'],
        'correctIndex': 1,
      },
      'userAnswer': 3,
      'isCorrect': false,
      'answeredAt': '2026-11-01T00:00:00.000',
    };
    SharedPreferences.setMockInitialValues({
      'quiz_history': jsonEncode([
        {
          'id': '1',
          'quizType': 'multipleChoice',
          'difficulty': 'hard',
          'completedAt': '2026-11-01T00:00:00.000',
          'totalQuestions': 1,
          'correctCount': 0,
          'score': 0,
          'answerRecords': [record],
        }
      ]),
    });

    final item = (await QuizHistoryService().getHistory()).single;
    expect(item.answerRecords.single.isCorrect, isTrue);
    expect(item.answerRecords.single.question.correctIndex, 3);
    expect(item.correctCount, 1);
    expect(item.score, 100);
  });
}
