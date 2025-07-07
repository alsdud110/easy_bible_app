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
    if (match == null) return 9999999;
    final book = match.group(1)!;
    final chapter = int.parse(match.group(2)!);
    final verse = int.parse(match.group(3)!);
    final bookIdx = books.indexOf(book);
    return bookIdx * 1000000 + chapter * 1000 + verse;
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

    // inRange 시작
    if (!inRange && book == startBook && ch == startCh) inRange = true;

    if (inRange) result[k] = bibleData[k]!;

    // 끝점이면 그 장의 마지막 절까지 다 넣고, 끝냄!
    if (inRange && book == endBook && ch == endCh) {
      // 다음 장 나오면 break
      continue;
    }
    if (inRange && book == endBook && ch > endCh) break;
    if (inRange && books.indexOf(book) > books.indexOf(endBook)) break;
  }

  // 디버깅: 추출된 결과 직접 확인
  print('======== EXTRACT DEBUG START ========');
  for (var k in result.keys) {
    print('$k → ${result[k]}');
  }
  print('======== EXTRACT DEBUG END ========');

  return result;
}
