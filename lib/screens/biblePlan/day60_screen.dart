import 'package:flutter/material.dart';
import '../../models/bible_60.dart';
import '../../models/bible_json_loader.dart';
import '../../utils/extract_verses.dart';
import '../../models/const//book_full_name.dart';
import 'plan_verse_list_view.dart';

String prettyRange(String start, String end) {
  final startMatch = RegExp(r'^([가-힣]+)\s*(\d+)$').firstMatch(start);
  final endMatch = RegExp(r'^([가-힣]+)\s*(\d+)$').firstMatch(end);

  if (startMatch == null || endMatch == null) return '$start ~ $end';

  final startBook = startMatch.group(1)!;
  final startCh = startMatch.group(2)!;
  final endBook = endMatch.group(1)!;
  final endCh = endMatch.group(2)!;

  final startFull = bookFullName[startBook] ?? startBook;
  final endFull = bookFullName[endBook] ?? endBook;

  if (startBook == endBook) {
    return '$startFull $startCh장 ~ $endCh장';
  }
  return '$startFull $startCh장 ~ $endFull $endCh장';
}

class Day60Screen extends StatelessWidget {
  const Day60Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: loadBibleJson(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('성경 데이터를 불러오지 못했습니다.')),
          );
        }
        final bibleData = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: const Text('성경일독 DAY60')),
          body: ListView.separated(
            itemCount: bible60.length,
            separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1),
            itemBuilder: (_, idx) {
              final day = bible60[idx];
              final dayNum = idx + 1;
              final start = day['start']!;
              final end = day['end']!;
              final dayLabel = 'DAY$dayNum';
              final rangeLabel = prettyRange(start, end);
              return ListTile(
                title: Text('$dayLabel  $rangeLabel'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                onTap: () {
                  final startMatch =
                      RegExp(r'^([가-힣]+)\s*(\d+)$').firstMatch(start);
                  final endMatch =
                      RegExp(r'^([가-힣]+)\s*(\d+)$').firstMatch(end);
                  if (startMatch == null || endMatch == null) return;
                  final startBook = startMatch.group(1)!;
                  final startCh = int.parse(startMatch.group(2)!);
                  final endBook = endMatch.group(1)!;
                  final endCh = int.parse(endMatch.group(2)!);

                  final verses = extractVersesInRange(
                    bibleData,
                    startBook,
                    startCh,
                    endBook,
                    endCh,
                  );

                  Navigator.of(context).push(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 200),
                      pageBuilder: (_, __, ___) => PlanVerseListView(
                        title: '$dayLabel  $rangeLabel',
                        verses: verses,
                        onBack: () => Navigator.pop(context),
                      ),
                      transitionsBuilder: (_, animation, __, child) =>
                          FadeTransition(opacity: animation, child: child),
                    ),
                  );
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
}
