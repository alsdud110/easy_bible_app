import 'package:easy_bible_app/screens/bible/bible_home_screen.dart';
import 'package:easy_bible_app/screens/easyBible/easy_bible_home_screen.dart';
import 'package:easy_bible_app/screens/todayVerseCard/today_verse_card.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/request_card.dart';
import '../widgets/plan_expansion_card.dart';
import 'biblePlan/day60_screen.dart';
import 'biblePlan/day120_screen.dart';
import 'biblePlan/day180_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle; // 추가!
  final bool isDark; // 추가!
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
  _MenuItem(this.title, this.icon, this.screen, this.color, this.route);
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<Offset>> _offsetAnimations;
  late final List<Animation<double>> _opacityAnimations;

  bool _planExpanded = false;

  final List<_MenuItem> menuItems = [
    _MenuItem('전체 성경', Icons.church_rounded, const BibleHomeScreen(),
        Colors.blueAccent, '/bible'),
    _MenuItem('어성경 바이블', Icons.book_online_rounded, const EasyBibleHomeScreen(),
        Colors.blueAccent, '/easyBible'),
    _MenuItem('성경일독(플랜)', Icons.calendar_month_outlined,
        const SizedBox.shrink(), Colors.deepPurple, '/plan'),
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

  void _goPlan(int planType) {
    Widget page;
    if (planType == 60) {
      page = const Day60Screen();
    } else if (planType == 120)
      page = const Day120Screen();
    else
      page = const Day180Screen();

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
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
          '어! 성경이 읽혀지네',
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
        itemCount: menuItems.length + 1, // 오늘의 구절 카드 포함!
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
                  Navigator.of(context).pushNamed(item.route);
                },
              ),
            );
          } else {
            // 맨 마지막: 오늘의 구절 카드
            return const TodayVerseCard();
          }
        },
      ),
    );
  }
}
