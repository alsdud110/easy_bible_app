import 'package:flutter/material.dart';
import '../models/bible_card_theme.dart';

/// 2025 트렌디한 성경 카드 디자인
class BeautifulBibleCard extends StatelessWidget {
  final String verse;
  final String reference;
  final BibleCardTheme theme;
  final bool? forceWhiteText; // null이면 테마 기본값, true면 흰색, false면 검정

  const BeautifulBibleCard({
    super.key,
    required this.verse,
    required this.reference,
    this.theme = const BibleCardTheme(
      name: '보라 핑크',
      gradientColors: [
        Color(0xFF6B4CE6),
        Color(0xFF9D50E8),
        Color(0xFFE65C9A),
      ],
      gradientStops: [0.0, 0.5, 1.0],
    ),
    this.forceWhiteText,
  });

  // 실제 사용할 텍스트 색상 반환
  Color get _textColor {
    if (forceWhiteText == null) {
      return theme.textColor; // 테마 기본값
    }
    return forceWhiteText! ? Colors.white : const Color(0xFF1F2937);
  }

  // 텍스트 길이에 따라 적절한 폰트 크기 계산
  double _calculateFontSize(int length) {
    if (length > 200) return 28.0;
    if (length > 150) return 32.0;
    if (length > 120) return 36.0;
    if (length > 100) return 38.0;
    if (length > 80) return 42.0;
    if (length > 60) return 46.0;
    return 50.0;
  }

  // 텍스트 길이에 따라 줄간격 계산
  double _calculateLineHeight(int length) {
    if (length > 150) return 1.7;
    if (length > 100) return 1.8;
    return 1.9;
  }

  // 긴 텍스트를 자연스럽게 문단 나누기
  String _formatVerse(String verse) {
    // 쉼표나 마침표 뒤에 자연스럽게 줄바꿈 추가
    if (verse.length < 50) return verse;

    String result = verse;

    // 접속사나 구두점 뒤에 줄바꿈 추가 (너무 짧지 않은 경우)
    final patterns = [
      RegExp(r'([가-힣]{20,}[,]) '),  // 쉼표 뒤
      RegExp(r'([가-힣]{20,}며) '),   // ~며 뒤
      RegExp(r'([가-힣]{20,}요) '),   // ~요 뒤
      RegExp(r'([가-힣]{20,}라) '),   // ~라 뒤
      RegExp(r'([가-힣]{20,}니) '),   // ~니 뒤
    ];

    for (var pattern in patterns) {
      result = result.replaceAllMapped(pattern, (match) => '${match.group(1)}\n');
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    // 고정 크기로 설정 (이미지 캡처용)
    const cardWidth = 1080.0; // 인스타그램 사이즈
    const cardHeight = 1350.0; // 세로형 카드 (말씀 공간 확보를 위해 조정)

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.gradientColors,
          stops: theme.gradientStops,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 배경 패턴
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPatternPainter(_textColor),
            ),
          ),

          // 메인 콘텐츠
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 오늘 날짜
                Text(
                  '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: _textColor.withValues(alpha: 0.95),
                    letterSpacing: 3,
                    fontFamily: 'Pretendard',
                  ),
                ),

                SizedBox(height: verse.length > 100 ? 30 : 40),

                // 성경 구절 - 내용에 맞게 크기 조정
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: verse.length > 150 ? 35 : 45,
                    vertical: verse.length > 150 ? 35 : verse.length > 100 ? 40 : 50,
                  ),
                  decoration: BoxDecoration(
                    color: _textColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _textColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _formatVerse(verse),
                    style: TextStyle(
                      fontSize: _calculateFontSize(verse.length),
                      height: _calculateLineHeight(verse.length),
                      fontWeight: FontWeight.w700,
                      color: _textColor,
                      fontFamily: 'ChosunCentennial',
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: null,
                  ),
                ),

                SizedBox(height: verse.length > 100 ? 25 : 35),

                // 출처
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _textColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    reference,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _textColor,
                      fontFamily: 'ChosunCentennial',
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 하단 텍스트
                Text(
                  '내일이 되면 새롭게 받을 수 있어요!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: _textColor.withValues(alpha: 0.85),
                    fontFamily: 'Pretendard',
                  ),
                ),

                const SizedBox(height: 12),

                // 앱 이름
                Text(
                  '올인바이블 (All in Bible)',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _textColor.withValues(alpha: 0.95),
                    fontFamily: 'Pretendard',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // 상단 장식
          Positioned(
            top: 40,
            left: 50,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _textColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: _textColor.withValues(alpha: 0.95),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '오늘의 말씀',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _textColor.withValues(alpha: 0.95),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 배경 패턴 페인터
class _BackgroundPatternPainter extends CustomPainter {
  final Color patternColor;

  const _BackgroundPatternPainter(this.patternColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = patternColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 원형 패턴
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.2 + i * 60),
        30.0 + i * 15,
        paint,
      );
    }

    // 선 패턴
    for (int i = 0; i < 5; i++) {
      final y = size.height * 0.15 + i * 30;
      canvas.drawLine(
        Offset(size.width * 0.1, y),
        Offset(size.width * 0.3, y),
        paint..strokeWidth = 1.0,
      );
    }

    // 하단 원형
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.85),
      40,
      paint..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundPatternPainter oldDelegate) =>
      oldDelegate.patternColor != patternColor;
}
