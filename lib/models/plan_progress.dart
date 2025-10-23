enum PlanType {
  day60(60, '성경 60일 통독'),
  day120(120, '성경 120일 통독'),
  day180(180, '성경 180일 통독');

  final int totalDays;
  final String defaultName;

  const PlanType(this.totalDays, this.defaultName);
}

class PlanProgress {
  final String id; // 고유 ID
  final PlanType planType; // 60일, 120일, 180일
  final String planName; // 사용자 지정 플랜명 (기본: "성경 60일 통독")
  final DateTime startDate; // 시작일
  final Set<int> completedDays; // 완료한 Day 목록 (1, 2, 3...)
  final DateTime? notificationTime; // 알림 시간 (선택사항)
  final DateTime? completedDate; // 완주일 (모든 Day 완료 시)

  PlanProgress({
    required this.id,
    required this.planType,
    required this.planName,
    required this.startDate,
    Set<int>? completedDays,
    this.notificationTime,
    this.completedDate,
  }) : completedDays = completedDays ?? {};

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

    return PlanProgress(
      id: json['id'] as String,
      planType: PlanType.values.firstWhere(
        (type) => type.name == json['planType'],
        orElse: () => PlanType.day60,
      ),
      planName: json['planName'] as String,
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
  }) {
    return PlanProgress(
      id: id ?? this.id,
      planType: planType ?? this.planType,
      planName: planName ?? this.planName,
      startDate: startDate ?? this.startDate,
      completedDays: completedDays ?? this.completedDays,
      notificationTime: notificationTime ?? this.notificationTime,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  // Day 완료 추가
  PlanProgress markDayAsCompleted(int day) {
    final newCompletedDays = Set<int>.from(completedDays)..add(day);
    final isNowCompleted = newCompletedDays.length >= planType.totalDays;

    return copyWith(
      completedDays: newCompletedDays,
      completedDate: isNowCompleted && completedDate == null
          ? DateTime.now()
          : completedDate,
    );
  }

  // Day 완료 취소
  PlanProgress unmarkDayAsCompleted(int day) {
    final newCompletedDays = Set<int>.from(completedDays)..remove(day);

    return copyWith(
      completedDays: newCompletedDays,
      completedDate: null, // 완료 취소 시 완주일도 초기화
    );
  }
}
