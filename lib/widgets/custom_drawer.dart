import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// 각 스크린 import 추가
import '../../screens/bible/bible_home_screen.dart'; // 전체 성경
import '../../screens/home_screen.dart'; // 어성경 바이블(홈)
import '../../screens/biblePlan/day60_screen.dart';
import '../../screens/biblePlan/day120_screen.dart';
import '../../screens/biblePlan/day180_screen.dart';
import '../../screens/favorite/favorite_list_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomDrawer extends StatelessWidget {
  final VoidCallback? onThemeToggle;
  final bool isDark;
  const CustomDrawer({
    super.key,
    this.onThemeToggle,
    this.isDark = false,
  });

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).pop(); // Drawer 먼저 닫기

    // 현재 화면이 HomeScreen인지 확인
    if (screen is HomeScreen) {
      // 이미 홈이면 모든 라우트 제거하고 홈으로
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => screen,
          transitionDuration: const Duration(milliseconds: 170),
          reverseTransitionDuration: const Duration(milliseconds: 120),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
        (route) => false,
      );
    } else {
      // 홈이 아니면 일반 push (뒤로가기 가능)
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => screen,
          transitionDuration: const Duration(milliseconds: 170),
          reverseTransitionDuration: const Duration(milliseconds: 120),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  void _showComingSoonDialog(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Navigator.of(context).pop(); // Drawer 먼저 닫기

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.construction_rounded, color: cs.primary),
            const SizedBox(width: 12),
            Text(
              '준비 중',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          '해당 메뉴는 준비 중입니다!',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: cs.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '확인',
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
      ),
      backgroundColor: cs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withOpacity(0.88),
                    cs.surface.withOpacity(0.98),
                    cs.primary.withOpacity(0.68),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 28.0,
                  bottom: 8.0,
                  left: 24,
                  right: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final imageSize =
                            (constraints.maxWidth * 0.6).clamp(80.0, 120.0);

                        return Image.asset(
                          'assets/icon/bible_icon.png',
                          width: imageSize,
                          height: imageSize,
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All in Bible',
                      style: GoogleFonts.dancingScript(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 스크롤 가능한 메뉴 영역
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // 메뉴: 전체 성경
                  _DrawerButton(
                    icon: Icons.menu_book_rounded,
                    label: '전체 성경',
                    color: cs.primary,
                    onTap: () => _navigateToScreen(
                        context,
                        BibleHomeScreen(
                          onThemeToggle: onThemeToggle,
                          isDark: isDark,
                        )),
                  ),
                  // 메뉴: 어성경 바이블(홈)
                  _DrawerButton(
                    icon: Icons.home_rounded,
                    label: '어성경 바이블',
                    color: cs.primary,
                    onTap: () => _showComingSoonDialog(context),
                  ),

                  // 성경일독(플랜) - 펼침/접기
                  _PlanExpansionMenu(
                    color: cs.secondary,
                    navigateToScreen: (screen) => _navigateToScreen(context, screen),
                  ),

                  _DrawerButton(
                    icon: Icons.bookmark_added,
                    label: '북마크',
                    color: Colors.amber.shade700,
                    onTap: () => _navigateToScreen(context, const FavoriteListScreen()),
                  ),
                ],
              ),
            ),
          ),

          // ----- 테마 토글 Lottie 애니메이션 -----
          _ThemeToggleLottie(
            isDark: isDark,
            onThemeToggle: onThemeToggle,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DrawerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DrawerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 18.0, right: 12, bottom: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.13),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          label,
          style:
              theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        hoverColor: color.withOpacity(0.10),
        splashColor: color.withOpacity(0.16),
      ),
    );
  }
}

// 숫자 뱃지 버튼
class _DrawerNumberButton extends StatelessWidget {
  final String number;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DrawerNumberButton({
    required this.number,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, bottom: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        title: Text(
          label,
          style:
              theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        hoverColor: color.withOpacity(0.10),
        splashColor: color.withOpacity(0.16),
      ),
    );
  }
}

// 펼침 메뉴: 성경일독(플랜)
class _PlanExpansionMenu extends StatefulWidget {
  final Color color;
  final void Function(Widget screen) navigateToScreen;
  const _PlanExpansionMenu({
    required this.color,
    required this.navigateToScreen,
  });

  @override
  State<_PlanExpansionMenu> createState() => _PlanExpansionMenuState();
}

class _PlanExpansionMenuState extends State<_PlanExpansionMenu>
    with SingleTickerProviderStateMixin {
  bool expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      expanded = !expanded;
      if (expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 18.0, right: 12, bottom: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: widget.color.withOpacity(0.13),
              child: Icon(Icons.flight_takeoff_rounded,
                  color: widget.color, size: 24),
            ),
            title: Text(
              '성경일독(플랜)',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            trailing: AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Icon(
                Icons.keyboard_arrow_down,
                color: widget.color,
              ),
            ),
            onTap: _toggleExpansion,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            hoverColor: widget.color.withOpacity(0.10),
            splashColor: widget.color.withOpacity(0.16),
          ),
        ),
        SizeTransition(
          sizeFactor: _animation,
          axisAlignment: -1,
          child: FadeTransition(
            opacity: _animation,
            child: Padding(
              padding: const EdgeInsets.only(left: 34, right: 18),
              child: Column(
                children: [
                  _buildAnimatedButton(0, '60', 'DAY60 플랜',
                      () => widget.navigateToScreen(const Day60Screen())),
                  _buildAnimatedButton(1, '120', 'DAY120 플랜',
                      () => widget.navigateToScreen(const Day120Screen())),
                  _buildAnimatedButton(2, '180', 'DAY180 플랜',
                      () => widget.navigateToScreen(const Day180Screen())),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedButton(
      int index, String number, String label, VoidCallback onTap) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // 각 버튼마다 약간의 지연 효과
        final delay = index * 0.15;
        final progress =
            (_controller.value - delay).clamp(0.0, 1.0) / (1 - delay);

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * 10),
            child: _DrawerNumberButton(
              number: number,
              label: label,
              color: widget.color,
              onTap: onTap,
            ),
          ),
        );
      },
    );
  }
}

// 테마 토글 Lottie 애니메이션 위젯
class _ThemeToggleLottie extends StatefulWidget {
  final bool isDark;
  final VoidCallback? onThemeToggle;

  const _ThemeToggleLottie({
    required this.isDark,
    this.onThemeToggle,
  });

  @override
  State<_ThemeToggleLottie> createState() => _ThemeToggleLottieState();
}

class _ThemeToggleLottieState extends State<_ThemeToggleLottie>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 초기 상태 설정
    if (widget.isDark) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_ThemeToggleLottie oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 테마가 바뀌면 애니메이션 실행
    if (oldWidget.isDark != widget.isDark) {
      if (widget.isDark) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: GestureDetector(
        onTap: () {
          widget.onThemeToggle?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Lottie 애니메이션
              SizedBox(
                width: 48,
                height: 48,
                child: Lottie.asset(
                  'assets/lottie/theme_toggler.json',
                  controller: _controller,
                  onLoaded: (composition) {
                    _controller.duration = composition.duration;
                    if (widget.isDark) {
                      _controller.value = 1.0;
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isDark ? "다크 모드" : "라이트 모드",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.isDark ? "어두운 테마 사용 중" : "밝은 테마 사용 중",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.primary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
