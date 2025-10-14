import 'package:flutter/material.dart';
import '../../models/bible_180.dart'; // bible180 import
import '../../models/bible_json_loader.dart';
import '../../utils/extract_verses.dart';
import '../../utils/pretty_range_label.dart';
import 'plan_verse_list_view.dart';

class Day180Screen extends StatelessWidget {
  const Day180Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // ✅ 테마 가져오기
    final cs = theme.colorScheme; // ✅ ColorScheme 가져오기

    return FutureBuilder<Map<String, String>>(
      future: loadBibleJson(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor, // ✅ 테마 적용
            body: Center(
              child: CircularProgressIndicator(
                color: cs.primary, // ✅ 테마 적용
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor, // ✅ 테마 적용
            body: Center(
              child: Text(
                '성경 데이터를 불러오지 못했습니다.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurface, // ✅ 테마 적용
                ),
              ),
            ),
          );
        }
        final bibleData = snapshot.data!;
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor, // ✅ 테마 적용
          appBar: AppBar(
            title: const Text('성경일독 DAY180'),
            backgroundColor: theme.appBarTheme.backgroundColor, // ✅ 테마 적용
            elevation: theme.appBarTheme.elevation ?? 0, // ✅ 테마 적용
            scrolledUnderElevation:
                theme.appBarTheme.scrolledUnderElevation ?? 0, // ✅ 테마 적용
            centerTitle: theme.appBarTheme.centerTitle ?? true, // ✅ 테마 적용
            iconTheme: theme.appBarTheme.iconTheme, // ✅ 테마 적용
          ),
          body: ListView.separated(
            itemCount: bible180.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 1,
              color: cs.outline.withOpacity(0.2), // ✅ 더 은은하게
            ),
            itemBuilder: (_, idx) {
              final dayRanges = bible180[idx];
              final dayNum = idx + 1;
              final dayLabel = 'DAY $dayNum';
              final rangeLabel = dayRanges.join(', ');

              return ListTile(
                tileColor: cs.surface, // ✅ 테마 적용
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayLabel,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        // ✅ 테마 적용
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.primary, // ✅ 테마 적용
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        prettyRangeLabel(rangeLabel),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          // ✅ 테마 적용
                          fontSize: 15,
                          color: cs.onSurface, // ✅ 테마 적용
                        ),
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: cs.primary, // ✅ 테마 적용
                ),
                onTap: () {
                  _openPlanVerse(context, bibleData, idx);
                },
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              );
            },
          ),
        );
      },
    );
  }

  // DAY180용 VerseView 오픈 함수 (이전/다음 DAY 연동)
  void _openPlanVerse(
      BuildContext context, Map<String, String> bibleData, int idx) {
    final dayRanges = bible180[idx];
    final dayNum = idx + 1;
    final dayLabel = 'DAY $dayNum';
    final rangeLabel = dayRanges.join(', ');

    final entries = extractVersesForDay(bibleData, dayRanges);

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => PlanVerseListView(
          title: '$dayLabel  $rangeLabel',
          verses: Map<String, String>.fromEntries(entries),
          onBack: () => Navigator.pop(context),

          // 이전/다음 DAY 지원
          hasPrevDay: idx > 0,
          hasNextDay: idx < bible180.length - 1,
          onPrevDay: idx > 0
              ? () {
                  Navigator.pop(context);
                  _openPlanVerse(context, bibleData, idx - 1);
                }
              : null,
          onNextDay: idx < bible180.length - 1
              ? () {
                  Navigator.pop(context);
                  _openPlanVerse(context, bibleData, idx + 1);
                }
              : null,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}
