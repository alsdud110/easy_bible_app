class Memo {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Memo({
    required this.id,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'createdAt': createdAt.millisecondsSinceEpoch, // ✅ 타임스탬프로 저장
        'updatedAt': updatedAt?.millisecondsSinceEpoch, // ✅ 타임스탬프로 저장
      };

  factory Memo.fromJson(Map<String, dynamic> json) {
    // ✅ int와 String 둘 다 처리
    DateTime parseDateTime(dynamic value) {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    return Memo(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: parseDateTime(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? parseDateTime(json['updatedAt']) : null,
    );
  }

  Memo copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Memo(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FavoriteVerse {
  final String bookName;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final String reference; // "창세기 1:3-7"
  final String text;
  final DateTime createdAt;
  final List<Memo> memos; // ✅ 메모 리스트로 변경

  FavoriteVerse({
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.reference,
    required this.text,
    required this.createdAt,
    List<Memo>? memos,
  }) : memos = memos ?? [];

  // JSON 변환
  Map<String, dynamic> toJson() => {
        'bookName': bookName,
        'chapter': chapter,
        'startVerse': startVerse,
        'endVerse': endVerse,
        'reference': reference,
        'text': text,
        'createdAt': createdAt.millisecondsSinceEpoch, // ✅ 타임스탬프로 저장
        'memos': memos.map((m) => m.toJson()).toList(),
      };

  factory FavoriteVerse.fromJson(Map<String, dynamic> json) {
    // ✅ int와 String 둘 다 처리
    DateTime parseDateTime(dynamic value) {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    return FavoriteVerse(
      bookName: json['bookName'] as String,
      chapter: json['chapter'] as int,
      startVerse: json['startVerse'] as int,
      endVerse: json['endVerse'] as int,
      reference: json['reference'] as String,
      text: json['text'] as String,
      createdAt: parseDateTime(json['createdAt']),
      memos: (json['memos'] as List<dynamic>?)
              ?.map((m) => Memo.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // 특정 절이 북마크 범위에 포함되는지 확인
  bool containsVerse(String bookName, int chapter, int verse) {
    return this.bookName == bookName &&
        this.chapter == chapter &&
        verse >= startVerse &&
        verse <= endVerse;
  }

  // 고유 키 생성 (중복 방지용)
  String get key => '${bookName}_${chapter}_${startVerse}_$endVerse';

  FavoriteVerse copyWith({
    String? bookName,
    int? chapter,
    int? startVerse,
    int? endVerse,
    String? reference,
    String? text,
    DateTime? createdAt,
    List<Memo>? memos,
  }) {
    return FavoriteVerse(
      bookName: bookName ?? this.bookName,
      chapter: chapter ?? this.chapter,
      startVerse: startVerse ?? this.startVerse,
      endVerse: endVerse ?? this.endVerse,
      reference: reference ?? this.reference,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      memos: memos ?? this.memos,
    );
  }
}
