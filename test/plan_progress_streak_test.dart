import 'package:easy_bible_app/models/plan_progress.dart';
import 'package:flutter_test/flutter_test.dart';

String _key(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

PlanProgress _plan(Map<int, String> dates) => PlanProgress(
      id: 't',
      planType: PlanType.day60,
      planName: 't',
      startDate: DateTime.now(),
      completedDays: dates.keys.toSet(),
      completedDayDates: dates,
    );

void main() {
  final now = DateTime.now();
  DateTime daysAgo(int n) => DateTime(now.year, now.month, now.day - n);

  test('기록 없으면 0', () {
    expect(_plan({}).currentStreak, 0);
  });

  test('오늘까지 3일 연속', () {
    final p = _plan({1: _key(daysAgo(2)), 2: _key(daysAgo(1)), 3: _key(now)});
    expect(p.currentStreak, 3);
  });

  test('오늘 안 읽었어도 어제까지 이어지면 연속', () {
    final p = _plan({1: _key(daysAgo(2)), 2: _key(daysAgo(1))});
    expect(p.currentStreak, 2);
  });

  test('하루 빠지면 끊김', () {
    final p = _plan({1: _key(daysAgo(3)), 2: _key(now)});
    expect(p.currentStreak, 1);
  });

  test('하루에 여러 일차를 읽어도 1일로 계산', () {
    final p = _plan({1: _key(now), 2: _key(now)});
    expect(p.currentStreak, 1);
  });

  test('완료 시 날짜 기록, 취소 시 제거, JSON 왕복 유지', () {
    var p = _plan({}).markDayAsCompleted(1);
    expect(p.completedDayDates[1], _key(now));
    expect(p.currentStreak, 1);

    final restored = PlanProgress.fromJson(p.toJson());
    expect(restored.completedDayDates, p.completedDayDates);

    p = p.unmarkDayAsCompleted(1);
    expect(p.completedDayDates.containsKey(1), isFalse);
  });

  test('예전 저장 데이터(날짜 필드 없음)도 읽힘', () {
    final json = _plan({}).toJson()..remove('completedDayDates');
    expect(PlanProgress.fromJson(json).currentStreak, 0);
  });
}
