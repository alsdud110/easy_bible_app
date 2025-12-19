import 'package:flutter/material.dart';

/// 볼드 레이아웃 - 강렬하고 임팩트 있는 디자인
class BoldLayout extends StatelessWidget {
  final String verse;
  final String reference;
  final String shareTitle;
  final Color backgroundColor;
  final Color accentColor;

  const BoldLayout({
    super.key,
    required this.verse,
    required this.reference,
    required this.shareTitle,
    this.backgroundColor = const Color(0xFF1A1A1A), // 다크 배경
    this.accentColor = const Color(0xFFFFD700), // 골드
  });

  double _calculateFontSize(int length) {
    if (length > 200) return 30.0;
    if (length > 150) return 34.0;
    if (length > 120) return 38.0;
    if (length > 100) return 42.0;
    if (length > 80) return 46.0;
    if (length > 60) return 50.0;
    return 54.0;
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
          // 배경 그래픽
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.15),
                    accentColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.12),
                    accentColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 메인 콘텐츠
          Padding(
            padding: const EdgeInsets.all(80.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 60,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shareTitle,
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                            fontFamily: 'Pretendard',
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.6),
                            fontFamily: 'Pretendard',
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // 말씀
                Container(
                  padding: const EdgeInsets.all(50),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 출처 (위로 이동)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          reference,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A1A),
                            fontFamily: 'ChosunCentennial',
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 말씀
                      Text(
                        verse,
                        style: TextStyle(
                          fontSize: _calculateFontSize(verse.length),
                          height: 1.8,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'ChosunCentennial',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 하단
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '올인바이블',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontFamily: 'Pretendard',
                        letterSpacing: 1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'All in Bible',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                          fontFamily: 'Pretendard',
                          letterSpacing: 0.5,
                        ),
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
