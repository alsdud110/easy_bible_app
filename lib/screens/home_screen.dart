import 'package:easy_bible_app/screens/todayVerseCard/today_verse_card.dart';
import 'package:easy_bible_app/screens/favorite/favorite_list_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import 'biblePlan/plan_screens.dart';
import '../widgets/ribbon_mark.dart';
import 'biblePlan/plan_start_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/plan_progress.dart';
import '../providers/plan_progress_provider.dart';

/// 2025 트렌드 기반 홈 화면 - 성능 최적화 버전
/// - Bento Grid Layout
/// - Bold Typography
/// - Material 3 Design
/// - RepaintBoundary 최적화
/// - Const 위젯 활용
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // 인사말 캐싱 (build마다 계산하지 않음)
  late final _GreetingData _greetingData;

  @override
  void initState() {
    super.initState();

    // 단일 애니메이션 컨트롤러로 통합
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800), // 더 부드럽게
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // 인사말 데이터 한번만 계산
    _greetingData = _GreetingData.fromTime(DateTime.now());

    // 앱 로고 이미지 미리 캐싱 (성능 최적화)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetImage('assets/icon/bible_icon.png'),
        context,
      );
    });

    // 즉시 애니메이션 시작
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // SliverAppBar
          _buildSliverAppBar(theme),

          // Bento Grid Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 인사말 섹션
                      _GreetingSection(data: _greetingData),
                      const SizedBox(height: 24),

                      // Bento Grid Layout
                      _BentoGrid(isDark: isDark),

                      const SizedBox(height: 24),

                      // 오늘의 말씀 (큰 카드)
                      _TodayVerseSection(colorScheme: theme.colorScheme),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      endDrawer: CustomDrawer(
        onThemeToggle: widget.onThemeToggle ?? () {},
        isDark: widget.isDark,
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 70,
      titleSpacing: 0,
      title: RepaintBoundary(
        child: Row(
          children: [
            // 앱 로고 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon/bible_icon.png',
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                cacheWidth: 140, // 성능 최적화를 위한 캐시 크기
              ),
            ),
            const SizedBox(width: 10),
            // Bold Typography
            Text(
              'All in Bible',
              style: GoogleFonts.dancingScript(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 26,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              size: 28,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

// 인사말 데이터 클래스 (불변)
class _GreetingData {
  final String text;
  final IconData icon;

  const _GreetingData({required this.text, required this.icon});

  factory _GreetingData.fromTime(DateTime time) {
    final hour = time.hour;
    if (hour < 12) {
      return const _GreetingData(
        text: '좋은 아침이에요',
        icon: Icons.wb_sunny_rounded,
      );
    } else if (hour < 18) {
      return const _GreetingData(
        text: '좋은 오후에요',
        icon: Icons.wb_twilight_rounded,
      );
    } else {
      return const _GreetingData(
        text: '좋은 저녁이에요',
        icon: Icons.nightlight_round,
      );
    }
  }
}

// 인사말 섹션 (독립 위젯화)
class _GreetingSection extends StatelessWidget {
  final _GreetingData data;

  const _GreetingSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, size: 22, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                data.text,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '오늘도 말씀과 함께하세요',
            style: TextStyle(
              fontSize: 15,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// Bento Grid (독립 위젯화 + 그래디언트 캐싱 + 애니메이션)
class _BentoGrid extends StatefulWidget {
  final bool isDark;

  const _BentoGrid({required this.isDark});

  @override
  State<_BentoGrid> createState() => _BentoGridState();
}

class _BentoGridState extends State<_BentoGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // 각 카드마다 순차적으로 나타나는 애니메이션
    _cardAnimations = List.generate(4, (index) {
      final start = index * 0.15; // 0.0, 0.15, 0.30, 0.45
      final end = start + 0.55; // 0.55, 0.70, 0.85, 1.0
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 첫 번째 행
        Row(
          children: [
            Expanded(
              flex: 2,
              child: FadeTransition(
                opacity: _cardAnimations[0],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_cardAnimations[0]),
                  child: RepaintBoundary(
                    child: _BentoCard(
                      title: '전체 성경',
                      subtitle: '66권 탐독하기',
                      icon: Icons.menu_book_rounded,
                      height: 160,
                      onTap: () => Navigator.of(context).pushNamed('/bible'),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: FadeTransition(
                opacity: _cardAnimations[1],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_cardAnimations[1]),
                  child: RepaintBoundary(
                    child: _BentoCard(
                      title: '북마크',
                      subtitle: '',
                      icon: Icons.bookmark_border_rounded,
                      height: 160,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FavoriteListScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 두 번째 행
        Row(
          children: [
            Expanded(
              flex: 1,
              child: FadeTransition(
                opacity: _cardAnimations[2],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_cardAnimations[2]),
                  child: RepaintBoundary(
                    child: _BentoCard(
                      title: '성경퀴즈',
                      subtitle: '재미있게',
                      icon: Icons.quiz_outlined,
                      height: 140,
                      onTap: () => Navigator.of(context).pushNamed('/quiz'),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: FadeTransition(
                opacity: _cardAnimations[3],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_cardAnimations[3]),
                  child: RepaintBoundary(
                    child: _PlanBentoCard(isDark: widget.isDark),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 홈 타일 공통 외형: 종이색 카드 + 헤어라인. 색은 내용(가름끈)에만.
BoxDecoration _tileDecoration(ColorScheme cs) => BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: cs.outlineVariant),
    );

// Bento 카드 (최적화 + 반응형)
class _BentoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final double height;
  final VoidCallback onTap;

  const _BentoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textColor = cs.onSurface;
    final iconColor = cs.onSurfaceVariant;
    final screenWidth = MediaQuery.of(context).size.width;

    // 화면 크기에 따라 동적으로 폰트 크기 조절
    final titleFontSize = screenWidth < 380 ? 18.0 : 20.0;
    final subtitleFontSize = screenWidth < 380 ? 12.0 : 13.0;
    final iconSize = screenWidth < 380 ? 24.0 : 28.0;
    final padding = screenWidth < 380 ? 16.0 : 20.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: height,
            decoration: _tileDecoration(cs),
            child: Stack(
              children: [
              // 텍스트 콘텐츠
              Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(icon, color: iconColor, size: iconSize),
                    const SizedBox(height: 8),
                    // FittedBox로 텍스트 자동 조절
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: subtitleFontSize,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ],
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

// 성경일독 플랜 카드 (Provider 최적화 + 반응형)
class _PlanBentoCard extends StatelessWidget {
  final bool isDark;

  const _PlanBentoCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Selector로 필요한 값만 구독
    final hasAnyPlan = context.select<PlanProgressProvider, bool>(
      (provider) => provider.hasAnyPlan,
    );
    final planCount = context.select<PlanProgressProvider, int>(
      (provider) => provider.plans.length,
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final cs = Theme.of(context).colorScheme;

    // 화면 크기에 따라 동적으로 조절
    final titleFontSize = screenWidth < 380 ? 18.0 : 20.0;
    final subtitleFontSize = screenWidth < 380 ? 12.0 : 13.0;
    final iconSize = screenWidth < 380 ? 24.0 : 28.0;
    final badgeFontSize = screenWidth < 380 ? 12.0 : 13.0;
    final padding = screenWidth < 380 ? 16.0 : 20.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final provider = context.read<PlanProgressProvider>();
          _showPlanBottomSheet(context, provider);
        },
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: 140,
            decoration: _tileDecoration(cs),
            child: Stack(
              children: [
                // 진행 중인 플랜이 있으면 가름끈을 카드 위쪽에 드리운다
                if (hasAnyPlan)
                  Positioned(
                    top: 0,
                    right: padding,
                    child: const RibbonMark(width: 12, height: 28),
                  ),
              // 콘텐츠
              Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 상단: 아이콘 + 뱃지
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: cs.onSurfaceVariant,
                          size: iconSize,
                        ),
                        if (hasAnyPlan)
                          Flexible(
                            child: Padding(
                              // 가름끈 자리만큼 비켜 둔다
                              padding: EdgeInsets.only(right: 12 + 8),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$planCount개 진행 중',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontSize: badgeFontSize,
                                    fontWeight: FontWeight.w500,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    // 하단: 타이틀
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '성경일독',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            !hasAnyPlan ? '플랜 시작하기' : '진행 중인 플랜 보기',
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  void _showPlanBottomSheet(
      BuildContext context, PlanProgressProvider provider) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 타이틀
            Text(
              '성경일독 플랜',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '원하는 플랜을 선택하세요',
              style: TextStyle(
                fontSize: 15,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // 플랜 옵션들 (4개라 작은 화면에서도 넘치지 않도록 스크롤 허용)
            // 플랜마다 색을 달리하지 않고 아이콘으로만 구분한다
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _PlanOption(
                      provider: provider,
                      planType: PlanType.day60,
                      icon: Icons.bolt_outlined,
                    ),
                    const SizedBox(height: 8),
                    _PlanOption(
                      provider: provider,
                      planType: PlanType.day120,
                      icon: Icons.trending_up_rounded,
                    ),
                    const SizedBox(height: 8),
                    _PlanOption(
                      provider: provider,
                      planType: PlanType.day180,
                      icon: Icons.spa_outlined,
                    ),
                    const SizedBox(height: 8),
                    _PlanOption(
                      provider: provider,
                      planType: PlanType.day365,
                      icon: Icons.wb_sunny_outlined,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// 플랜 옵션 위젯
class _PlanOption extends StatelessWidget {
  final PlanProgressProvider provider;
  final PlanType planType;
  final IconData icon;

  const _PlanOption({
    required this.provider,
    required this.planType,
    required this.icon,
  });

  String get title => planType.title;
  String get description => planType.description;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasPlan = provider.hasPlan(planType);
    final progress = provider.getProgressPercent(planType).toDouble();
    final isAvailable = planType.isAvailable;

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.55,
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!isAvailable) {
            showPlanComingSoon(context, planType);
            return;
          }
          Navigator.pop(context);

          final Widget page = hasPlan
              ? buildPlanDayScreen(planType)
              : PlanStartScreen(planType: planType);

          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => page),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: hasPlan ? cs.surface : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasPlan ? cs.outline : cs.outlineVariant,
            ),
          ),
          child: Stack(
            children: [
              // 진행 중인 플랜에만 가름끈
              if (hasPlan)
                const Positioned(
                  top: 0,
                  right: 48,
                  child: RibbonMark(width: 10, height: 22),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
            children: [
              // 아이콘 (나머지 모서리: 16 - 16 패딩 → 최소값 8)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hasPlan ? cs.surfaceContainerHighest : cs.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: cs.onSurfaceVariant, size: 22),
              ),
              const SizedBox(width: 16),
              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                        if (hasPlan || !isAvailable) ...[
                          const SizedBox(width: 8),
                          Text(
                            isAvailable ? '진행 중' : '준비 중',
                            style: TextStyle(
                              color: isAvailable
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (hasPlan && progress > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress / 100,
                                backgroundColor: cs.surfaceContainerHighest,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(cs.primary),
                                minHeight: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${progress.toInt()}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // 화살표
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
                size: 22,
              ),
            ],
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

// 오늘의 말씀 섹션
class _TodayVerseSection extends StatelessWidget {
  final ColorScheme colorScheme;

  const _TodayVerseSection({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '오늘의 말씀',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const TodayVerseCard(),
        ],
      ),
    );
  }
}
