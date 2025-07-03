import 'package:flutter/material.dart';

/// 테마와 무관하게 공통적으로 사용하는 컬러(로고, 경계 등)
class CommonColors {
  static const error = Color(0xFFE66B6B);
  static const success = Color(0xFF4BB97B);
  static const info = Color(0xFF4F80FF);
  static const warning = Color(0xFFFFA629);
  static const transparent = Colors.transparent;
}

/// 밝은 베이지/우드톤 (Light)
class LightColors {
  static const background = Color(0xFFE9E1D3);
  static const primary = Color(0xFF7A5E38);
  static const secondary = Color(0xFFD2B48C);
  static const surface = Color(0xFFF6F0E6);
  static const onPrimary = Colors.white;
  static const onSecondary = Color(0xFF473920);
  static const onBackground = Color(0xFF473920);
  static const onSurface = Color(0xFF6B5844);

  // 텍스트
  static const display = Color(0xFF473920);
  static const headline = Color(0xFF7A5E38);
  static const body = Color(0xFF473920);
  static const bodyMedium = Color(0xFF7A5E38);
  static const bodySmall = Color(0xFFD2B48C);
  static const label = Color(0xFF7A5E38);
  static const labelSmall = Color(0xFFC0A375);

  // AppBar/BottomNav
  static const appBar = Color(0xFFDED1B9);
  static const cardBorder = Color(0xFFD8CDBA);
  static const cardSurfaceTint = Color(0xFFE6DDCC);

  // 기타
  static const fabFill = Color(0xFF7A5E38);
  static const inputFill = Color(0xFFF4EADB);
  static const divider = Color(0xFFD8CDBA);
}

/// 다크 베이지/우드톤 (Dark)
class DarkColors {
  static const background = Color(0xFF32281B);
  static const primary = Color(0xFFC0A375);
  static const secondary = Color(0xFF9C805B);
  static const surface = Color(0xFF473920);
  static const onPrimary = Colors.black;
  static const onSecondary = Color(0xFFF5E7C5);
  static const onBackground = Color(0xFFF5E7C5);
  static const onSurface = Color(0xFFF3E7D7);

  // 텍스트
  static const display = Color(0xFFF5E7C5);
  static const headline = Color(0xFFC0A375);
  static const body = Color(0xFFF3E7D7);
  static const bodyMedium = Color(0xFFC0A375);
  static const bodySmall = Color(0xFF9C805B);
  static const label = Color(0xFFC0A375);
  static const labelSmall = Color(0xFFF5E7C5);

  // AppBar/BottomNav
  static const appBar = Color(0xFF473920);
  static const cardBorder = Color(0xFF7D664B);
  static const cardSurfaceTint = Color(0xFF473920);

  // 기타
  static const fabFill = Color(0xFFC0A375);
  static const inputFill = Color(0xFF473920);
  static const divider = Color(0xFF7D664B);
}
