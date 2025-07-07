import 'package:flutter/material.dart';
import '../../models/bible_120.dart';
import '../../models/bible_json_loader.dart';
import '../../utils/extract_verses.dart';
import '../../utils/pretty_range_label.dart';

import 'plan_verse_list_view.dart';

class Day120Screen extends StatelessWidget {
  const Day120Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: loadBibleJson(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: Text('성경 데이터를 불러오지 못했습니다.')));
        }
        final bibleData = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: const Text('성경일독 DAY120')),
          body: ListView.separated(
            itemCount: bible120.length,
            separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1),
            itemBuilder: (_, idx) {
              final dayRanges = bible120[idx];
              final dayNum = idx + 1;
              final dayLabel = 'DAY $dayNum';
              final rangeLabel = dayRanges.join(', ');
              print(rangeLabel);

              return ListTile(
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        prettyRangeLabel(rangeLabel),
                        style: const TextStyle(fontSize: 15),
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                onTap: () {
                  final entries = extractVersesForDay(bibleData, dayRanges);
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 300),
                      pageBuilder: (_, __, ___) => PlanVerseListView(
                        title: '$dayLabel  $rangeLabel',
                        verses: Map<String, String>.fromEntries(entries),
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
