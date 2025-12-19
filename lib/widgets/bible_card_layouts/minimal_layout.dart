import 'package:flutter/material.dart';

/// 미니멀 레이아웃 - 깔끔하고 단순한 디자인
class MinimalLayout extends StatelessWidget {
  final String verse;
  final String reference;
  final String shareTitle;
  final Color backgroundColor;
  final Color textColor;

  const MinimalLayout({
    super.key,
    required this.verse,
    required this.reference,
    required this.shareTitle,
    this.backgroundColor = Colors.white,
    this.textColor = const Color(0xFF1F2937),
  });

  double _calculateFontSize(int length) {
    if (length > 200) return 26.0;
    if (length > 150) return 30.0;
    if (length > 120) return 34.0;
    if (length > 100) return 36.0;
    if (length > 80) return 40.0;
    if (length > 60) return 44.0;
    return 48.0;
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
        padding: const EdgeInsets.all(80.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽 세로선
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 120,
                  color: textColor,
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shareTitle,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          color: textColor.withValues(alpha: 0.6),
                          letterSpacing: 2,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w200,
                          color: textColor.withValues(alpha: 0.5),
                          letterSpacing: 1.5,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // 말씀
            Text(
              verse,
              style: TextStyle(
                fontSize: _calculateFontSize(verse.length),
                height: 1.9,
                fontWeight: FontWeight.w600,
                color: textColor,
                fontFamily: 'ChosunCentennial',
                letterSpacing: 0.3,
              ),
            ),

            const SizedBox(height: 50),

            // 출처
            Text(
              '- $reference',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: textColor.withValues(alpha: 0.8),
                fontFamily: 'ChosunCentennial',
                letterSpacing: 1,
              ),
            ),

            const Spacer(),

            // 하단
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: textColor.withValues(alpha: 0.4),
                    fontFamily: 'Pretendard',
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '올인바이블 (All in Bible)',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: textColor.withValues(alpha: 0.5),
                    fontFamily: 'Pretendard',
                    letterSpacing: 0.5,
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
