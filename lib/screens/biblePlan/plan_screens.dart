import 'package:flutter/material.dart';
import '../../models/plan_progress.dart';
import 'day60_screen.dart';
import 'day120_screen.dart';
import 'day180_screen.dart';
import 'day365_screen.dart';

/// 플랜 타입 → 일자 목록 화면
Widget buildPlanDayScreen(PlanType planType) {
  switch (planType) {
    case PlanType.day60:
      return const Day60Screen();
    case PlanType.day120:
      return const Day120Screen();
    case PlanType.day180:
      return const Day180Screen();
    case PlanType.day365:
      return const Day365Screen();
  }
}

/// 알림 payload("day60" 등) → 플랜 타입. 알 수 없는 값이면 null.
PlanType? planTypeFromPayload(String? payload) {
  for (final type in PlanType.values) {
    if (type.name == payload) return type;
  }
  return null;
}

/// 데이터 준비 전인 플랜(365)을 눌렀을 때 안내
void showPlanComingSoon(BuildContext context, PlanType planType) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text('${planType.title}은(는) 곧 열립니다. 조금만 기다려 주세요!')),
    );
}
