import '../models/bible_data.dart';

/// 한글 약칭 → 영어 약칭 매핑
const Map<String, String> koreanToEnglishBookMap = {
  // 구약
  '창': 'Gen',
  '출': 'Exo',
  '레': 'Lev',
  '민': 'Num',
  '신': 'Deu',
  '수': 'Jos',
  '삿': 'Jdg',
  '룻': 'Rut',
  '삼상': '1Sa',
  '삼하': '2Sa',
  '왕상': '1Ki',
  '왕하': '2Ki',
  '대상': '1Ch',
  '대하': '2Ch',
  '스': 'Ezr',
  '느': 'Neh',
  '에': 'Est',
  '욥': 'Job',
  '시': 'Psa',
  '잠': 'Pro',
  '전': 'Ecc',
  '아': 'Sng',
  '사': 'Isa',
  '렘': 'Jer',
  '애': 'Lam',
  '겔': 'Eze',
  '단': 'Dan',
  '호': 'Hos',
  '욜': 'Joe',
  '암': 'Amo',
  '옵': 'Oba',
  '욘': 'Jon',
  '미': 'Mic',
  '나': 'Nah',
  '합': 'Hab',
  '습': 'Zep',
  '학': 'Hag',
  '슥': 'Zec',
  '말': 'Mal',

  // 신약
  '마': 'Mat',
  '막': 'Mar',
  '눅': 'Luk',
  '요': 'Jhn',
  '행': 'Act',
  '롬': 'Rom',
  '고전': '1Co',
  '고후': '2Co',
  '갈': 'Gal',
  '엡': 'Eph',
  '빌': 'Phi',
  '골': 'Col',
  '살전': '1Th',
  '살후': '2Th',
  '딤전': '1Ti',
  '딤후': '2Ti',
  '딛': 'Tit',
  '몬': 'Phm',
  '히': 'Heb',
  '약': 'Jam',
  '벧전': '1Pe',
  '벧후': '2Pe',
  '요일': '1Jn',
  '요이': '2Jn',
  '요삼': '3Jn',
  '유': 'Jud',
  '계': 'Rev',
};

/// 영어 약칭 → 한글 약칭 매핑 (역매핑)
final Map<String, String> englishToKoreanBookMap = {
  for (var entry in koreanToEnglishBookMap.entries) entry.value: entry.key
};

/// 책 이름 변환 유틸리티
class BookNameConverter {
  /// 한글 약칭 → 영어 약칭
  static String koreanToEnglish(String koreanName) {
    return koreanToEnglishBookMap[koreanName] ?? koreanName;
  }

  /// 영어 약칭 → 한글 약칭
  static String englishToKorean(String englishName) {
    return englishToKoreanBookMap[englishName] ?? englishName;
  }

  /// BibleData 객체로부터 영어 약칭 가져오기
  static String getEnglishName(BibleData book) {
    return koreanToEnglishBookMap[book.name] ?? book.eng.substring(0, 3);
  }

  /// BibleData 리스트에서 한글 약칭으로 검색
  static BibleData? findByKoreanName(String koreanName) {
    try {
      return bibleBooks.firstWhere((book) => book.name == koreanName);
    } catch (e) {
      return null;
    }
  }

  /// BibleData 리스트에서 영어 약칭으로 검색
  static BibleData? findByEnglishName(String englishName) {
    final koreanName = englishToKorean(englishName);
    return findByKoreanName(koreanName);
  }
}

/// 성경 구절 키 변환 유틸리티
class VerseKeyConverter {
  /// 한글 키 → 영어 키 변환
  /// 예: "창1:1" → "Gen1:1"
  static String koreanToEnglish(String koreanKey) {
    final regex = RegExp(r'^([가-힣]+)(\d+):(\d+)$');
    final match = regex.firstMatch(koreanKey);

    if (match == null) return koreanKey;

    final bookName = match.group(1)!;
    final chapter = match.group(2)!;
    final verse = match.group(3)!;

    final englishBook = BookNameConverter.koreanToEnglish(bookName);
    return '$englishBook$chapter:$verse';
  }

  /// 영어 키 → 한글 키 변환
  /// 예: "Gen1:1" → "창1:1"
  static String englishToKorean(String englishKey) {
    final regex = RegExp(r'^([A-Za-z0-9]+)(\d+):(\d+)$');
    final match = regex.firstMatch(englishKey);

    if (match == null) return englishKey;

    final bookName = match.group(1)!;
    final chapter = match.group(2)!;
    final verse = match.group(3)!;

    final koreanBook = BookNameConverter.englishToKorean(bookName);
    return '$koreanBook$chapter:$verse';
  }

  /// 키를 파싱하여 책 이름, 장, 절 추출
  /// 반환: (bookName, chapter, verse)
  static (String, int, int)? parseKey(String key) {
    final koreanRegex = RegExp(r'^([가-힣]+)(\d+):(\d+)$');
    final englishRegex = RegExp(r'^([A-Za-z0-9]+)(\d+):(\d+)$');

    var match = koreanRegex.firstMatch(key);
    match ??= englishRegex.firstMatch(key);

    if (match == null) return null;

    final bookName = match.group(1)!;
    final chapter = int.tryParse(match.group(2)!) ?? 0;
    final verse = int.tryParse(match.group(3)!) ?? 0;

    return (bookName, chapter, verse);
  }
}
