import 'package:flutter/material.dart';

/// 성경 카드 배경 테마
class BibleCardTheme {
  final String name;
  final List<Color> gradientColors;
  final List<double> gradientStops;
  final bool useDarkText; // 밝은 배경일 때 true

  const BibleCardTheme({
    required this.name,
    required this.gradientColors,
    required this.gradientStops,
    this.useDarkText = false, // 기본값: 흰색 텍스트
  });

  // 텍스트 색상 반환
  Color get textColor => useDarkText
      ? const Color(0xFF1F1B16) // 다크 그레이
      : Colors.white;

  // 프리셋 테마들. 선택은 인덱스로 하므로 개수와 순서는 유지한다.
  // 파랑/보라 계열은 앱 팔레트(종이·가죽·가름끈)에 맞는 테마로 교체
  static const List<BibleCardTheme> presets = [
    // 1. 가름끈 (성경책의 붉은 끈)
    BibleCardTheme(
      name: '가름끈',
      gradientColors: [
        Color(0xFF5E1D1A), // 짙은 버건디
        Color(0xFF8C2F2B), // 가름끈 버건디
        Color(0xFFB5574F), // 바랜 버건디
      ],
      gradientStops: [0.0, 0.5, 1.0],
    ),

    // 2. 새벽 안개
    BibleCardTheme(
      name: '새벽 안개',
      gradientColors: [
        Color(0xFF3A3632), // 먹색
        Color(0xFF6B635A), // 젖은 돌
        Color(0xFFA89F92), // 안개
      ],
      gradientStops: [0.0, 0.5, 1.0],
    ),

    // 3. 선셋 글로우 (Sunset Glow)
    BibleCardTheme(
      name: '선셋 글로우',
      gradientColors: [
        Color(0xFFFA709A), // 코랄 핑크
        Color(0xFFFEE140), // 선샤인 옐로우
        Color(0xFFFFCF71), // 골든 옐로우
      ],
      gradientStops: [0.0, 0.5, 1.0],
      useDarkText: true, // 밝은 배경 - 어두운 텍스트
    ),

    // 4. 에메랄드 포레스트 (Emerald Forest)
    BibleCardTheme(
      name: '에메랄드 포레스트',
      gradientColors: [
        Color(0xFF11998E), // 틸 그린
        Color(0xFF38EF7D), // 에메랄드
        Color(0xFF7CF7C1), // 민트 그린
      ],
      gradientStops: [0.0, 0.5, 1.0],
    ),

    // 5. 로즈 골드 (Rose Gold)
    BibleCardTheme(
      name: '로즈 골드',
      gradientColors: [
        Color(0xFFEB3349), // 딥 로즈
        Color(0xFFF45C43), // 코랄 레드
        Color(0xFFFFB88C), // 피치 골드
      ],
      gradientStops: [0.0, 0.5, 1.0],
    ),

    // 6. 양피지
    BibleCardTheme(
      name: '양피지',
      gradientColors: [
        Color(0xFFE9DCBF), // 양피지
        Color(0xFFE2CFA9), // 바랜 양피지
        Color(0xFFF5EDD9), // 미색
      ],
      gradientStops: [0.0, 0.5, 1.0],
      useDarkText: true, // 밝은 배경 - 어두운 텍스트
    ),

    // 7. 가죽 표지
    BibleCardTheme(
      name: '가죽 표지',
      gradientColors: [
        Color(0xFF3B2A20), // 짙은 가죽
        Color(0xFF6B4A35), // 가죽
        Color(0xFF9C7556), // 닳은 가죽
      ],
      gradientStops: [0.0, 0.5, 1.0],
    ),

    // 8. 골든 아워 (Golden Hour)
    BibleCardTheme(
      name: '골든 아워',
      gradientColors: [
        Color(0xFFFDC830), // 골든 옐로우
        Color(0xFFF37335), // 선셋 오렌지
        Color(0xFFFFE985), // 라이트 골드
      ],
      gradientStops: [0.0, 0.5, 1.0],
      useDarkText: true, // 밝은 배경 - 어두운 텍스트
    ),

    // 9. 올리브 동산
    BibleCardTheme(
      name: '올리브 동산',
      gradientColors: [
        Color(0xFF3E5530), // 짙은 올리브
        Color(0xFF5F7A45), // 올리브
        Color(0xFF8FA370), // 마른 잎
      ],
      gradientStops: [0.0, 0.5, 1.0],
    ),

    // 10. 체리 블라썸 (Cherry Blossom)
    BibleCardTheme(
      name: '체리 블라썸',
      gradientColors: [
        Color(0xFFFF6B9D), // 체리 핑크
        Color(0xFFC06C84), // 로즈
        Color(0xFFFFB3C6), // 라이트 핑크
      ],
      gradientStops: [0.0, 0.5, 1.0],
      useDarkText: true, // 밝은 배경 - 어두운 텍스트
    ),

    // 11. 밤의 등불
    BibleCardTheme(
      name: '밤의 등불',
      gradientColors: [
        Color(0xFF161513), // 밤
        Color(0xFF2B2622), // 그늘
        Color(0xFF6E4A2E), // 등잔 불빛
      ],
      gradientStops: [0.0, 0.5, 1.0],
    ),

    // 12. 피치 크림 (Peach Cream)
    BibleCardTheme(
      name: '피치 크림',
      gradientColors: [
        Color(0xFFFFAFBD), // 피치 핑크
        Color(0xFFFFC3A0), // 피치
        Color(0xFFFFE5D9), // 크림 피치
      ],
      gradientStops: [0.0, 0.5, 1.0],
      useDarkText: true, // 밝은 배경 - 어두운 텍스트
    ),

    // 13. 코랄 서머 (Coral Summer)
    BibleCardTheme(
      name: '코랄 서머',
      gradientColors: [
        Color(0xFFFF9A56), // 코랄
        Color(0xFFFF6A88), // 핫 핑크
        Color(0xFFFFC371), // 피치 골드
      ],
      gradientStops: [0.0, 0.5, 1.0],
      useDarkText: true, // 밝은 배경 - 어두운 텍스트
    ),

    // 14. 미드나잇 시티 (Midnight City)
    BibleCardTheme(
      name: '미드나잇 시티',
      gradientColors: [
        Color(0xFF232526), // 차콜
        Color(0xFF414345), // 다크 그레이
        Color(0xFF6B6E70), // 미디엄 그레이
      ],
      gradientStops: [0.0, 0.5, 1.0],
    ),

    // 15. 포도원
    BibleCardTheme(
      name: '포도원',
      gradientColors: [
        Color(0xFF5A1F2B), // 포도주
        Color(0xFF7E2E3C), // 익은 포도
        Color(0xFFB8707A), // 바랜 포도
      ],
      gradientStops: [0.0, 0.5, 1.0],
    ),
  ];
}
