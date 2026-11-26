import 'package:easy_bible_app/screens/todayVerseCard/today_verse_card.dart';
import 'package:easy_bible_app/screens/favorite/favorite_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/ribbon_mark.dart';
import '../models/plan_progress.dart';
import '../models/quiz_history.dart';
import '../providers/favorite_provider.dart';
import '../providers/plan_progress_provider.dart';
import '../services/quiz_history_service.dart';
import 'biblePlan/plan_screens.dart';
import 'biblePlan/plan_start_screen.dart';

/// 홈 화면.
/// 오늘 할 일(읽을 곳, 오늘의 말씀)을 첫 화면에 두고,
/// 나머지 기능은 아래 목차형 바로가기로 모은다.
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  )..forward();

  // 앱을 켜 둔 채 날짜가 바뀌면 날짜 줄과 오늘의 말씀을 새로 그리기 위한 키
  String _today = _dateKey();

  static String _dateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _dateKey() != _today) {
      setState(() => _today = _dateKey());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(theme),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            sliver: SliverToBoxAdapter(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOut,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DateLine(key: ValueKey(_today)),
                    const SizedBox(height: 12),
                    const _TodayReadingCard(),
                    const SizedBox(height: 24),
                    const _SectionLabel('오늘의 말씀'),
                    // TodayVerseCard 자체에 위 12, 아래 16 여백이 있다
                    // 날짜가 바뀌면 키가 바뀌어 새 상태로 다시 불러옴
                    TodayVerseCard(key: ValueKey(_today)),
                    const SizedBox(height: 16),
                    const _ShortcutList(),
                  ],
                ),
              ),
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
    final cs = theme.colorScheme;
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 56,
      titleSpacing: 20,
      // 앱 아이콘 대신 본문과 같은 명조체 워드마크
      title: Text(
        'All in Bible',
        style: TextStyle(
          fontFamily: 'ChosunCentennial',
          color: cs.onSurface,
          fontSize: 21,
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded, size: 26, color: cs.onSurface),
            tooltip: '메뉴',
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 날짜 한 줄
// ─────────────────────────────────────────────
class _DateLine extends StatelessWidget {
  const _DateLine({super.key});

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return _SectionLabel(
      '${now.month}월 ${now.day}일 ${_weekdays[now.weekday - 1]}요일',
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// 홈 카드 공통 외형: 종이색 카드 + 헤어라인. 색은 내용(가름끈)에만.
BoxDecoration _tileDecoration(ColorScheme cs) => BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: cs.outlineVariant),
    );

// ─────────────────────────────────────────────
// 오늘 읽을 곳
// ─────────────────────────────────────────────

/// 홈에 대표로 보여 줄 플랜: 끝나지 않은 플랜 중 가장 최근에 시작한 것.
PlanProgress? _pickActivePlan(Iterable<PlanProgress> plans) {
  final active = plans
      .where((p) => !p.isCompleted && p.planType.isAvailable)
      .toList()
    ..sort((a, b) => b.startDate.compareTo(a.startDate));
  return active.isEmpty ? null : active.first;
}

class _TodayReadingCard extends StatelessWidget {
  const _TodayReadingCard();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProgressProvider>();
    final plan = _pickActivePlan(provider.plans.values);

    if (plan == null) return const _StartPlanCard();

    final cs = Theme.of(context).colorScheme;
    final type = plan.planType;
    final day = plan.nextDay;
    final readings = type.readings;
    final range = day - 1 < readings.length ? readings[day - 1].join(' · ') : '';
    final done = plan.completedDays.length;
    final otherCount = provider.plans.length - 1;

    return Container(
      decoration: _tileDecoration(cs),
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            right: 20,
            child: RibbonMark(width: 12, height: 28),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  // 가름끈 자리만큼 비켜 둔다
                  padding: const EdgeInsets.only(right: 32),
                  child: Text(
                    '오늘 읽을 곳 · ${plan.planName} $day일차',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  range,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: plan.progressPercentage,
                          minHeight: 4,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(cs.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$done / ${type.totalDays}일',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => buildPlanDayScreen(type),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '이어서 읽기',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (otherCount > 0)
                  Center(
                    child: TextButton(
                      onPressed: () => _showPlanBottomSheet(context),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.onSurfaceVariant,
                      ),
                      child: Text(
                        '다른 플랜 $otherCount개',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 진행 중인 플랜이 없을 때
class _StartPlanCard extends StatelessWidget {
  const _StartPlanCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: _tileDecoration(cs),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '성경일독',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '매일 읽을 분량을 정해 드려요',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '60일부터 365일까지, 속도에 맞는 플랜을 고르세요',
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _showPlanBottomSheet(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '플랜 고르기',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 바로가기 (목차형)
// ─────────────────────────────────────────────
class _ShortcutList extends StatefulWidget {
  const _ShortcutList();

  @override
  State<_ShortcutList> createState() => _ShortcutListState();
}

class _ShortcutListState extends State<_ShortcutList> {
  QuizHistoryItem? _lastQuiz;

  @override
  void initState() {
    super.initState();
    _loadLastQuiz();
  }

  Future<void> _loadLastQuiz() async {
    final history = await QuizHistoryService().getHistory();
    if (!mounted) return;
    setState(() => _lastQuiz = history.isEmpty ? null : history.first);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final favoriteCount = context.select<FavoriteProvider, int>(
      (p) => p.favorites.length,
    );
    final planCount = context.select<PlanProgressProvider, int>(
      (p) => p.plans.length,
    );
    final quiz = _lastQuiz;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('바로가기'),
        const SizedBox(height: 8),
        Divider(height: 1, thickness: 1, color: cs.onSurface),
        _ShortcutRow(
          label: '전체 성경',
          value: '66권',
          onTap: () => Navigator.of(context).pushNamed('/bible'),
        ),
        _ShortcutRow(
          label: '성경일독',
          value: planCount > 0 ? '플랜 $planCount개' : '',
          onTap: () => _showPlanBottomSheet(context),
        ),
        _ShortcutRow(
          label: '북마크',
          value: favoriteCount > 0 ? '$favoriteCount개' : '',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FavoriteListScreen()),
          ),
        ),
        _ShortcutRow(
          label: '성경퀴즈',
          value: quiz == null
              ? ''
              : '최근 ${quiz.correctCount} / ${quiz.totalQuestions}',
          onTap: () async {
            await Navigator.of(context).pushNamed('/quiz');
            _loadLastQuiz(); // 퀴즈를 풀고 돌아오면 최근 점수 갱신
          },
        ),
      ],
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ShortcutRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: CustomPaint(
                  size: const Size.fromHeight(1),
                  painter: _DotLeaderPainter(cs.outline),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (value.isNotEmpty) ...[
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right_rounded,
                size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// 목차의 점선 리더 (제목 …… 값)
class _DotLeaderPainter extends CustomPainter {
  final Color color;
  _DotLeaderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const gap = 4.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawCircle(Offset(x + 0.75, size.height / 2), 0.75, paint);
    }
  }

  @override
  bool shouldRepaint(_DotLeaderPainter old) => old.color != color;
}

// ─────────────────────────────────────────────
// 플랜 선택 바텀시트
// ─────────────────────────────────────────────
void _showPlanBottomSheet(BuildContext context) {
  final provider = context.read<PlanProgressProvider>();
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
          Text(
            '성경일독 플랜',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '원하는 플랜을 선택하세요',
            style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          // 4개라 작은 화면에서도 넘치지 않도록 스크롤 허용.
          // 플랜마다 색을 달리하지 않고 아이콘으로만 구분한다.
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

