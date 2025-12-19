import 'package:flutter/material.dart';

/// 심플 레이아웃 - 간결한 화이트 카드
class SimpleLayout extends StatelessWidget {
  final String verse;
  final String reference;
  final String shareTitle;
  final Color backgroundColor;
  final Color textColor;

  const SimpleLayout({
    super.key,
    required this.verse,
    required this.reference,
    required this.shareTitle,
    this.backgroundColor = Colors.white,
    this.textColor = const Color(0xFF1F2937),
  });

  double _calculateFontSize(int length) {
    if (length > 200) return 28.0;
    if (length > 150) return 32.0;
    if (length > 120) return 36.0;
    if (length > 100) return 38.0;
    if (length > 80) return 42.0;
    if (length > 60) return 46.0;
    return 50.0;
  }

  @override
  Widget build(BuildContext context) {
    const cardWidth = 1080.0;
    const cardHeight = 1350.0;

    return Container(
      width: cardWidth,
      height: cardHeight,
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 100.0, vertical: 120.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 날짜
            Text(
              '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                color: textColor.withValues(alpha: 0.4),
                fontFamily: 'Pretendard',
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 50),

            // 말씀
            Text(
              verse,
              style: TextStyle(
                fontSize: _calculateFontSize(verse.length),
                height: 2.0,
                fontWeight: FontWeight.w600,
                color: textColor,
                fontFamily: 'ChosunCentennial',
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.left,
            ),

            const SizedBox(height: 50),

            // 출처
            Text(
              reference,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.7),
                fontFamily: 'ChosunCentennial',
                letterSpacing: 1,
              ),
            ),

            const Spacer(),

            // 하단
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 2,
                  color: textColor.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: textColor.withValues(alpha: 0.35),
                    fontFamily: 'Pretendard',
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '올인바이블 (All in Bible)',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: textColor.withValues(alpha: 0.4),
                    fontFamily: 'Pretendard',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
