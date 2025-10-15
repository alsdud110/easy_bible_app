import 'package:easy_bible_app/screens/bible/bible_home_screen.dart';
import 'package:easy_bible_app/screens/easyBible/easy_bible_home_screen.dart';
import 'package:easy_bible_app/screens/todayVerseCard/today_verse_card.dart';
import 'package:easy_bible_app/screens/favorite/favorite_list_screen.dart'; // ✅ 추가
import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/request_card.dart';
import '../widgets/plan_expansion_card.dart';
import 'biblePlan/day60_screen.dart';
import 'biblePlan/day120_screen.dart';
import 'biblePlan/day180_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  final bool isDark;
  const HomeScreen({
    super.key,
    this.onThemeToggle,
    this.isDark = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Widget screen;
  final Color color;
  final String route;
  final bool isComingSoon;

  _MenuItem(
    this.title,
    this.icon,
    this.screen,
    this.color,
    this.route, {
    this.isComingSoon = false,
  });
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<Offset>> _offsetAnimations;
  late final List<Animation<double>> _opacityAnimations;

  bool _planExpanded = false;

  final List<_MenuItem> menuItems = [
    _MenuItem('전체 성경', Icons.church_rounded, const BibleHomeScreen(),
        Colors.blueAccent, '/bible'),
    _MenuItem(
      '어성경 바이블',
      Icons.book_online_rounded,
      const EasyBibleHomeScreen(),
      Colors.blueAccent,
      '/easyBible',
      isComingSoon: true,
    ),
    _MenuItem('성경일독(플랜)', Icons.calendar_month_outlined,
        const SizedBox.shrink(), Colors.deepPurple, '/plan'),
    // ✅ 즐겨찾기 메뉴 추가
    _MenuItem(
      '좋아하는 성경 구절',
      Icons.star_rounded,
      const FavoriteListScreen(),
      Colors.amber,
      '/favorites',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      menuItems.length,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 390),
        vsync: this,
      ),
    );

    _offsetAnimations = List.generate(menuItems.length, (i) {
      final isLeft = i % 2 == 0;
      final begin = isLeft ? const Offset(-0.17, 0) : const Offset(0.17, 0);
      return Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.ease),
      );
    });

    _opacityAnimations = List.generate(
      menuItems.length,
      (i) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeIn),
      ),
    );

    Future.delayed(const Duration(milliseconds: 100), _startAnimations);
  }

  void _startAnimations() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 90));
      _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _showComingSoonDialog(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: Divider(
            thickness: 0.2,
            height: 0.5,
            color: Colors.black,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor:
            theme.appBarTheme.titleTextStyle?.color ?? Colors.black,
        scrolledUnderElevation: theme.appBarTheme.scrolledUnderElevation ?? 0,
        title: Text(
          '어! 성경이 읽어지네',
          style: theme.appBarTheme.titleTextStyle,
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, size: 28),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              color: theme.appBarTheme.iconTheme?.color,
            ),
          ),
        ],
      ),
      endDrawer: CustomDrawer(
        onThemeToggle: widget.onThemeToggle ?? () {},
        isDark: widget.isDark,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: menuItems.length + 1,
        separatorBuilder: (_, i) => i == menuItems.length - 1
            ? const SizedBox(height: 28)
            : const SizedBox(height: 20),
        itemBuilder: (context, i) {
          if (i < menuItems.length) {
            final item = menuItems[i];

            if (item.title == '성경일독(플랜)') {
              return AnimatedBuilder(
                animation: _controllers[i],
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimations[i].value,
                    child: SlideTransition(
                      position: _offsetAnimations[i],
                      child: child,
                    ),
                  );
                },
                child: PlanExpansionCard(
                  expanded: _planExpanded,
                  onTap: () {
                    setState(() => _planExpanded = !_planExpanded);
                  },
                  onPlanTap: (context, planType) {
                    Widget page;
                    if (planType == 60) {
                      page = const Day60Screen();
                    } else if (planType == 120) {
                      page = const Day120Screen();
                    } else {
                      page = const Day180Screen();
                    }
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (_, __, ___) => page,
                        transitionsBuilder: (_, animation, __, child) =>
                            FadeTransition(opacity: animation, child: child),
                      ),
                    );
                  },
                ),
              );
            }

            return AnimatedBuilder(
              animation: _controllers[i],
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimations[i].value,
                  child: SlideTransition(
                    position: _offsetAnimations[i],
                    child: child,
                  ),
                );
              },
              child: RequestCard(
                title: item.title,
                iconData: item.icon,
                onTap: () {
                  if (item.isComingSoon) {
                    _showComingSoonDialog(context);
                  } else if (item.route == '/favorites') {
                    // ✅ 즐겨찾기 페이지로 직접 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FavoriteListScreen(),
                      ),
                    );
                  } else {
                    Navigator.of(context).pushNamed(item.route);
                  }
                },
              ),
            );
          } else {
            return const TodayVerseCard();
          }
        },
      ),
    );
  }
}
