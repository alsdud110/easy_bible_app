class FavoriteVerse {
  final String bookName;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final String reference; // "창세기 1:3-7"
  final String text;
  final DateTime createdAt;

  FavoriteVerse({
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.reference,
    required this.text,
    required this.createdAt,
  });

  // JSON 변환
  Map<String, dynamic> toJson() => {
        'bookName': bookName,
        'chapter': chapter,
        'startVerse': startVerse,
        'endVerse': endVerse,
        'reference': reference,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FavoriteVerse.fromJson(Map<String, dynamic> json) => FavoriteVerse(
        bookName: json['bookName'],
        chapter: json['chapter'],
        startVerse: json['startVerse'],
        endVerse: json['endVerse'],
        reference: json['reference'],
        text: json['text'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  // 특정 절이 즐겨찾기 범위에 포함되는지 확인
  bool containsVerse(String bookName, int chapter, int verse) {
    return this.bookName == bookName &&
        this.chapter == chapter &&
        verse >= startVerse &&
        verse <= endVerse;
  }

  // 고유 키 생성 (중복 방지용)
  String get key => '${bookName}_${chapter}_${startVerse}_$endVerse';
}
