import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plan_progress.dart';

class PlanProgressProvider with ChangeNotifier {
  static const String _storageKey = 'plan_progress_multi';
  Map<PlanType, PlanProgress> _plans = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  // 전체 플랜 맵
  Map<PlanType, PlanProgress> get plans => _plans;

  // 특정 타입의 플랜 가져오기
  PlanProgress? getPlan(PlanType type) => _plans[type];

  // 특정 타입의 플랜이 있는지
  bool hasPlan(PlanType type) => _plans.containsKey(type);

  // 어떤 플랜이라도 있는지
  bool get hasAnyPlan => _plans.isNotEmpty;

  // 초기 로드
  Future<void> loadPlan() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;
        _plans = {};

        jsonData.forEach((key, value) {
          final planType = PlanType.values.firstWhere(
            (e) => e.name == key,
            orElse: () => PlanType.day60,
          );
          _plans[planType] = PlanProgress.fromJson(value as Map<String, dynamic>);
        });
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('플랜 로드 실패: $e');
      _plans = {};
      _isLoaded = true;
    }
  }

  // 저장
  Future<void> _savePlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_plans.isNotEmpty) {
        final jsonMap = <String, dynamic>{};
        _plans.forEach((key, value) {
          jsonMap[key.name] = value.toJson();
        });
        final jsonString = json.encode(jsonMap);
        await prefs.setString(_storageKey, jsonString);
      } else {
        await prefs.remove(_storageKey);
      }
    } catch (e) {
      debugPrint('플랜 저장 실패: $e');
    }
  }

  // 새 플랜 시작
  Future<void> startNewPlan({
    required PlanType planType,
    String? customPlanName,
    DateTime? notificationTime,
  }) async {
    final now = DateTime.now();
    final planName = customPlanName ?? planType.defaultName;

    _plans[planType] = PlanProgress(
      id: now.millisecondsSinceEpoch.toString(),
      planType: planType,
      planName: planName,
      startDate: now,
      notificationTime: notificationTime,
    );

    notifyListeners();
    await _savePlans();
  }

  // Day 완료 처리
  Future<void> markDayAsCompleted(PlanType planType, int day) async {
    if (!_plans.containsKey(planType)) return;

    final updatedPlan = _plans[planType]!.markDayAsCompleted(day);
    _plans[planType] = updatedPlan;

    notifyListeners();
    await _savePlans();
  }

  // Day 완료 취소
  Future<void> unmarkDayAsCompleted(PlanType planType, int day) async {
    if (!_plans.containsKey(planType)) return;

    final updatedPlan = _plans[planType]!.unmarkDayAsCompleted(day);
    _plans[planType] = updatedPlan;

    notifyListeners();
    await _savePlans();
  }

  // 특정 Day 완료 여부 확인
  bool isDayCompleted(PlanType planType, int day) {
    return _plans[planType]?.isDayCompleted(day) ?? false;
  }

  // 특정 Day 접근 가능 여부 확인
  bool canAccessDay(PlanType planType, int day) {
    return _plans[planType]?.canAccessDay(day) ?? false;
  }

  // 플랜 이름 변경
  Future<void> updatePlanName(PlanType planType, String newName) async {
    if (!_plans.containsKey(planType)) return;

    _plans[planType] = _plans[planType]!.copyWith(planName: newName);
    notifyListeners();
    await _savePlans();
  }

  // 알림 시간 변경
  Future<void> updateNotificationTime(PlanType planType, DateTime? newTime) async {
    if (!_plans.containsKey(planType)) return;

    _plans[planType] = _plans[planType]!.copyWith(notificationTime: newTime);
    notifyListeners();
    await _savePlans();
  }

  // 특정 플랜 삭제 (초기화)
  Future<void> deletePlan(PlanType planType) async {
    _plans.remove(planType);
    notifyListeners();
    await _savePlans();
  }

  // 플랜 완주 여부
  bool isPlanCompleted(PlanType planType) => _plans[planType]?.isCompleted ?? false;

  // 진행률 (0.0 ~ 1.0)
  double getProgressPercentage(PlanType planType) => _plans[planType]?.progressPercentage ?? 0.0;

  // 진행률 백분율 (0 ~ 100)
  int getProgressPercent(PlanType planType) => _plans[planType]?.progressPercent ?? 0;

  // 완료한 Day 수
  int getCompletedDaysCount(PlanType planType) => _plans[planType]?.completedDays.length ?? 0;

  // 전체 Day 수
  int getTotalDays(PlanType planType) => _plans[planType]?.planType.totalDays ?? 0;

  // 다음 읽을 Day
  int getNextDay(PlanType planType) => _plans[planType]?.nextDay ?? 1;

  // 경과 일수
  int getElapsedDays(PlanType planType) => _plans[planType]?.elapsedDays ?? 0;
}
