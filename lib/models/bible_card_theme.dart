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
      ? const Color(0xFF1F2937) // 다크 그레이
      : Colors.white;

  // 프리셋 테마들 - 2025 트렌디 컬러
  static const List<BibleCardTheme> presets = [
    // 1. 퍼플 드림 (Purple Dream)
    BibleCardTheme(
      name: '퍼플 드림',
      gradientColors: [
        Color(0xFF667EEA), // 소프트 퍼플
        Color(0xFF764BA2), // 딥 퍼플
        Color(0xFFF093FB), // 핑크 퍼플
      ],
      gradientStops: [0.0, 0.5, 1.0],
    ),

    // 2. 오션 미스트 (Ocean Mist)
    BibleCardTheme(
      name: '오션 미스트',
      gradientColors: [
        Color(0xFF4E54C8), // 딥 블루
        Color(0xFF8F94FB), // 소프트 블루
        Color(0xFFA8EDEA), // 민트 블루
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

    // 6. 아쿠아 브리즈 (Aqua Breeze)
    BibleCardTheme(
      name: '아쿠아 브리즈',
      gradientColors: [
        Color(0xFF2AFADF), // 밝은 시안
        Color(0xFF4C83FF), // 오션 블루
        Color(0xFF7B68EE), // 미디엄 슬레이트 블루
      ],
      gradientStops: [0.0, 0.5, 1.0],
    ),

    // 7. 라벤더 블러쉬 (Lavender Blush)
    BibleCardTheme(
      name: '라벤더 블러쉬',
      gradientColors: [
        Color(0xFFB06AB3), // 라벤더
        Color(0xFF4568DC), // 퍼플 블루
        Color(0xFFD4A5FF), // 라일락
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

    // 9. 미스틱 민트 (Mystic Mint)
    BibleCardTheme(
      name: '미스틱 민트',
      gradientColors: [
        Color(0xFF00C9FF), // 스카이 블루
        Color(0xFF92FE9D), // 민트 그린
        Color(0xFFB4FFC9), // 라이트 민트
      ],
      gradientStops: [0.0, 0.5, 1.0],
      useDarkText: true, // 밝은 배경 - 어두운 텍스트
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

    // 11. 트로피칼 파라다이스 (Tropical Paradise)
    BibleCardTheme(
      name: '트로피칼 파라다이스',
      gradientColors: [
        Color(0xFF09203F), // 딥 네이비
        Color(0xFF537895), // 슬레이트 블루
        Color(0xFF96DEDA), // 아쿠아
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

    // 15. 베리 소르베 (Berry Sorbet)
    BibleCardTheme(
      name: '베리 소르베',
      gradientColors: [
        Color(0xFFD38312), // 버건디 골드
        Color(0xFFA83279), // 베리 퍼플
        Color(0xFFFFB6B9), // 라이트 베리
      ],
      gradientStops: [0.0, 0.5, 1.0],
    ),
  ];
}
