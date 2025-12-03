import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double _pageFraction = 0.0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: '전체 성경',
      description: '한글/영어 성경을 자유롭게 읽고\n성경 구절 빠른 검색과 단어 검색을 활용하세요',
      lottieAsset: 'assets/lottie/bible_book.json',
      icon: Icons.menu_book_rounded,
      color: const Color(0xFF6366F1),
    ),
    OnboardingPage(
      title: '성경 읽기 플랜',
      description: '60일, 120일, 180일 플랜으로\n매일 꾸준히 체계적인 성경 읽기를 실천하세요',
      lottieAsset: 'assets/lottie/calender.json',
      icon: Icons.calendar_month_rounded,
      color: const Color(0xFF8B5CF6),
    ),
    OnboardingPage(
      title: '오늘의 말씀 카드',
      description: '매일 새로운 성경 구절을 받아보고\n나만의 말씀 카드를 만들어 공유하세요',
      lottieAsset: 'assets/lottie/Microsoft Designer.json',
      icon: Icons.auto_awesome_rounded,
      color: const Color(0xFFEC4899),
    ),
    OnboardingPage(
      title: '묵상과 기록',
      description: '마음에 드는 구절을 북마크하고\n나만의 말씀 묵상을 기록해보세요',
      lottieAsset: 'assets/lottie/note.json',
      icon: Icons.edit_note_rounded,
      color: const Color(0xFF10B981),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (!mounted) return;
      setState(() {
        _pageFraction = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    if (!mounted) return;
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);

      // 콜백 호출 (이제 안전함 - 래퍼 위젯이 처리)
      widget.onComplete();
    } catch (e) {
      // 오류 발생 시에도 온보딩 완료 처리
      widget.onComplete();
    }
  }

  void _nextPage() {
    if (!mounted) return;
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    if (!mounted) return;
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 Skip 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 로고 또는 앱 이름
                  Text(
                    'All in Bible',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ChosunCentennial',
                    ),
                  ),
                  // Skip 버튼 (공간 유지를 위해 Opacity 사용)
                  Opacity(
                    opacity: _currentPage < _pages.length - 1 ? 1.0 : 0.0,
                    child: TextButton(
                      onPressed: _currentPage < _pages.length - 1
                          ? _skipOnboarding
                          : null,
                      child: Text(
                        '건너뛰기',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 페이지뷰 (Parallax 효과)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(index, _pages[index], theme);
                },
              ),
            ),

            // 인디케이터
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1 ? '다음' : '시작하기',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int index, OnboardingPage page, ThemeData theme) {
    // Parallax 계산
    final offset = _pageFraction - index;
    final absOffset = offset.abs();

    // 페이드 효과: 현재 페이지는 완전 불투명, 벗어날수록 투명
    final opacity = (1.0 - absOffset).clamp(0.0, 1.0);

    // Scale 효과: 현재 페이지는 1.0, 벗어날수록 0.85
    final scale = (1.0 - (absOffset * 0.15)).clamp(0.85, 1.0);

    // Y축 이동: 살짝 위아래로 움직임
    final translateY = offset * 30;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(0, translateY),
          child: Transform.scale(
            scale: scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 아이콘 또는 Lottie 애니메이션
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Transform.rotate(
                        angle: (1 - value) * 0.5,
                        child: child,
                      ),
                    );
                  },
                  child: page.lottieAsset != null
                      ? Lottie.asset(
                          page.lottieAsset!,
                          width: 240,
                          height: 240,
                          fit: BoxFit.contain,
                        )
                      : Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: page.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: page.color.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            page.icon,
                            size: 80,
                            color: page.color,
                          ),
                        ),
                ),

                const SizedBox(height: 48),

                // 제목 (슬라이드 업 애니메이션)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 50.0, end: 0.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, value),
                      child: Opacity(
                        opacity: (1 - (value / 50)).clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    page.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 16),

                // 설명 (슬라이드 업 애니메이션 - 딜레이)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 50.0, end: 0.0),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, value),
                      child: Opacity(
                        opacity: (1 - (value / 50)).clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    page.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String? lottieAsset;
  final IconData? icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    this.lottieAsset,
    this.icon,
    required this.color,
  });
}
