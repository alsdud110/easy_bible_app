import 'package:flutter/material.dart';

/// 공통 컬러
class CommonColors {
  static const error = Color(0xFFFF6B6B); // 부드러운 빨강
  static const success = Color(0xFF51CF66); // 생동감 있는 초록
  static const info = Color(0xFF4DABF7); // 밝은 파랑
  static const warning = Color(0xFFFFB84D); // 따뜻한 노랑
  static const transparent = Colors.transparent;
}

/// 라이트 테마 - 2025 트렌드 (부드러운 베이지 + 바이올렛 포인트)
class LightColors {
  // 배경 - 따뜻한 화이트/베이지 톤
  static const background = Color(0xFFFAF9F6); // 크림 화이트
  static const surface = Color(0xFFFFFFFF); // 퓨어 화이트

  // 메인 컬러 - 모던한 바이올렛/인디고
  static const primary = Color(0xFF6366F1); // 인디고 (트렌디!)
  static const secondary = Color(0xFF8B5CF6); // 바이올렛
  static const accent = Color(0xFFEC4899); // 핑크 포인트

  // 회색 톤 - 부드러운 그레이
  static const divider = Color(0xFFE5E7EB);
  static const card = Color(0xFFFFFFFF);

  static const onPrimary = Colors.white;
  static const onSecondary = Colors.white;
  static const onBackground = Color(0xFF1F2937);
  static const onSurface = Color(0xFF111827);

  // 텍스트 - 부드러운 다크 그레이
  static const display = Color(0xFF111827); // 거의 블랙
  static const headline = Color(0xFF1F2937); // 다크 그레이
  static const body = Color(0xFF374151); // 미디엄 그레이
  static const bodyMedium = Color(0xFF6B7280); // 그레이
  static const bodySmall = Color(0xFF9CA3AF); // 라이트 그레이
  static const label = Color(0xFF4B5563);
  static const labelSmall = Color(0xFF9CA3AF);

  // UI 요소
  static const appBar = Color(0xFFFFFFFF);
  static const cardBorder = Color(0xFFF3F4F6);
  static const cardSurfaceTint = Colors.white;
  static const fabFill = Color(0xFF6366F1);
  static const inputFill = Color(0xFFF9FAFB);
}

/// 다크 테마 - 2025 트렌드 (딥 다크 + 네온 포인트)
class DarkColors {
  // 배경 - 순수한 다크 그레이 (중립적)
  static const background = Color(0xFF121212); // Material Design 다크 배경
  static const surface = Color(0xFF1E1E1E); // 네이비 그레이

  // 메인 컬러 - 생동감 있는 네온 컬러
  static const primary = Color(0xFF818CF8); // 브라이트 인디고
  static const secondary = Color(0xFFA78BFA); // 브라이트 바이올렛
  static const accent = Color(0xFFF472B6); // 네온 핑크

  // 회색 톤 - 블루 틴트 제거
  static const divider = Color(0xFF2C2C2C);
  static const card = Color(0xFF1A1A1A);

  static const onPrimary = Color(0xFF121212);
  static const onSecondary = Color(0xFF121212);
  static const onBackground = Color(0xFFF9FAFB);
  static const onSurface = Color(0xFFE5E7EB);

  // 텍스트 - 부드러운 화이트 그레이
  static const display = Color(0xFFF9FAFB); // 밝은 화이트
  static const headline = Color(0xFFE5E7EB); // 라이트 그레이
  static const body = Color(0xFFD1D5DB); // 미디엄 라이트 그레이
  static const bodyMedium = Color(0xFF9CA3AF); // 그레이
  static const bodySmall = Color(0xFF6B7280); // 다크 그레이
  static const label = Color(0xFFD1D5DB);
  static const labelSmall = Color(0xFF6B7280);

  // UI 요소
  static const appBar = Color(0xFF1A1A1A);
  static const cardBorder = Color(0xFF2C2C2C);
  static const cardSurfaceTint = Color(0xFF1E1E1E);
  static const fabFill = Color(0xFF818CF8);
  static const inputFill = Color(0xFF1E1E1E);
}
