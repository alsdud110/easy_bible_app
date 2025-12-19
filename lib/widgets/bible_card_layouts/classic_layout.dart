import 'package:flutter/material.dart';

/// 클래식 레이아웃 - 전통적인 성경 카드 스타일
class ClassicLayout extends StatelessWidget {
  final String verse;
  final String reference;
  final String shareTitle;
  final Color backgroundColor;
  final Color textColor;

  const ClassicLayout({
    super.key,
    required this.verse,
    required this.reference,
    required this.shareTitle,
    this.backgroundColor = const Color(0xFFFFFDF7), // 아이보리
    this.textColor = const Color(0xFF2C1810),
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
      child: Stack(
        children: [
          // 장식 테두리
          Positioned.fill(
            child: CustomPaint(
              painter: _ClassicBorderPainter(textColor),
            ),
          ),

          // 메인 콘텐츠
          Padding(
            padding: const EdgeInsets.all(100.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 상단 장식
                Icon(
                  Icons.auto_stories,
                  size: 60,
                  color: textColor.withValues(alpha: 0.7),
                ),

                const SizedBox(height: 40),

                // 제목
                Text(
                  shareTitle,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: textColor.withValues(alpha: 0.8),
                    fontFamily: 'ChosunCentennial',
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 30),

                // 날짜
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: textColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${DateTime.now().year}년 ${DateTime.now().month}월 ${DateTime.now().day}일',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: textColor.withValues(alpha: 0.7),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),

                const Spacer(),

                // 말씀
                Text(
                  '"$verse"',
                  style: TextStyle(
                    fontSize: _calculateFontSize(verse.length),
                    height: 1.9,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: 'ChosunCentennial',
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.left,
                ),

                const Spacer(),

                // 출처
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reference,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      fontFamily: 'ChosunCentennial',
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // 하단
                Column(
                  children: [
                    Text(
                      '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: textColor.withValues(alpha: 0.5),
                        fontFamily: 'Pretendard',
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '올인바이블 (All in Bible)',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.6),
                        fontFamily: 'Pretendard',
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 클래식 테두리 페인터
class _ClassicBorderPainter extends CustomPainter {
  final Color borderColor;

  const _ClassicBorderPainter(this.borderColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 외부 테두리
    canvas.drawRect(
      Rect.fromLTWH(40, 40, size.width - 80, size.height - 80),
      paint,
    );

    // 내부 테두리
    canvas.drawRect(
      Rect.fromLTWH(50, 50, size.width - 100, size.height - 100),
      paint..strokeWidth = 1.0,
    );

    // 코너 장식
    final cornerPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    const cornerSize = 30.0;
    const margin = 40.0;

    // 좌상단
    canvas.drawLine(Offset(margin, margin + cornerSize), Offset(margin, margin),
        cornerPaint);
    canvas.drawLine(Offset(margin, margin), Offset(margin + cornerSize, margin),
        cornerPaint);

    // 우상단
    canvas.drawLine(Offset(size.width - margin - cornerSize, margin),
        Offset(size.width - margin, margin), cornerPaint);
    canvas.drawLine(Offset(size.width - margin, margin),
        Offset(size.width - margin, margin + cornerSize), cornerPaint);

    // 좌하단
    canvas.drawLine(Offset(margin, size.height - margin - cornerSize),
        Offset(margin, size.height - margin), cornerPaint);
    canvas.drawLine(Offset(margin, size.height - margin),
        Offset(margin + cornerSize, size.height - margin), cornerPaint);

    // 우하단
    canvas.drawLine(
        Offset(size.width - margin - cornerSize, size.height - margin),
        Offset(size.width - margin, size.height - margin),
        cornerPaint);
    canvas.drawLine(
        Offset(size.width - margin, size.height - margin - cornerSize),
        Offset(size.width - margin, size.height - margin),
        cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _ClassicBorderPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor;
}
