import 'package:flutter/material.dart';

/// 우아한 레이아웃 - 세련되고 우아한 스타일
class ElegantLayout extends StatelessWidget {
  final String verse;
  final String reference;
  final String shareTitle;
  final Color backgroundColor;
  final Color accentColor;
  final Color textColor;

  const ElegantLayout({
    super.key,
    required this.verse,
    required this.reference,
    required this.shareTitle,
    this.backgroundColor = const Color(0xFFF8F9FA),
    this.accentColor = const Color(0xFF8B7355), // 골드 브라운
    this.textColor = const Color(0xFF2D2D2D),
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
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor,
            backgroundColor.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 배경 장식
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.3),
                    accentColor,
                    accentColor.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.3),
                    accentColor,
                    accentColor.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),

          // 메인 콘텐츠
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 80.0, vertical: 100.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 상단 장식
                Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 40),

                // 제목
                Text(
                  shareTitle,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: accentColor,
                    fontFamily: 'Pretendard',
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: textColor.withValues(alpha: 0.5),
                    fontFamily: 'Pretendard',
                    letterSpacing: 2,
                  ),
                ),

                const Spacer(),

                // 말씀
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 왼쪽 따옴표
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '"',
                          style: TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.w800,
                            color: accentColor.withValues(alpha: 0.3),
                            fontFamily: 'Pretendard',
                            height: 0.8,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        verse,
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

                      const SizedBox(height: 10),

                      // 오른쪽 따옴표
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '"',
                          style: TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.w800,
                            color: accentColor.withValues(alpha: 0.3),
                            fontFamily: 'Pretendard',
                            height: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // 출처
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: accentColor.withValues(alpha: 0.3), width: 1),
                      bottom: BorderSide(
                          color: accentColor.withValues(alpha: 0.3), width: 1),
                    ),
                  ),
                  child: Text(
                    reference,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                      fontFamily: 'ChosunCentennial',
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                const Spacer(),

                // 하단 장식
                Container(
                  width: 80,
                  height: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
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
    );
  }
}
