import 'package:easy_bible_app/screens/todayVerseCard/today_verse_card.dart';
import 'package:easy_bible_app/screens/favorite/favorite_list_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_drawer.dart';
import 'biblePlan/day60_screen.dart';
import 'biblePlan/day120_screen.dart';
import 'biblePlan/day180_screen.dart';
import 'biblePlan/plan_start_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/plan_progress.dart';
import '../providers/plan_progress_provider.dart';
import '../theme/colors.dart';

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
                fontWeight: FontWeight.w900,
                fontSize: 26,
                letterSpacing: -0.5,
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
              Icon(data.icon, size: 24, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                data.text,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '오늘도 말씀과 함께하세요',
            style: TextStyle(
              fontSize: 15,
              color: cs.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
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
                      gradient: widget.isDark
                          ? _CachedGradients.darkPrimaryGradient
                          : _CachedGradients.lightPrimaryGradient,
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
                      icon: Icons.bookmark_rounded,
                      gradient: widget.isDark
                          ? _CachedGradients.darkSecondaryGradient
                          : _CachedGradients.lightSecondaryGradient,
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
                      title: '어성경',
                      subtitle: 'Coming',
                      icon: Icons.book_online_rounded,
                      gradient: widget.isDark
                          ? _CachedGradients.darkGrayGradient
                          : _CachedGradients.lightGrayGradient,
                      height: 140,
                      isGrayCard: true,
                      onTap: () => _showComingSoonDialog(context),
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

  void _showComingSoonDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Icon(Icons.construction_rounded, color: cs.primary),
            const SizedBox(width: 12),
            Text(
              '준비 중',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          '해당 메뉴는 준비 중입니다!',
          style: TextStyle(color: cs.onSurface),
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
}

// 그래디언트 캐싱 (매번 생성하지 않음)
class _CachedGradients {
  static final lightPrimaryGradient = LinearGradient(
    colors: [LightColors.primary, LightColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final lightSecondaryGradient = LinearGradient(
    colors: [LightColors.secondary, LightColors.accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final lightGrayGradient = LinearGradient(
    colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final darkPrimaryGradient = LinearGradient(
    colors: [DarkColors.primary, DarkColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final darkSecondaryGradient = LinearGradient(
    colors: [DarkColors.secondary, DarkColors.accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final darkGrayGradient = LinearGradient(
    colors: [DarkColors.surface, DarkColors.card],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final lightAccentGradient = LinearGradient(
    colors: [LightColors.accent, LightColors.primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final darkAccentGradient = LinearGradient(
    colors: [DarkColors.accent, DarkColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Bento 카드 (최적화)
class _BentoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final double height;
  final VoidCallback onTap;
  final bool isGrayCard;

  const _BentoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.height,
    required this.onTap,
    this.isGrayCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isGrayCard && !isDark ? LightColors.onSurface : Colors.white;
    final iconColor = isGrayCard && !isDark ? LightColors.bodyMedium : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 배경 패턴
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: 120,
                  color: iconColor.withValues(alpha: 0.1),
                ),
              ),
              // 텍스트 콘텐츠
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(icon, color: iconColor, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
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
    );
  }
}

// 성경일독 플랜 카드 (Provider 최적화)
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final provider = context.read<PlanProgressProvider>();
          _showPlanBottomSheet(context, provider);
        },
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 140,
          decoration: BoxDecoration(
            gradient: isDark
                ? _CachedGradients.darkAccentGradient
                : _CachedGradients.lightAccentGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : LightColors.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 배경 패턴
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              // 콘텐츠
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 상단: 아이콘 + 뱃지
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        if (hasAnyPlan)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$planCount개 진행 중',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // 하단: 타이틀
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '성경일독',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          !hasAnyPlan ? '플랜 시작하기' : '진행 중인 플랜 보기',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
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
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '원하는 플랜을 선택하세요',
              style: TextStyle(
                fontSize: 15,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            // 플랜 옵션들
            _PlanOption(
              provider: provider,
              planType: PlanType.day60,
              title: '60일 플랜',
              description: '두 달로 성경 완독',
              icon: Icons.flash_on_rounded,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            _PlanOption(
              provider: provider,
              planType: PlanType.day120,
              title: '120일 플랜',
              description: '네 달로 성경 완독',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 12),
            _PlanOption(
              provider: provider,
              planType: PlanType.day180,
              title: '180일 플랜',
              description: '여유있게 성경 완독',
              icon: Icons.nature_people_rounded,
              color: const Color(0xFF8B5CF6),
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
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _PlanOption({
    required this.provider,
    required this.planType,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasPlan = provider.hasPlan(planType);
    final progress = provider.getProgressPercent(planType).toDouble();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);

          Widget page;
          if (hasPlan) {
            if (planType == PlanType.day60) {
              page = const Day60Screen();
            } else if (planType == PlanType.day120) {
              page = const Day120Screen();
            } else {
              page = const Day180Screen();
            }
          } else {
            page = PlanStartScreen(planType: planType);
          }

          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => page),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasPlan ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // 아이콘
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
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
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        if (hasPlan) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '진행 중',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
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
                        color: cs.onSurface.withValues(alpha: 0.6),
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
                                backgroundColor: color.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${progress.toInt()}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color,
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
                Icons.arrow_forward_ios_rounded,
                color: cs.onSurface.withValues(alpha: 0.3),
                size: 20,
              ),
            ],
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
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '오늘의 말씀',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
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
