import 'package:flutter/material.dart';

/// 공통 컬러 (로고, 경계 등)
class CommonColors {
  static const error = Color(0xFFF44336); // 빨강
  static const success = Color(0xFF4CAF50); // 초록
  static const info = Color(0xFF2196F3); // 파랑
  static const warning = Color(0xFFFFC107); // 노랑
  static const transparent = Colors.transparent;
}

/// 밝은 라이트 테마 (화이트 + 연한 회색)
class LightColors {
  static const background = Color(0xFFF8F9FB); // 연한 회색(배경)
  static const surface = Color(0xFFF1F3F6); // 카드/표면용 더 연한 회색
  static const primary = Colors.black; // 기본 텍스트
  static const secondary = Color(0xFF444444); // 강조용 짙은 회색
  static const accent = Color(0xFFB0B7C3); // 매우 연한 회색 (구분선 등)
  static const divider = Color(0xFFE0E3EB); // 연회색 (divider)
  static const card = Color(0xFFF7F8FA); // 카드
  static const onPrimary = Colors.white;
  static const onSecondary = Colors.white;
  static const onBackground = Colors.black;
  static const onSurface = Colors.black87;

  // 텍스트
  static const display = Colors.black;
  static const headline = Colors.black87;
  static const body = Color(0xFF21232A);
  static const bodyMedium = Colors.black54;
  static const bodySmall = Color(0xFF888888);
  static const label = Colors.black87;
  static const labelSmall = Color(0xFFB0B7C3);

  // AppBar/BottomNav
  static const appBar = Colors.white;
  static const cardBorder = Color(0xFFDADDE5);
  static const cardSurfaceTint = Colors.white;

  // 기타
  static const fabFill = Colors.black;
  static const inputFill = Color(0xFFF2F3F6);
}

/// 다크 테마 (블랙 + 진한 회색)
class DarkColors {
  static const background = Color(0xFF15181D); // 거의 검정에 가까운 진회색
  static const surface = Color(0xFF23262B); // 카드/표면 진한 회색
  static const primary = Colors.white; // 기본 텍스트
  static const secondary = Color(0xFFBBBBBB); // 강조용 회색
  static const accent = Color(0xFF373A40); // 더 진한 회색 (divider 등)
  static const divider = Color(0xFF343740); // 진회색 (divider)
  static const card = Color(0xFF1C1F24); // 카드
  static const onPrimary = Colors.black;
  static const onSecondary = Colors.black;
  static const onBackground = Colors.white;
  static const onSurface = Colors.white70;

  // 텍스트
  static const display = Colors.white;
  static const headline = Colors.white70;
  static const body = Color(0xFFE8EAED);
  static const bodyMedium = Colors.white60;
  static const bodySmall = Color(0xFF888888);
  static const label = Colors.white70;
  static const labelSmall = Color(0xFF888888);

  // AppBar/BottomNav
  static const appBar = Color(0xFF181A20);
  static const cardBorder = Color(0xFF282A31);
  static const cardSurfaceTint = Color(0xFF23262B);

  // 기타
  static const fabFill = Colors.white;
  static const inputFill = Color(0xFF23262B);
}
