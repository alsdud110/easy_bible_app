import 'package:flutter/material.dart';

class HighlightVerse {
  final String bookName;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final HighlightColor color;
  final DateTime createdAt;

  HighlightVerse({
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.color,
    required this.createdAt,
  });

  String get key => '$bookName-$chapter-$startVerse-$endVerse';

  Map<String, dynamic> toJson() => {
        'bookName': bookName,
        'chapter': chapter,
        'startVerse': startVerse,
        'endVerse': endVerse,
        'color': color.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HighlightVerse.fromJson(Map<String, dynamic> json) {
    return HighlightVerse(
      bookName: json['bookName'] as String,
      chapter: json['chapter'] as int,
      startVerse: json['startVerse'] as int,
      endVerse: json['endVerse'] as int,
      color: HighlightColor.values.firstWhere(
        (c) => c.name == json['color'],
        orElse: () => HighlightColor.yellow,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool containsVerse(String book, int chap, int verse) {
    return bookName == book &&
        chapter == chap &&
        verse >= startVerse &&
        verse <= endVerse;
  }
}

enum HighlightColor {
  red,
  orange,
  yellow,
  green,
  blue,
  indigo,
  purple,
  clear, // 초기화용
}

// 형광펜 색: 종이 위 색연필처럼 채도를 낮춘 따뜻한 톤.
// 저장값은 enum 이름(red, blue...)이라 이름은 유지하고 색만 바꾼다.
// blue/indigo/purple 칸은 앱 팔레트에 맞춰 청록·흙·장밋빛으로 옮겼다.
extension HighlightColorExtension on HighlightColor {
  Color get color {
    switch (this) {
      case HighlightColor.red:
        return const Color(0xFFF2C4BE); // 바랜 장미
      case HighlightColor.orange:
        return const Color(0xFFF3D3B0); // 살구
      case HighlightColor.yellow:
        return const Color(0xFFF3E3A6); // 밀랍
      case HighlightColor.green:
        return const Color(0xFFD2DFBC); // 세이지
      case HighlightColor.blue:
        return const Color(0xFFC6DDD5); // 청록 안개
      case HighlightColor.indigo:
        return const Color(0xFFE4D5C4); // 모래
      case HighlightColor.purple:
        return const Color(0xFFEBD0D6); // 장밋빛 모브
      case HighlightColor.clear:
        return Colors.transparent;
    }
  }

  Color get darkColor {
    switch (this) {
      case HighlightColor.red:
        return const Color(0xFFB4433D); // 벽돌
      case HighlightColor.orange:
        return const Color(0xFFB9733A); // 구운 살구
      case HighlightColor.yellow:
        return const Color(0xFFB8952F); // 바랜 금박
      case HighlightColor.green:
        return const Color(0xFF6E8B4E); // 올리브
      case HighlightColor.blue:
        return const Color(0xFF4E7F74); // 깊은 청록
      case HighlightColor.indigo:
        return const Color(0xFF8A6A4F); // 가죽
      case HighlightColor.purple:
        return const Color(0xFF9A5B6B); // 포도주
      case HighlightColor.clear:
        return Colors.transparent;
    }
  }

  String get displayName {
    switch (this) {
      case HighlightColor.red:
        return '';
      case HighlightColor.orange:
        return '';
      case HighlightColor.yellow:
        return '';
      case HighlightColor.green:
        return '';
      case HighlightColor.blue:
        return '';
      case HighlightColor.indigo:
        return '';
      case HighlightColor.purple:
        return '';
      case HighlightColor.clear:
        return '초기화';
    }
  }

  IconData get icon {
    switch (this) {
      case HighlightColor.clear:
        return Icons.format_color_reset;
      default:
        return Icons.circle;
    }
  }
}
