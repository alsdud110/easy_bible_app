import 'dart:convert';
import 'dart:io';

import 'package:easy_bible_app/models/bible_120.dart';
import 'package:easy_bible_app/models/bible_180.dart';
import 'package:easy_bible_app/models/bible_365.dart';
import 'package:easy_bible_app/models/bible_60.dart';
import 'package:easy_bible_app/models/plan_progress.dart';
import 'package:easy_bible_app/utils/extract_verses.dart';
import 'package:flutter_test/flutter_test.dart';

/// 성경일독 플랜이 날 수를 지키고 성경 전체를 빠짐없이 읽게 하는지 확인
void main() {
  final bible = (json.decode(File('assets/bible.json').readAsStringSync())
          as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v as String));

  final plans = {
    PlanType.day60: bible60,
    PlanType.day120: bible120,
    PlanType.day180: bible180,
    PlanType.day365: bible365,
  };

  for (final MapEntry(key: type, value: days) in plans.entries) {
    test('${type.totalDays}일 플랜', () {
      expect(days.length, type.totalDays);
      final read = <String>{};
      final emptyDays = <int>[];
      for (var i = 0; i < days.length; i++) {
        final entries = extractVersesForDay(bible, days[i]);
        if (entries.isEmpty) emptyDays.add(i + 1);
        // 범위 조각 하나라도 비면 오타(예: 없는 책 약어)
        for (final range in days[i]) {
          expect(extractVersesForDay(bible, [range]), isNotEmpty,
              reason: '${i + 1}일차 "$range"');
        }
        read.addAll(entries.map((e) => e.key));
      }
      expect(emptyDays, isEmpty);
      if (type == PlanType.day60) {
        // 60일은 장 단위로만 나뉘므로 같은 절이 이틀에 나오면 장 겹침
        final seen = <String>{};
        final dup = <String>[];
        for (var i = 0; i < days.length; i++) {
          for (final e in extractVersesForDay(bible, days[i])) {
            if (!seen.add(e.key)) dup.add('${i + 1}일차 ${e.key}');
          }
        }
        expect(dup, isEmpty, reason: dup.take(5).join(', '));
      }
      final missing = bible.keys.where((k) => !read.contains(k)).toList();
      expect(missing, isEmpty, reason: '빠진 절 ${missing.length}개: ${missing.take(10)}');
    });
  }
}
