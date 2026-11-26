import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../config/feature_flags.dart';

// 각 스크린 import 추가
import '../../screens/bible/bible_home_screen.dart'; // 전체 성경
import '../../screens/home_screen.dart'; // 어성경 바이블(홈)
import '../../screens/biblePlan/plan_screens.dart';
import '../models/plan_progress.dart';
import '../../screens/favorite/favorite_list_screen.dart';
import '../../screens/subscription/paywall_screen.dart';
import '../providers/subscription_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isPremium = context.watch<SubscriptionProvider>().isPremium;

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
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
                color: theme.scaffoldBackgroundColor,
                border: Border(bottom: BorderSide(color: cs.outlineVariant)),
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
                      // 홈 앱바 워드마크와 같은 글꼴
                      style: TextStyle(
                        fontFamily: 'ChosunCentennial',
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 24,
                        letterSpacing: 0.2,
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
                  // 메뉴: 프리미엄 (구독)
                  // 사업자등록/통신판매업 신고 전까지 kPremiumFeatureEnabled 로 숨김
                  if (kPremiumFeatureEnabled)
                    _DrawerButton(
                      icon: isPremium
                          ? Icons.workspace_premium_rounded
                          : Icons.workspace_premium_outlined,
                      label: isPremium ? '프리미엄 이용 중' : '프리미엄',
                      color: cs.onSurfaceVariant,
                      onTap: () {
                        Navigator.of(context).pop(); // 드로어 먼저 닫기
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PaywallScreen(),
                          ),
                        );
                      },
                    ),

                  // 메뉴: 전체 성경
                  _DrawerButton(
                    icon: Icons.menu_book_rounded,
                    label: '전체 성경',
                    color: cs.onSurfaceVariant,
                    onTap: () => _navigateToScreen(
                        context,
                        BibleHomeScreen(
                          onThemeToggle: onThemeToggle,
                          isDark: isDark,
                        )),
                  ),

                  // 성경일독(플랜) - 펼침/접기
                  _PlanExpansionMenu(
                    color: cs.onSurfaceVariant,
                    navigateToScreen: (screen) => _navigateToScreen(context, screen),
                  ),

                  // 메뉴: 성경퀴즈
                  _DrawerButton(
                    icon: Icons.quiz_rounded,
                    label: '성경퀴즈',
                    color: cs.onSurfaceVariant,
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop(); // Drawer 먼저 닫기
                      navigator.pushNamed('/quiz');
                    },
                  ),

                  _DrawerButton(
                    icon: Icons.bookmark_added,
                    label: '북마크',
                    color: cs.onSurfaceVariant,
                    onTap: () => _navigateToScreen(context, const FavoriteListScreen()),
                  ),
                ],
              ),
            ),
          ),

          // ----- 테마 토글 Lottie 애니메이션 -----
          Padding(
            padding: EdgeInsets.only(
              bottom: Platform.isAndroid
                ? MediaQuery.of(context).padding.bottom
                : 0,
            ),
            child: _ThemeToggleLottie(
              isDark: isDark,
              onThemeToggle: onThemeToggle,
            ),
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
    final cs = theme.colorScheme;
    // 메뉴마다 색을 달리하지 않는다. 아이콘은 먹색 보조 톤 하나로
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 12, bottom: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.surfaceContainerHighest,
          child: Icon(icon, color: cs.onSurfaceVariant, size: 22),
        ),
        title: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// 아이콘 버튼 (성경일독 플랜용)
class _DrawerNumberButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DrawerNumberButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, bottom: 4),
      child: ListTile(
        leading: Icon(icon, color: color, size: 20),
        title: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 15,
            color: cs.onSurface,
          ),
        ),
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 12, bottom: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.surfaceContainerHighest,
              child: Icon(Icons.calendar_month_outlined,
                  color: cs.onSurfaceVariant, size: 22),
            ),
            title: Text(
              '성경일독(플랜)',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
            ),
            trailing: AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Icon(
                Icons.keyboard_arrow_down,
                color: cs.onSurfaceVariant,
              ),
            ),
            onTap: _toggleExpansion,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        SizeTransition(
          sizeFactor: _animation,
          axisAlignment: -1,
          child: FadeTransition(
            opacity: _animation,
            child: Padding(
              padding: const EdgeInsets.only(left: 32, right: 16),
              child: Column(
                children: [
                  _buildPlanButton(0, PlanType.day60, Icons.bolt_outlined),
                  _buildPlanButton(
                      1, PlanType.day120, Icons.trending_up_rounded),
                  _buildPlanButton(2, PlanType.day180, Icons.spa_outlined),
                  _buildPlanButton(
                      3, PlanType.day365, Icons.wb_sunny_outlined),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanButton(int index, PlanType planType, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    final available = planType.isAvailable;
    return _buildAnimatedButton(
      index,
      icon,
      available ? planType.title : '${planType.title} (준비 중)',
      available
          ? cs.onSurfaceVariant
          : cs.onSurfaceVariant.withValues(alpha: 0.5),
      () => available
          ? widget.navigateToScreen(buildPlanDayScreen(planType))
          : showPlanComingSoon(context, planType),
    );
  }

  Widget _buildAnimatedButton(
      int index, IconData icon, String label, Color color, VoidCallback onTap) {
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
              icon: icon,
              label: label,
              color: color,
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
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Lottie 애니메이션
              SizedBox(
                width: 48,
                height: 48,
                child: Lottie.asset( // 해·달 원래 색 그대로
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
                        fontWeight: FontWeight.w600,
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
                color: cs.onSurfaceVariant,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
