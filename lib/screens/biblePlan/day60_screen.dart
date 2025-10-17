import 'package:flutter/material.dart';
import '../../models/bible_60.dart';
import '../../models/bible_json_loader.dart';
import '../../utils/extract_verses.dart';
import '../../utils/pretty_range_label.dart';
import 'plan_verse_list_view.dart';

class Day60Screen extends StatefulWidget {
  const Day60Screen({super.key});

  @override
  State<Day60Screen> createState() => _Day60ScreenState();
}

class _Day60ScreenState extends State<Day60Screen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
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
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1200),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.rotate(
                        angle: value * 6.28 * 2, // 2바퀴 회전
                        child: Transform.scale(
                          scale: 0.8 + (value * 0.2),
                          child: child,
                        ),
                      );
                    },
                    child: CircularProgressIndicator(
                      color: cs.primary,
                      strokeWidth: 4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: child,
                      );
                    },
                    child: Text(
                      '성경 데이터 로딩 중...',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
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
            title: const Text('성경일독 DAY60'),
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
              child: ListView.separated(
                itemCount: bible60.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 1,
                  color: cs.outline.withOpacity(0.2),
                ),
                itemBuilder: (_, idx) {
                  final dayRanges = bible60[idx];
                  final dayNum = idx + 1;
                  final dayLabel = 'DAY $dayNum';
                  final rangeLabel = dayRanges.join(', ');

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
                      child: ListTile(
                        tileColor: cs.surface,
                        title: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // DAY 라벨 애니메이션
                            TweenAnimationBuilder<double>(
                              duration:
                                  Duration(milliseconds: 600 + (idx * 30)),
                              tween: Tween(begin: 0.0, end: 1.0),
                              curve: Curves.easeOut,
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: 0.8 + (value * 0.2),
                                  child: Opacity(
                                    opacity: value.clamp(0.0, 1.0),
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      cs.primary,
                                      cs.primary.withOpacity(0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cs.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
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
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                prettyRangeLabel(rangeLabel),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 15,
                                  color: cs.onSurface,
                                ),
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        trailing: TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 600 + (idx * 30)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: child,
                            );
                          },
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 18,
                            color: cs.primary,
                          ),
                        ),
                        onTap: () {
                          _openPlanVerse(context, bibleData, idx);
                        },
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                    ),
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
    final dayRanges = bible60[idx];
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
          onBack: () => Navigator.pop(context),
          hasPrevDay: idx > 0,
          hasNextDay: idx < bible60.length - 1,
          onPrevDay: idx > 0
              ? () {
                  Navigator.pop(context);
                  _openPlanVerse(context, bibleData, idx - 1);
                }
              : null,
          onNextDay: idx < bible60.length - 1
              ? () {
                  Navigator.pop(context);
                  _openPlanVerse(context, bibleData, idx + 1);
                }
              : null,
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
