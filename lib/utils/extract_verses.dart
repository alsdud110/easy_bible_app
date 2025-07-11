// extract_verses.dart

// DAY60 전용 (절대 수정하지 마!)
Map<String, String> extractVersesInRange(
  Map<String, String> bibleData,
  String startBook,
  int startCh,
  String endBook,
  int endCh,
) {
  final books = [
    "창",
    "출",
    "레",
    "민",
    "신",
    "수",
    "삿",
    "룻",
    "삼상",
    "삼하",
    "왕상",
    "왕하",
    "대상",
    "대하",
    "스",
    "느",
    "에",
    "욥",
    "시",
    "잠",
    "전",
    "아",
    "사",
    "렘",
    "애",
    "겔",
    "단",
    "호",
    "욜",
    "암",
    "옵",
    "욘",
    "미",
    "나",
    "합",
    "습",
    "학",
    "슥",
    "말",
    "마",
    "막",
    "눅",
    "요",
    "행",
    "롬",
    "고전",
    "고후",
    "갈",
    "엡",
    "빌",
    "골",
    "살전",
    "살후",
    "딤전",
    "딤후",
    "딛",
    "몬",
    "히",
    "약",
    "벧전",
    "벧후",
    "요일",
    "요이",
    "요삼",
    "유",
    "계"
  ];

  int keyToOrder(String key) {
    final match = RegExp(r'^([가-힣]+)(\d+):(\d+)$').firstMatch(key);
    if (match == null) return 999999999;
    final book = match.group(1)!;
    final chapter = int.parse(match.group(2)!);
    final verse = int.parse(match.group(3)!);
    final bookIdx = books.indexOf(book);
    return bookIdx * 1000000 + chapter * 1000 + verse;
  }

  int maxVerse = 0;
  for (final k in bibleData.keys) {
    final m = RegExp(r'^([가-힣]+)(\d+):(\d+)$').firstMatch(k);
    if (m == null) continue;
    final book = m.group(1)!;
    final ch = int.parse(m.group(2)!);
    final verse = int.parse(m.group(3)!);
    if (book == endBook && ch == endCh && verse > maxVerse) {
      maxVerse = verse;
    }
  }

  final sortedKeys = bibleData.keys.toList()
    ..sort((a, b) => keyToOrder(a).compareTo(keyToOrder(b)));

  bool inRange = false;
  final result = <String, String>{};
  for (final k in sortedKeys) {
    final m = RegExp(r'^([가-힣]+)(\d+):(\d+)$').firstMatch(k);
    if (m == null) continue;
    final book = m.group(1)!;
    final ch = int.parse(m.group(2)!);
    final verse = int.parse(m.group(3)!);

    if (!inRange && book == startBook && ch == startCh) inRange = true;
    if (inRange) result[k] = bibleData[k]!;
    if (book == endBook && ch == endCh && verse == maxVerse) break;
  }
  return result;
}

// 범위 여러 개/복잡 구간에서 순서 보장
List<MapEntry<String, String>> extractVersesForDay(
  Map<String, String> bibleData,
  List<String> ranges,
) {
  final books = [
    "창",
    "출",
    "레",
    "민",
    "신",
    "수",
    "삿",
    "룻",
    "삼상",
    "삼하",
    "왕상",
    "왕하",
    "대상",
    "대하",
    "스",
    "느",
    "에",
    "욥",
    "시",
    "잠",
    "전",
    "아",
    "사",
    "렘",
    "애",
    "겔",
    "단",
    "호",
    "욜",
    "암",
    "옵",
    "욘",
    "미",
    "나",
    "합",
    "습",
    "학",
    "슥",
    "말",
    "마",
    "막",
    "눅",
    "요",
    "행",
    "롬",
    "고전",
    "고후",
    "갈",
    "엡",
    "빌",
    "골",
    "살전",
    "살후",
    "딤전",
    "딤후",
    "딛",
    "몬",
    "히",
    "약",
    "벧전",
    "벧후",
    "요일",
    "요이",
    "요삼",
    "유",
    "계"
  ];
  final result = <MapEntry<String, String>>[];
  for (final range in ranges) {
    final entries = _extractSingleRangeEntries(bibleData, range);
    result.addAll(entries);
  }
  // ★ 여기가 핵심: 반드시 "책-장-절" 기준으로 오름차순 정렬!
  // result.sort((a, b) {
  //   getOrder(String key) {
  //     final m = RegExp(r'^([가-힣]+)(\d+):(\d+)$').firstMatch(key);
  //     if (m == null) return 999999999;
  //     final book = m.group(1)!;
  //     final chapter = int.parse(m.group(2)!);
  //     final verse = int.parse(m.group(3)!);
  //     final bookIdx = books.indexOf(book);
  //     return bookIdx * 1000000 + chapter * 1000 + verse;
  //   }

  //   return getOrder(a.key).compareTo(getOrder(b.key));
  // });
  return result;
}

