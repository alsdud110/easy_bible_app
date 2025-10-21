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

extension HighlightColorExtension on HighlightColor {
  Color get color {
    switch (this) {
      case HighlightColor.red:
        return const Color(0xFFFFB3BA); // 연한 핑크-레드
      case HighlightColor.orange:
        return const Color(0xFFFFDFBA); // 부드러운 피치
      case HighlightColor.yellow:
        return const Color(0xFFFFF4BA); // 은은한 레몬
      case HighlightColor.green:
        return const Color(0xFFBAF1C8); // 민트 그린
      case HighlightColor.blue:
        return const Color(0xFFBAE1FF); // 하늘색
      case HighlightColor.indigo:
        return const Color(0xFFD4C5F9); // 라벤더
      case HighlightColor.purple:
        return const Color(0xFFFFBAF3); // 연보라-핑크
      case HighlightColor.clear:
        return Colors.transparent;
    }
  }

  Color get darkColor {
    switch (this) {
      case HighlightColor.red:
        return const Color(0xFFE63946); // 선명한 레드
      case HighlightColor.orange:
        return const Color(0xFFF77F00); // 따뜻한 오렌지
      case HighlightColor.yellow:
        return const Color(0xFFF9C74F); // 골든 옐로우
      case HighlightColor.green:
        return const Color(0xFF06D6A0); // 에메랄드 그린
      case HighlightColor.blue:
        return const Color(0xFF118AB2); // 딥 블루
      case HighlightColor.indigo:
        return const Color(0xFF7209B7); // 바이올렛
      case HighlightColor.purple:
        return const Color(0xFFD946EF); // 핫 핑크-퍼플
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
