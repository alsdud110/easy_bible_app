import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/bible_180.dart';
import '../../models/bible_json_loader.dart';
import '../../utils/extract_verses.dart';
import '../../utils/pretty_range_label.dart';
import '../../providers/plan_progress_provider.dart';
import 'plan_verse_list_view.dart';

class Day180Screen extends StatefulWidget {
  const Day180Screen({super.key});

  @override
  State<Day180Screen> createState() => _Day180ScreenState();
}

class _Day180ScreenState extends State<Day180Screen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FutureBuilder<Map<String, String>>(
      future: loadBibleJson(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: cs.primary,
                    strokeWidth: 4,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '성경 데이터 로딩 중...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: Text(
                '성경 데이터를 불러오지 못했습니다.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurface,
                ),
              ),
            ),
          );
        }
        final bibleData = snapshot.data!;
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('성경일독 DAY180'),
            backgroundColor: theme.appBarTheme.backgroundColor,
            elevation: theme.appBarTheme.elevation ?? 0,
            scrolledUnderElevation:
                theme.appBarTheme.scrolledUnderElevation ?? 0,
            centerTitle: theme.appBarTheme.centerTitle ?? true,
            iconTheme: theme.appBarTheme.iconTheme,
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Consumer<PlanProgressProvider>(
                builder: (context, planProvider, _) {
                  return ListView.separated(
                    itemCount: bible180.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: cs.outline.withOpacity(0.2),
                    ),
                    itemBuilder: (_, idx) {
                      final dayRanges = bible180[idx];
                      final dayNum = idx + 1;
                      final dayLabel = 'DAY $dayNum';
                      final rangeLabel = dayRanges.join(', ');

                      // 읽음 처리 및 접근 가능 여부 확인
                      final isCompleted = planProvider.isDayCompleted(dayNum);
                      final canAccess = planProvider.canAccessDay(dayNum);

                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 400 + (idx * 20)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: child,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          child: Opacity(
                            opacity: canAccess ? 1.0 : 0.4,
                            child: ListTile(
                              tileColor: cs.surface,
                              enabled: canAccess,
                              title: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isCompleted
                                            ? [
                                                Colors.green,
                                                Colors.green.withOpacity(0.7),
                                              ]
                                            : canAccess
                                                ? [
                                                    cs.primary,
                                                    cs.primary.withOpacity(0.7),
                                                  ]
                                                : [
                                                    Colors.grey,
                                                    Colors.grey.withOpacity(0.7),
                                                  ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: canAccess
                                          ? [
                                              BoxShadow(
                                                color: isCompleted
                                                    ? Colors.green.withOpacity(0.3)
                                                    : cs.primary.withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Text(
                                      dayLabel,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: cs.onPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      prettyRangeLabel(rangeLabel),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: 15,
                                        color: canAccess
                                            ? cs.onSurface
                                            : cs.onSurface.withOpacity(0.5),
                                      ),
                                      softWrap: true,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isCompleted)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                ],
                              ),
                              trailing: TweenAnimationBuilder<double>(
                                duration: Duration(milliseconds: 400 + (idx * 20)),
                                tween: Tween(begin: 0.0, end: 1.0),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value.clamp(0.0, 1.0),
                                    child: child,
                                  );
                                },
                                child: Icon(
                                  canAccess
                                      ? Icons.arrow_forward_ios_rounded
                                      : Icons.lock,
                                  size: 18,
                                  color: canAccess ? cs.primary : Colors.grey,
                                ),
                              ),
                              onTap: canAccess
                                  ? () {
                                      _openPlanVerse(context, bibleData, idx);
                                    }
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _openPlanVerse(
      BuildContext context, Map<String, String> bibleData, int idx) {
    final dayRanges = bible180[idx];
    final dayNum = idx + 1;
    final dayLabel = 'DAY $dayNum';
    final rangeLabel = dayRanges.join(', ');

    final entries = extractVersesForDay(bibleData, dayRanges);

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => PlanVerseListView(
          title: '$dayLabel  $rangeLabel',
          verses: Map<String, String>.fromEntries(entries),
          dayNumber: dayNum,
          onBack: () => Navigator.pop(context),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
