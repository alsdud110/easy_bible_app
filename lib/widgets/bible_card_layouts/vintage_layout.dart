import 'package:flutter/material.dart';

/// 빈티지 레이아웃 - 레트로 감성 디자인
class VintageLayout extends StatelessWidget {
  final String verse;
  final String reference;
  final String shareTitle;

  const VintageLayout({
    super.key,
    required this.verse,
    required this.reference,
    required this.shareTitle,
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
    const bgColor = Color(0xFFFFF8E1);
    const brownColor = Color(0xFF8B4513);
    const darkBrownColor = Color(0xFF5D2E0F);
    const textColor = Color(0xFF3E2723);

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            bgColor,
            const Color(0xFFFFE0B2),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 빈티지 텍스처 효과
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.03),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.03),
                  ],
                ),
              ),
            ),
          ),

          // 장식 코너
          Positioned(
            top: 40,
            left: 40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: brownColor, width: 4),
                  left: BorderSide(color: brownColor, width: 4),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: brownColor, width: 4),
                  right: BorderSide(color: brownColor, width: 4),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: brownColor, width: 4),
                  left: BorderSide(color: brownColor, width: 4),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: 40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: brownColor, width: 4),
                  right: BorderSide(color: brownColor, width: 4),
                ),
              ),
            ),
          ),

          // 메인 콘텐츠
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 150),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 장식
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: brownColor,
                            width: 3,
                          ),
                        ),
                        child: Icon(
                          Icons.auto_stories,
                          color: brownColor,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: 200,
                        height: 2,
                        color: brownColor,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 성경 구절
                Text(
                  '"$verse"',
                  style: TextStyle(
                    fontSize: _calculateFontSize(verse.length),
                    height: 1.9,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontFamily: 'ChosunCentennial',
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.left,
                ),

                const SizedBox(height: 60),

                // 참조 구절
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 2,
                      color: darkBrownColor,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      reference,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: darkBrownColor,
                        fontFamily: 'ChosunCentennial',
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: darkBrownColor,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // 하단 장식
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 200,
                        height: 2,
                        color: brownColor,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '❦',
                        style: TextStyle(
                          fontSize: 48,
                          color: brownColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: textColor.withValues(alpha: 0.4),
                          fontFamily: 'Pretendard',
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '올인바이블 (All in Bible)',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: textColor.withValues(alpha: 0.5),
                          fontFamily: 'Pretendard',
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
