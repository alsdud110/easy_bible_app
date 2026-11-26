import 'dart:convert';
import 'dart:io';

import 'package:easy_bible_app/models/bible_data.dart';
import 'package:easy_bible_app/utils/bible_key_converter.dart';
import 'package:flutter_test/flutter_test.dart';

/// 66권 모든 장이 번역본마다 절을 갖고 있는지 확인 (절 목록이 비는 버그 방지)
void main() {
  Map<String, dynamic> load(String path) =>
      json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;

  final bibles = {
    '개역개정': load('assets/bible.json'),
    '표준새번역': load('assets/bible_snb.json'),
    'KJV': load('assets/bible_kjv.json'),
  };

  int count(Map<String, dynamic> bible, String prefix) =>
      bible.keys.where((k) => k.startsWith(prefix)).length;

  test('모든 책·장에 절이 있다', () {
    final missing = <String>[];
    for (final book in bibleBooks) {
      for (var ch = 1; ch <= book.chapters; ch++) {
        for (final e in bibles.entries) {
          final name = e.key == 'KJV'
              ? BookNameConverter.koreanToEnglish(book.name)
              : book.name;
          if (count(e.value, '$name$ch:') == 0) {
            missing.add('${e.key} ${book.fullName} $ch장');
          }
        }
      }
    }
    expect(missing, isEmpty);
  });

  test('소제목 데이터의 책 이름이 앱 책 이름과 일치', () {
    final names = bibleBooks.map((b) => b.fullName).toSet();
    for (final path in [
      'assets/bible_subtitles.json',
      'assets/bible_subtitles_snb.json',
    ]) {
      final list = json.decode(File(path).readAsStringSync()) as List;
      final unknown =
          list.map((e) => e['book'] as String).toSet().difference(names);
      expect(unknown, isEmpty, reason: path);
    }
  });

  test('번역본 사이 장별 절 수 차이', () {
    final diffs = <String>[];
    for (final book in bibleBooks) {
      final eng = BookNameConverter.koreanToEnglish(book.name);
      for (var ch = 1; ch <= book.chapters; ch++) {
        final ko = count(bibles['개역개정']!, '${book.name}$ch:');
        final snb = count(bibles['표준새번역']!, '${book.name}$ch:');
        final kjv = count(bibles['KJV']!, '$eng$ch:');
        if (ko != snb || ko != kjv) {
          diffs.add('${book.fullName} $ch장: 개역 $ko / 표준 $snb / KJV $kjv');
        }
      }
    }
    // 번역본마다 절 구분이 다를 수 있어 실패로 보지 않고 기록만 함
    printOnFailure(diffs.join('\n'));
    // ignore: avoid_print
    print('절 수가 다른 장 ${diffs.length}개\n${diffs.join('\n')}');
  });
}
