import 'bible_60.dart';
import 'bible_120.dart';
import 'bible_180.dart';
import 'bible_365.dart';

/// 성경일독 플랜 종류.
/// 화면에 보이는 이름/설명은 여기 한 곳에서만 관리한다.
enum PlanType {
  day60(60, '60일 성경일독', '두 달 동안 몰입해서 완독'),
  day120(120, '120일 성경일독', '넉 달 동안 꾸준하게 완독'),
  day180(180, '180일 성경일독', '반년 동안 여유 있게 완독'),
  day365(365, '365일 성경일독', '하루 한 걸음, 일 년 동안 완독');

  final int totalDays;

  /// 화면 표시용 이름 (예: "60일 성경일독")
  final String title;

  /// 플랜 선택 화면의 한 줄 설명
  final String description;

  const PlanType(this.totalDays, this.title, this.description);

  /// 새 플랜 시작 시 기본 플랜명
  String get defaultName => title;

  /// 일자별 읽기 범위 데이터
  List<List<String>> get readings {
    switch (this) {
      case PlanType.day60:
        return bible60;
      case PlanType.day120:
        return bible120;
      case PlanType.day180:
        return bible180;
      case PlanType.day365:
        return bible365;
    }
  }

  /// 읽기 데이터가 준비되었는지 (365 플랜은 데이터 추가 전까지 '준비 중')
  bool get isAvailable => readings.isNotEmpty;
}

class PlanProgress {
  final String id; // 고유 ID
  final PlanType planType; // 60일, 120일, 180일, 365일
  final String planName; // 사용자 지정 플랜명 (기본: PlanType.title)
  final DateTime startDate; // 시작일
  final Set<int> completedDays; // 완료한 Day 목록 (1, 2, 3...)
  final DateTime? notificationTime; // 알림 시간 (선택사항)
  final DateTime? completedDate; // 완주일 (모든 Day 완료 시)
  // Day별 완료한 날짜(yyyy-MM-dd). 연속 일수 계산용. 이 필드 추가 전 기록은 날짜가 없다
  final Map<int, String> completedDayDates;

  PlanProgress({
    required this.id,
    required this.planType,
    required this.planName,
    required this.startDate,
    Set<int>? completedDays,
    this.notificationTime,
    this.completedDate,
    Map<int, String>? completedDayDates,
  })  : completedDays = completedDays ?? {},
        completedDayDates = completedDayDates ?? {};

  // 진행률 계산 (0.0 ~ 1.0)
  double get progressPercentage {
    if (planType.totalDays == 0) return 0.0;
    return completedDays.length / planType.totalDays;
  }

  // 진행률 백분율 (0 ~ 100)
  int get progressPercent => (progressPercentage * 100).round();

  // 완주 여부
  bool get isCompleted => completedDays.length >= planType.totalDays;

  // 특정 Day 완료 여부
  bool isDayCompleted(int day) => completedDays.contains(day);

  // 특정 Day 접근 가능 여부 (이전 Day를 완료했거나 Day 1인 경우)
  bool canAccessDay(int day) {
    if (day <= 0 || day > planType.totalDays) return false;
    if (day == 1) return true; // Day 1은 항상 접근 가능
    return completedDays.contains(day - 1); // 이전 Day를 완료했으면 접근 가능
  }

  // 다음 읽을 Day 계산
  int get nextDay {
    for (int day = 1; day <= planType.totalDays; day++) {
      if (!completedDays.contains(day)) {
        return day;
      }
    }
    return planType.totalDays; // 모두 완료한 경우 마지막 Day 반환
  }

  /// 오늘(또는 어제)까지 하루도 빠지지 않고 일독한 연속 일수.
  /// 오늘 아직 안 읽었어도 어제까지 이어져 있으면 연속으로 본다.
  int get currentStreak {
    final dates = completedDayDates.values.toSet();
    if (dates.isEmpty) return 0;
    var cursor = DateTime.now();
    if (!dates.contains(_dateKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!dates.contains(_dateKey(cursor))) return 0;
    }
    var streak = 0;
    while (dates.contains(_dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static String _dateKey(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  // 경과 일수
  int get elapsedDays {
    final now = DateTime.now();
    return now.difference(startDate).inDays;
  }

  // JSON 변환
  Map<String, dynamic> toJson() => {
        'id': id,
        'planType': planType.name,
        'planName': planName,
        'startDate': startDate.millisecondsSinceEpoch,
        'completedDays': completedDays.toList(),
        'notificationTime': notificationTime?.millisecondsSinceEpoch,
        'completedDate': completedDate?.millisecondsSinceEpoch,
        'completedDayDates':
            completedDayDates.map((k, v) => MapEntry(k.toString(), v)),
      };

  factory PlanProgress.fromJson(Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    final planType = PlanType.values.firstWhere(
      (type) => type.name == json['planType'],
      orElse: () => PlanType.day60,
    );
    // 예전 기본 이름으로 저장된 플랜은 현재 기본 이름으로 바꿔 보여 준다 (직접 지은 이름은 유지)
    final storedName = json['planName'] as String;
    final n = planType.totalDays;
    final isOldDefault = storedName == '성경 $n일 통독' ||
        storedName == '$n일 성경읽기' ||
        storedName == '365 성경읽기';

    return PlanProgress(
      id: json['id'] as String,
      planType: planType,
      planName: isOldDefault ? planType.title : storedName,
      startDate: parseDateTime(json['startDate']),
      completedDays: (json['completedDays'] as List<dynamic>?)
              ?.map((d) => d as int)
              .toSet() ??
          {},
      notificationTime: json['notificationTime'] != null
          ? parseDateTime(json['notificationTime'])
          : null,
      completedDate: json['completedDate'] != null
          ? parseDateTime(json['completedDate'])
          : null,
      completedDayDates:
          (json['completedDayDates'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(int.parse(k), v as String),
              ) ??
              {},
    );
  }

  // copyWith 메서드
  PlanProgress copyWith({
    String? id,
    PlanType? planType,
    String? planName,
    DateTime? startDate,
    Set<int>? completedDays,
    DateTime? notificationTime,
    DateTime? completedDate,
    Map<int, String>? completedDayDates,
  }) {
    return PlanProgress(
      id: id ?? this.id,
      planType: planType ?? this.planType,
      planName: planName ?? this.planName,
      startDate: startDate ?? this.startDate,
      completedDays: completedDays ?? this.completedDays,
      notificationTime: notificationTime ?? this.notificationTime,
      completedDate: completedDate ?? this.completedDate,
      completedDayDates: completedDayDates ?? this.completedDayDates,
    );
  }

  // Day 완료 추가
  PlanProgress markDayAsCompleted(int day) {
    final newCompletedDays = Set<int>.from(completedDays)..add(day);
    final isNowCompleted = newCompletedDays.length >= planType.totalDays;

    final newDates = Map<int, String>.from(completedDayDates)
      ..[day] = _dateKey(DateTime.now());

    return copyWith(
      completedDays: newCompletedDays,
      completedDayDates: newDates,
      completedDate: isNowCompleted && completedDate == null
          ? DateTime.now()
          : completedDate,
    );
  }

  // Day 완료 취소
  PlanProgress unmarkDayAsCompleted(int day) {
    final newCompletedDays = Set<int>.from(completedDays)..remove(day);
    final newDates = Map<int, String>.from(completedDayDates)..remove(day);

    return copyWith(
      completedDays: newCompletedDays,
      completedDayDates: newDates,
      completedDate: null, // 완료 취소 시 완주일도 초기화
    );
  }
}