List<MapEntry<String, String>> _extractSingleRangeEntries(
  Map<String, String> bibleData,
  String range,
) {
  final result = <MapEntry<String, String>>[];

  String clean =
      range.replaceAll(' ', '').replaceAll('–', '~').replaceAll('-', '~');

  final mFix = RegExp(r'^([가-힣]+)(\d+):(\d+)~(\d+)$').firstMatch(clean);
  if (mFix != null) {
    clean =
        '${mFix.group(1)}${mFix.group(2)}:${mFix.group(3)}~${mFix.group(2)}:${mFix.group(4)}';
  }

  // cross-book: ex) 삼상18~삼하3장
  final crossBookMatch =
      RegExp(r'^([가-힣]+)(\d+)~([가-힣]+)(\d+)[장편]$').firstMatch(clean);
  if (crossBookMatch != null) {
    final books = [
      "창",
      "출",
      "레",
      "민",
      "신",
      "수",
      "삿",
      "룻",
      "삼상",
      "삼하",
      "왕상",
      "왕하",
      "대상",
      "대하",
      "스",
      "느",
      "에",
      "욥",
      "시",
      "잠",
      "전",
      "아",
      "사",
      "렘",
      "애",
      "겔",
      "단",
      "호",
      "욜",
      "암",
      "옵",
      "욘",
      "미",
      "나",
      "합",
      "습",
      "학",
      "슥",
      "말",
      "마",
      "막",
      "눅",
      "요",
      "행",
      "롬",
      "고전",
      "고후",
      "갈",
      "엡",
      "빌",
      "골",
      "살전",
      "살후",
      "딤전",
      "딤후",
      "딛",
      "몬",
      "히",
      "약",
      "벧전",
      "벧후",
      "요일",
      "요이",
      "요삼",
      "유",
      "계"
    ];
    final startBook = crossBookMatch.group(1)!;
    final startCh = int.parse(crossBookMatch.group(2)!);
    final endBook = crossBookMatch.group(3)!;
    final endCh = int.parse(crossBookMatch.group(4)!);

    final startIdx = books.indexOf(startBook);
    final endIdx = books.indexOf(endBook);

    // (1) 시작책: startCh~존재하는 마지막장까지
    int ch = startCh;
    while (true) {
      bool found = false;
      for (final e in bibleData.entries) {
        if (e.key.startsWith('$startBook$ch:')) {
          found = true;
          result.add(e);
        }
      }
      if (!found) break;
      ch++;
    }

    // (2) 중간책: 모두
    for (int i = startIdx + 1; i < endIdx; i++) {
      final midBook = books[i];
      final chapters = bibleData.keys
          .where((k) => k.startsWith(midBook))
          .map((k) =>
              int.parse(RegExp(r'^[가-힣]+(\d+):').firstMatch(k)!.group(1)!))
          .toSet();
      for (final midCh in chapters) {
        _addChapterVersesEntries(bibleData, midBook, midCh, result);
      }
    }

    // (3) 마지막책: 1~endCh까지
    for (int ch = 1; ch <= endCh; ch++) {
      _addChapterVersesEntries(bibleData, endBook, ch, result);
    }

    // ★ 정렬은 extractVersesForDay에서 해줌
    return result;
  }

  // 책, 범위 분리 (아래부터는 기존 파싱)
  final bookChapterRegex = RegExp(r'^([가-힣]+)(.*)$');
  final match = bookChapterRegex.firstMatch(clean);
  if (match == null) return result;

  final book = match.group(1)!;
  final chaptersStr = match.group(2)!.replaceAll('편', '').replaceAll('장', '');

  // [1] 장:절 ~ 장:절 (ex: 11:3~20:13)
  final fullMatch =
      RegExp(r'^(\d+):(\d+)~(\d+):(\d+)$').firstMatch(chaptersStr);
  if (fullMatch != null) {
    final startCh = int.parse(fullMatch.group(1)!);
    final startVerse = int.parse(fullMatch.group(2)!);
    final endCh = int.parse(fullMatch.group(3)!);
    final endVerse = int.parse(fullMatch.group(4)!);

    if (startCh == endCh) {
      // 같은 장
      final verses = bibleData.entries
          .where((e) =>
              e.key.startsWith('$book$startCh:') &&
              int.parse(e.key.split(':')[1]) >= startVerse &&
              int.parse(e.key.split(':')[1]) <= endVerse)
          .toList();
      verses.sort((a, b) => int.parse(a.key.split(':')[1])
          .compareTo(int.parse(b.key.split(':')[1])));
      result.addAll(verses);
    } else {
      // 시작 장: startVerse~끝까지
      final firstVerses = bibleData.entries
          .where((e) =>
              e.key.startsWith('$book$startCh:') &&
              int.parse(e.key.split(':')[1]) >= startVerse)
          .toList();
      firstVerses.sort((a, b) => int.parse(a.key.split(':')[1])
          .compareTo(int.parse(b.key.split(':')[1])));
      result.addAll(firstVerses);

      // 중간 장 전체
      for (int ch = startCh + 1; ch < endCh; ch++) {
        _addChapterVersesEntries(bibleData, book, ch, result);
      }

      // 마지막 장: 1~endVerse
      final lastVerses = bibleData.entries
          .where((e) =>
              e.key.startsWith('$book$endCh:') &&
              int.parse(e.key.split(':')[1]) <= endVerse)
          .toList();
      lastVerses.sort((a, b) => int.parse(a.key.split(':')[1])
          .compareTo(int.parse(b.key.split(':')[1])));
      result.addAll(lastVerses);
    }
    return result;
  }

  // [2] 장 ~ 장:절  ex) 11~20:13
  final startToEndVerse =
      RegExp(r'^(\d+)~(\d+):(\d+)$').firstMatch(chaptersStr);
  if (startToEndVerse != null) {
    final startCh = int.parse(startToEndVerse.group(1)!);
    final endCh = int.parse(startToEndVerse.group(2)!);
    final endVerse = int.parse(startToEndVerse.group(3)!);

    // 시작 장 전체
    _addChapterVersesEntries(bibleData, book, startCh, result);

    // 중간 장 전체
    for (int ch = startCh + 1; ch < endCh; ch++) {
      _addChapterVersesEntries(bibleData, book, ch, result);
    }

    // 마지막 장 1~endVerse
    final lastVerses = bibleData.entries
        .where((e) =>
            e.key.startsWith('$book$endCh:') &&
            int.parse(e.key.split(':')[1]) <= endVerse)
        .toList();
    lastVerses.sort((a, b) => int.parse(a.key.split(':')[1])
        .compareTo(int.parse(b.key.split(':')[1])));
    result.addAll(lastVerses);
    return result;
  }

  // [3] 장:절 ~ 장   ex) 20:14~28
  final startVerseToEndCh =
      RegExp(r'^(\d+):(\d+)~(\d+)$').firstMatch(chaptersStr);
  if (startVerseToEndCh != null) {
    final startCh = int.parse(startVerseToEndCh.group(1)!);
    final startVerse = int.parse(startVerseToEndCh.group(2)!);
    final endCh = int.parse(startVerseToEndCh.group(3)!);

    // 시작 장: startVerse~끝
    final firstVerses = bibleData.entries
        .where((e) =>
            e.key.startsWith('$book$startCh:') &&
            int.parse(e.key.split(':')[1]) >= startVerse)
        .toList();
    firstVerses.sort((a, b) => int.parse(a.key.split(':')[1])
        .compareTo(int.parse(b.key.split(':')[1])));
    result.addAll(firstVerses);

    // 다음장~endCh 전체
    for (int ch = startCh + 1; ch <= endCh; ch++) {
      _addChapterVersesEntries(bibleData, book, ch, result);
    }
    return result;
  }

  // [4] 장 ~ 장 (ex: 11~20)
  final matchChRange = RegExp(r'^(\d+)~(\d+)$').firstMatch(chaptersStr);
  if (matchChRange != null) {
    final startCh = int.parse(matchChRange.group(1)!);
    final endCh = int.parse(matchChRange.group(2)!);
    for (int ch = startCh; ch <= endCh; ch++) {
      _addChapterVersesEntries(bibleData, book, ch, result);
    }
    return result;
  }

  // [5] 쉼표 분할, 단일 장, 장:절
  for (final part in chaptersStr.split(',')) {
    if (part.isEmpty) continue;

    // 장:절
    final subMatch = RegExp(r'^(\d+):(\d+)$').firstMatch(part);
    if (subMatch != null) {
      final ch = int.parse(subMatch.group(1)!);
      final verse = int.parse(subMatch.group(2)!);
      _addChapterVersesEntries(bibleData, book, ch, result, lastVerse: verse);
      continue;
    }

    // 장~장
    if (part.contains('~')) {
      final bounds = part.split('~');
      final startCh = int.tryParse(bounds[0]);
      final endCh = int.tryParse(bounds[1]);
      if (startCh != null && endCh != null) {
        for (int ch = startCh; ch <= endCh; ch++) {
          _addChapterVersesEntries(bibleData, book, ch, result);
        }
      }
      continue;
    }

    // 장
    final ch = int.tryParse(part);
    if (ch != null) {
      _addChapterVersesEntries(bibleData, book, ch, result);
      continue;
    }
  }

  return result;
}

// 마지막절만 가져오고 싶을 땐 lastVerse 인자 사용
void _addChapterVersesEntries(
  Map<String, String> bibleData,
  String book,
  int ch,
  List<MapEntry<String, String>> result, {
  int? lastVerse,
}) {
  final regex = RegExp('^$book$ch:(\\d+)\$');
  final chapterVerses =
      bibleData.entries.where((e) => regex.hasMatch(e.key)).toList();

  // 무조건 int로 정렬!
  chapterVerses.sort((a, b) {
    final aVerse = int.parse(a.key.split(':').last);
    final bVerse = int.parse(b.key.split(':').last);
    return aVerse.compareTo(bVerse);
  });

  if (lastVerse != null) {
    result.addAll(
      chapterVerses.where(
        (e) => int.parse(e.key.split(':').last) <= lastVerse,
      ),
    );
  } else {
    result.addAll(chapterVerses);
  }
}
