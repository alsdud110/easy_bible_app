import 'package:easy_bible_app/screens/home_screen.dart';
import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final VoidCallback? onThemeToggle;
  final bool isDark;
  const CustomDrawer({
    super.key,
    this.onThemeToggle,
    this.isDark = false,
  });

  void _fadePushAndRemove(BuildContext context, Widget screen) {
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
      ),
      backgroundColor: cs.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          SafeArea(
            top: false,
            bottom: false,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withOpacity(0.92),
                    cs.primary.withOpacity(0.78)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 46.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 20),
                    CircleAvatar(
                      backgroundColor: cs.surface,
                      radius: 32,
                      child: Icon(Icons.person,
                          size: 38, color: cs.primary.withOpacity(0.72)),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '황민영',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '20210701',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _DrawerButton(
            icon: Icons.access_time_rounded,
            label: '어성경 바이블',
            color: cs.primary,
            onTap: () => _fadePushAndRemove(context, const HomeScreen()),
          ),
          _DrawerButton(
            icon: Icons.flight_takeoff_rounded,
            label: '성경일독(플랜)',
            color: cs.secondary,
            onTap: () => _fadePushAndRemove(context, const HomeScreen()),
          ),
          _DrawerButton(
            icon: Icons.person_outline_rounded,
            label: '마이페이지',
            color: cs.secondary,
            onTap: () => _fadePushAndRemove(context, const HomeScreen()),
          ),
          const Spacer(),

          // ----- 테마 토글 스위치 추가 -----
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(
              thickness: 1.1,
              height: 1,
              color: theme.dividerColor,
              indent: 0,
              endIndent: 0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 8),
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red[400]),
              title: Text(
                '로그아웃',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface.withOpacity(0.52),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
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
