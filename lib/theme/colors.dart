import 'package:flutter/material.dart';

// 팔레트 방향: 오래 펼쳐 둔 성경책.
// 배경·카드·글자는 미색 종이와 먹색 잉크의 따뜻한 무채색 하나로,
// 강조색은 붉은 가름끈(버건디) 하나만 쓴다. 주요 버튼·선택·진행률에만.
// 그라데이션, 형광색, 색 그림자는 쓰지 않는다.
// (unslop by Damir Sokolovsky @heydamir, CC BY 4.0 기준으로 정리)

/// 공통 의미 색 (팔레트 안에 앉도록 채도를 낮춤)
class CommonColors {
  static const error = Color(0xFFB4433D); // 오류
  static const success = Color(0xFF4E7F5C); // 완료/정답
  static const info = Color(0xFF4E7F74); // 안내 (깊은 청록)
  static const warning = Color(0xFFA8792E); // 주의
  static const transparent = Colors.transparent;
}

/// 퀴즈 의미 색
/// 정답/오답만 색으로 말하고, 난이도는 작은 점 정도로만 구분한다.
class QuizColors {
  static const correct = Color(0xFF4E7F5C); // 정답 (세이지 그린)
  static const incorrect = Color(0xFFB4433D); // 오답 (벽돌 레드)
  static const difficultyEasy = Color(0xFF6E8B66); // 쉬움
  static const difficultyMedium = Color(0xFFA8792E); // 보통
  static const difficultyHard = Color(0xFFB4433D); // 어려움
  static const star = Color(0xFFC29A45); // 별점 (바랜 금박)
}

/// 라이트 테마: 미색 종이 + 먹색 잉크 + 가름끈 버건디
class LightColors {
  // 표면 (종이)
  static const background = Color(0xFFF7F4EE); // 페이지 배경
  static const surface = Color(0xFFFDFBF7); // 카드
  static const raised = Color(0xFFEFE9DF); // 입력칸, 선택된 행
  static const deepest = Color(0xFFEDE7DC); // 가장 깊은 면

  // 강조 (가름끈)
  static const primary = Color(0xFF8C2F2B); // 버건디. 흰 글자와 대비 약 8:1
  static const primaryContainer = Color(0xFFF2E3DE); // 버건디를 아주 옅게
  static const onPrimaryContainer = Color(0xFF5E1D1A);

  // 보조색은 따로 두지 않고 먹색의 보조 톤으로 조용히
  static const secondary = Color(0xFF5E554A);
  static const accent = Color(0xFF8C2F2B);

  // 선
  static const divider = Color(0xFFE6E0D5); // 헤어라인
  static const outline = Color(0xFFD8D0C3); // 테두리
  static const card = Color(0xFFFDFBF7);

  static const onPrimary = Colors.white;
  static const onSecondary = Colors.white;
  static const onBackground = Color(0xFF1F1B16);
  static const onSurface = Color(0xFF1F1B16);

  // 글자 (먹색 3단계: 본문 / 보조 / 흐림)
  static const display = Color(0xFF1F1B16);
  static const headline = Color(0xFF1F1B16);
  static const body = Color(0xFF2E2923);
  static const bodyMedium = Color(0xFF5E554A);
  static const bodySmall = Color(0xFF7B7266);
  static const label = Color(0xFF5E554A);
  static const labelSmall = Color(0xFF7B7266);

  // UI 요소
  static const appBar = Color(0xFFF7F4EE);
  static const cardBorder = Color(0xFFE6E0D5);
  static const cardSurfaceTint = Color(0xFFFDFBF7);
  static const fabFill = Color(0xFF8C2F2B);
  static const inputFill = Color(0xFFEFE9DF);
}

/// 다크 테마: 밤에 켠 스탠드 아래의 책
class DarkColors {
  // 표면
  static const background = Color(0xFF161513); // 페이지 배경
  static const surface = Color(0xFF1C1A18); // 카드
  static const raised = Color(0xFF262421); // 입력칸, 선택된 행
  static const deepest = Color(0xFF12110F);

  // 강조 (가름끈, 어두운 면에서 읽히도록 밝힘)
  static const primary = Color(0xFFD98A80);
  static const primaryContainer = Color(0xFF3A2623);
  static const onPrimaryContainer = Color(0xFFF2D5CF);

  static const secondary = Color(0xFFAAA398);
  static const accent = Color(0xFFD98A80);

  // 선
  static const divider = Color(0xFF2B2926);
  static const outline = Color(0xFF3A3632);
  static const card = Color(0xFF1C1A18);

  static const onPrimary = Color(0xFF1F1310);
  static const onSecondary = Color(0xFF161513);
  static const onBackground = Color(0xFFEFE9DE);
  static const onSurface = Color(0xFFEFE9DE);

  // 글자
  static const display = Color(0xFFEFE9DE);
  static const headline = Color(0xFFEFE9DE);
  static const body = Color(0xFFE2DBCF);
  static const bodyMedium = Color(0xFFAAA398);
  static const bodySmall = Color(0xFF8A847A);
  static const label = Color(0xFFAAA398);
  static const labelSmall = Color(0xFF8A847A);

  // UI 요소
  static const appBar = Color(0xFF161513);
  static const cardBorder = Color(0xFF2B2926);
  static const cardSurfaceTint = Color(0xFF1C1A18);
  static const fabFill = Color(0xFFD98A80);
  static const inputFill = Color(0xFF262421);
}
