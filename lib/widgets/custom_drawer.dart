import 'package:flutter/material.dart';

// 각 스크린 import 추가
import '../../screens/bible/bible_home_screen.dart'; // 전체 성경
import '../../screens/home_screen.dart'; // 어성경 바이블(홈)
import '../../screens/biblePlan/day60_screen.dart';
import '../../screens/biblePlan/day120_screen.dart';
import '../../screens/biblePlan/day180_screen.dart';
import '../../screens/favorite/favorite_list_screen.dart'; // ✅ 추가
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

  // ✅ 준비 중 알림 함수 추가
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
          // ✅ 심플한 헤더 - 중앙 정렬
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
                  top: 20.0,
                  bottom: 10.0,
                  left: 24,
                  right: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // ✅ 중앙 정렬
                  mainAxisAlignment: MainAxisAlignment.center, // ✅ 세로 중앙 정렬
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final imageSize =
                            (constraints.maxWidth * 0.9).clamp(100.0, 200.0);

                        return Image.asset(
                          'assets/icon/bible_icon.png',
                          width: imageSize,
                          height: imageSize,
                        );
                      },
                    ),
                    Text(
                      'All in Bible',
                      style: GoogleFonts.dancingScript(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

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

          // ✅ 좋아하는 성경 구절
          _DrawerButton(
            icon: Icons.star_rounded,
            label: '좋아하는 성경 구절',
            color: Colors.amber.shade700,
            onTap: () => _navigateToScreen(context, const FavoriteListScreen()),
          ),

          const Spacer(),

          // ----- 테마 토글 스위치 -----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Icon(
                  isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                  color: cs.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isDark ? "어두운 테마" : "밝은 테마",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Switch(
                  value: isDark,
                  onChanged: (_) => onThemeToggle?.call(),
                  activeColor: cs.primary,
                  inactiveThumbColor: cs.surface,
                  inactiveTrackColor: cs.secondary.withOpacity(0.44),
                ),
              ],
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

class _PlanExpansionMenuState extends State<_PlanExpansionMenu> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DrawerButton(
          icon: Icons.flight_takeoff_rounded,
          label: '성경일독(플랜)',
          color: widget.color,
          onTap: () => setState(() => expanded = !expanded),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(left: 34, right: 18),
            child: Column(
              children: [
                _DrawerNumberButton(
                  number: '60',
                  label: 'DAY60 플랜',
                  color: widget.color,
                  onTap: () => widget.navigateToScreen(const Day60Screen()),
                ),
                _DrawerNumberButton(
                  number: '120',
                  label: 'DAY120 플랜',
                  color: widget.color,
                  onTap: () => widget.navigateToScreen(const Day120Screen()),
                ),
                _DrawerNumberButton(
                  number: '180',
                  label: 'DAY180 플랜',
                  color: widget.color,
                  onTap: () => widget.navigateToScreen(const Day180Screen()),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
