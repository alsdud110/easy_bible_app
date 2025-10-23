import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plan_progress.dart';

class PlanProgressProvider with ChangeNotifier {
  static const String _storageKey = 'plan_progress';
  PlanProgress? _currentPlan;
  bool _isLoaded = false;

  PlanProgress? get currentPlan => _currentPlan;
  bool get isLoaded => _isLoaded;
  bool get hasPlan => _currentPlan != null;

  // 초기 로드
  Future<void> loadPlan() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final jsonData = json.decode(jsonString);
        _currentPlan = PlanProgress.fromJson(jsonData);
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('플랜 로드 실패: $e');
      _currentPlan = null;
      _isLoaded = true;
    }
  }

  // 저장
  Future<void> _savePlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentPlan != null) {
        final jsonString = json.encode(_currentPlan!.toJson());
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

    _currentPlan = PlanProgress(
      id: now.millisecondsSinceEpoch.toString(),
      planType: planType,
      planName: planName,
      startDate: now,
      notificationTime: notificationTime,
    );

    notifyListeners();
    await _savePlan();
  }

  // Day 완료 처리
  Future<void> markDayAsCompleted(int day) async {
    if (_currentPlan == null) return;

    final updatedPlan = _currentPlan!.markDayAsCompleted(day);
    _currentPlan = updatedPlan;

    notifyListeners();
    await _savePlan();
  }

  // Day 완료 취소
  Future<void> unmarkDayAsCompleted(int day) async {
    if (_currentPlan == null) return;

    final updatedPlan = _currentPlan!.unmarkDayAsCompleted(day);
    _currentPlan = updatedPlan;

    notifyListeners();
    await _savePlan();
  }

  // 특정 Day 완료 여부 확인
  bool isDayCompleted(int day) {
    return _currentPlan?.isDayCompleted(day) ?? false;
  }

  // 특정 Day 접근 가능 여부 확인
  bool canAccessDay(int day) {
    return _currentPlan?.canAccessDay(day) ?? false;
  }

  // 플랜 이름 변경
  Future<void> updatePlanName(String newName) async {
    if (_currentPlan == null) return;

    _currentPlan = _currentPlan!.copyWith(planName: newName);
    notifyListeners();
    await _savePlan();
  }

  // 알림 시간 변경
  Future<void> updateNotificationTime(DateTime? newTime) async {
    if (_currentPlan == null) return;

    _currentPlan = _currentPlan!.copyWith(notificationTime: newTime);
    notifyListeners();
    await _savePlan();
  }

  // 플랜 삭제 (초기화)
  Future<void> deletePlan() async {
    _currentPlan = null;
    notifyListeners();
    await _savePlan();
  }

  // 플랜 완주 여부
  bool get isPlanCompleted => _currentPlan?.isCompleted ?? false;

  // 진행률 (0.0 ~ 1.0)
  double get progressPercentage => _currentPlan?.progressPercentage ?? 0.0;

  // 진행률 백분율 (0 ~ 100)
  int get progressPercent => _currentPlan?.progressPercent ?? 0;

  // 완료한 Day 수
  int get completedDaysCount => _currentPlan?.completedDays.length ?? 0;

  // 전체 Day 수
  int get totalDays => _currentPlan?.planType.totalDays ?? 0;

  // 다음 읽을 Day
  int get nextDay => _currentPlan?.nextDay ?? 1;

  // 경과 일수
  int get elapsedDays => _currentPlan?.elapsedDays ?? 0;

  // 플랜 유형별 필터링
  bool isPlanType(PlanType type) {
    return _currentPlan?.planType == type;
  }
}
