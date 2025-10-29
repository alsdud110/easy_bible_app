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

/// 2025 트렌드 기반 홈 화면
/// - Bento Grid Layout (벤토 그리드)
/// - Bold Typography (대담한 타이포그래피)
/// - Material 3 Design
/// - Micro-interactions
/// - 테마 컬러 시스템 통합
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      _fadeController.forward();
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 현대적인 SliverAppBar
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 70,
            titleSpacing: 0,
            title: Row(
              children: [
                // 앱 로고 이미지
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/icon/bible_icon.png',
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                // Bold Typography (2025 트렌드)
                Text(
                  'All in Bible',
                  style: GoogleFonts.dancingScript(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            actions: [
              // 햄버거 메뉴
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    size: 28,
                    color: cs.onSurface,
                  ),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),

          // Bento Grid Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 인사말 섹션
                        _buildGreetingSection(cs, isDark),
                        const SizedBox(height: 24),

                        // Bento Grid Layout
                        _buildBentoGrid(context, cs, isDark),

                        const SizedBox(height: 24),

                        // 오늘의 말씀 (큰 카드)
                        _buildTodayVerseSection(cs, isDark),

                        const SizedBox(height: 32),
                      ],
                    ),
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

  // 인사말 섹션
  Widget _buildGreetingSection(ColorScheme cs, bool isDark) {
    final hour = DateTime.now().hour;
    String greeting = '안녕하세요';
    IconData greetingIcon = Icons.wb_sunny_rounded;

    if (hour < 12) {
      greeting = '좋은 아침이에요';
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour < 18) {
      greeting = '좋은 오후에요';
      greetingIcon = Icons.wb_twilight_rounded;
    } else {
      greeting = '좋은 저녁이에요';
      greetingIcon = Icons.nightlight_round;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              greetingIcon,
              size: 24,
              color: cs.primary,
            ),
            const SizedBox(width: 8),
            Text(
              greeting,
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
            color: cs.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Bento Grid 레이아웃 (2025 트렌드의 핵심!)
  Widget _buildBentoGrid(BuildContext context, ColorScheme cs, bool isDark) {
    return Column(
      children: [
        // 첫 번째 행: 전체 성경 (큰 카드) + 북마크 (작은 카드)
        Row(
          children: [
            // 전체 성경 - 2/3 너비
            Expanded(
              flex: 2,
              child: _buildBentoCard(
                context: context,
                title: '전체 성경',
                subtitle: '66권 탐독하기',
                icon: Icons.menu_book_rounded,
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          DarkColors.primary,
                          DarkColors.secondary,
                        ]
                      : [
                          LightColors.primary,
                          LightColors.secondary,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                height: 160,
                onTap: () => Navigator.of(context).pushNamed('/bible'),
              ),
            ),
            const SizedBox(width: 16),

            // 북마크 - 1/3 너비
            Expanded(
              flex: 1,
              child: _buildBentoCard(
                context: context,
                title: '북마크',
                subtitle: '',
                icon: Icons.bookmark_rounded,
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          DarkColors.secondary,
                          DarkColors.accent,
                        ]
                      : [
                          LightColors.secondary,
                          LightColors.accent,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
          ],
        ),

        const SizedBox(height: 16),

        // 두 번째 행: 어성경 바이블 (작은 카드) + 성경일독 (큰 카드)
        Row(
          children: [
            // 어성경 바이블 - 1/3 너비
            Expanded(
              flex: 1,
              child: _buildBentoCard(
                context: context,
                title: '어성경',
                subtitle: 'Coming',
                icon: Icons.book_online_rounded,
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          DarkColors.surface,
                          DarkColors.card,
                        ]
                      : [
                          const Color(0xFFF3F4F6),
                          const Color(0xFFE5E7EB),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                height: 140,
                isGrayCard: true,
                onTap: () => _showComingSoonDialog(context),
              ),
            ),
            const SizedBox(width: 16),

            // 성경일독 플랜 - 2/3 너비
            Expanded(
              flex: 2,
              child: _buildPlanBentoCard(
                context: context,
                cs: cs,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Bento 카드 위젯
  Widget _buildBentoCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required double height,
    required VoidCallback onTap,
    bool isGrayCard = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 회색 카드의 경우 텍스트 색상 다르게
    final textColor =
        isGrayCard && !isDark ? LightColors.onSurface : Colors.white;
    final iconColor =
        isGrayCard && !isDark ? LightColors.bodyMedium : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 배경 패턴 (미묘한 효과)
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 120,
                color: iconColor.withOpacity(0.1),
              ),
            ),

            // 텍스트 콘텐츠
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.7),
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
    );
  }

  // 성경일독 플랜 Bento 카드 (특별 처리)
  Widget _buildPlanBentoCard({
    required BuildContext context,
    required ColorScheme cs,
    required bool isDark,
  }) {
    return Consumer<PlanProgressProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: () {
            _showPlanBottomSheet(context, provider);
          },
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        DarkColors.accent,
                        DarkColors.secondary,
                      ]
                    : [
                        LightColors.accent,
                        LightColors.primary,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : LightColors.primary.withOpacity(0.2),
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
                    color: Colors.white.withOpacity(0.1),
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
                          // 진행 중인 플랜 수
                          if (provider.hasAnyPlan)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${provider.plans.length}개 진행 중',
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
                            !provider.hasAnyPlan ? '플랜 시작하기' : '진행 중인 플랜 보기',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
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
        );
      },
    );
  }

  // 오늘의 말씀 섹션
  Widget _buildTodayVerseSection(ColorScheme cs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '오늘의 말씀',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const TodayVerseCard(),
      ],
    );
  }

  // 성경일독 플랜 선택 바텀시트
  void _showPlanBottomSheet(
      BuildContext context, PlanProgressProvider provider) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
                  color: cs.onSurface.withOpacity(0.2),
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
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),

            // 플랜 옵션들
            _buildPlanOption(
              context: context,
              provider: provider,
              planType: PlanType.day60,
              days: 60,
              title: '60일 플랜',
              description: '두 달로 성경 완독',
              icon: Icons.flash_on_rounded,
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 12),
            _buildPlanOption(
              context: context,
              provider: provider,
              planType: PlanType.day120,
              days: 120,
              title: '120일 플랜',
              description: '네 달로 성경 완독',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 12),
            _buildPlanOption(
              context: context,
              provider: provider,
              planType: PlanType.day180,
              days: 180,
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

  // 플랜 옵션 위젯
  Widget _buildPlanOption({
    required BuildContext context,
    required PlanProgressProvider provider,
    required PlanType planType,
    required int days,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasPlan = provider.hasPlan(planType);
    final progress = provider.getProgressPercent(planType).toDouble();

    return GestureDetector(
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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
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
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
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
                      color: cs.onSurface.withOpacity(0.6),
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
                              backgroundColor: color.withOpacity(0.2),
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
              color: cs.onSurface.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Coming Soon 다이얼로그
  void _showComingSoonDialog(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
          style: TextStyle(
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
}
