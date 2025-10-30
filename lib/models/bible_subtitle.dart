class BibleSubtitle {
  final String book;
  final String bookCode;
  final int chapter;
  final int verse;
  final String subtitle;

  BibleSubtitle({
    required this.book,
    required this.bookCode,
    required this.chapter,
    required this.verse,
    required this.subtitle,
  });

  factory BibleSubtitle.fromJson(Map<String, dynamic> json) {
    return BibleSubtitle(
      book: json['book'] as String,
      bookCode: json['bookCode'] as String,
      chapter: int.parse(json['chapter'].toString()),
      verse: int.parse(json['verse'].toString()),
      subtitle: json['subtitle'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'bookCode': bookCode,
      'chapter': chapter.toString(),
      'verse': verse.toString(),
      'subtitle': subtitle,
    };
  }
}
