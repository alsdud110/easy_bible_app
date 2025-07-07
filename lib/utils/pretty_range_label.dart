import '../models/const/book_full_name.dart';

String prettyRangeLabel(String input) {
  input = input.replaceAll(RegExp(r'[\-–~]'), '~');
  input = input.replaceAll(' ', '');

  // 1. 두 책명 범위 ex: "시119~잠9장"
  final crossBook = RegExp(r'^([가-힣]+)(\d+)~([가-힣]+)(\d+)[장편]$');
  final crossBookMatch = crossBook.firstMatch(input);
  if (crossBookMatch != null) {
    final book1 = crossBookMatch.group(1)!;
    final ch1 = crossBookMatch.group(2)!;
    final book2 = crossBookMatch.group(3)!;
    final ch2 = crossBookMatch.group(4)!;
    // '시'면 '편', 아니면 '장'
    final suffix1 = (book1 == '시') ? '편' : '장';
    final suffix2 = (book2 == '시') ? '편' : '장';
    final fullBook1 = bookFullName[book1] ?? book1;
    final fullBook2 = bookFullName[book2] ?? book2;
    return '$fullBook1 $ch1$suffix1 ~ $fullBook2 $ch2$suffix2';
  }

  // 2. 같은 책에서 "시119~150편" → "시편 119~150편", "창1~23장" → "창세기 1~23장"
  final regSameBook = RegExp(r'^([가-힣]+)(\d+)~(\d+)[장편]$');
  final matchSameBook = regSameBook.firstMatch(input);
  if (matchSameBook != null) {
    final book = matchSameBook.group(1)!;
    final startCh = matchSameBook.group(2)!;
    final endCh = matchSameBook.group(3)!;
    final suffix = (book == '시') ? '편' : '장';
    final fullBook = bookFullName[book] ?? book;
    return '$fullBook $startCh~$endCh$suffix';
  }

  // 3. "시119장~150장" → "시편 119~150편", "창24장~40장" → "창세기 24~40장"
  final regChToCh = RegExp(r'^([가-힣]+)(\d+)장~(\d+)장$');
  final matchChToCh = regChToCh.firstMatch(input);
  if (matchChToCh != null) {
    final book = matchChToCh.group(1)!;
    final startCh = matchChToCh.group(2)!;
    final endCh = matchChToCh.group(3)!;
    final suffix = (book == '시') ? '편' : '장';
    final fullBook = bookFullName[book] ?? book;
    return '$fullBook $startCh~$endCh$suffix';
  }

  // 4. 단일 장 "시119장" → "시편 119편", "창24장" → "창세기 24장"
  final regCh = RegExp(r'^([가-힣]+)(\d+)장$');
  final matchCh = regCh.firstMatch(input);
  if (matchCh != null) {
    final book = matchCh.group(1)!;
    final ch = matchCh.group(2)!;
    final suffix = (book == '시') ? '편' : '장';
    final fullBook = bookFullName[book] ?? book;
    return '$fullBook $ch$suffix';
  }

  // 5. 장:절 "창24:5" → "창세기 24장 5절"
  final regVerse = RegExp(r'^([가-힣]+)(\d+):(\d+)$');
  final matchVerse = regVerse.firstMatch(input);
  if (matchVerse != null) {
    final book = matchVerse.group(1)!;
    final ch = matchVerse.group(2)!;
    final verse = matchVerse.group(3)!;
    final fullBook = bookFullName[book] ?? book;
    return '$fullBook $ch장 $verse절';
  }

  // 여러개 쉼표로 분리
  if (input.contains(',')) {
    return input.split(',').map((part) => prettyRangeLabel(part)).join(', ');
  }

  return input;
}

// 여러 범위 콤마(,) 분리, 각 범위별 prettyRangeLabel 적용
String fullNameRangeLabel(String input) {
  final parts = input.split(',').map((s) => s.trim()).toList();
  return parts.map((part) => prettyRangeLabel(part)).join(', ');
}
