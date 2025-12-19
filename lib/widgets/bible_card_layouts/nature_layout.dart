import 'package:flutter/material.dart';

/// 자연 레이아웃 - 부드러운 자연 테마
class NatureLayout extends StatelessWidget {
  final String verse;
  final String reference;
  final String shareTitle;

  const NatureLayout({
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
    const bgColor = Color(0xFFF0F7F4);
    const greenColor = Color(0xFF5F9EA0);
    const darkGreenColor = Color(0xFF2F5D62);
    const textColor = Color(0xFF1F3833);

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            const Color(0xFFE8F5E9),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 배경 나뭇잎 장식
          Positioned(
            top: 60,
            right: 60,
            child: Icon(
              Icons.eco,
              size: 120,
              color: greenColor.withOpacity(0.1),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 80,
            child: Icon(
              Icons.spa,
              size: 100,
              color: greenColor.withOpacity(0.1),
            ),
          ),

          // 메인 콘텐츠
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 120),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),

                // 상단 장식
                Row(
                  children: [
                    Icon(
                      Icons.eco,
                      color: greenColor,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              greenColor,
                              greenColor.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 80),

                // 성경 구절
                Text(
                  '"$verse"',
                  style: TextStyle(
                    fontSize: _calculateFontSize(verse.length),
                    height: 1.9,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    fontFamily: 'ChosunCentennial',
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.left,
                ),

                const SizedBox(height: 60),

                // 참조 구절
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: greenColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book,
                        color: darkGreenColor,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        reference,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: darkGreenColor,
                          fontFamily: 'ChosunCentennial',
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 하단 장식
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              greenColor.withOpacity(0),
                              greenColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.spa,
                      color: greenColor,
                      size: 40,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 날짜 및 앱 이름
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
                        letterSpacing: 1,
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
                        letterSpacing: 1,
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
