import 'package:flutter/material.dart';

/// 성경 카드 레이아웃 타입
enum CardLayoutType {
  minimal, // 미니멀 디자인
  classic, // 클래식 디자인
  simple, // 심플 디자인
  elegant, // 우아한 디자인
  nature, // 자연 테마 디자인
  vintage, // 빈티지 디자인
}

/// 카드 레이아웃 정보
class BibleCardLayout {
  final CardLayoutType type;
  final String name;
  final String description;
  final IconData icon;

  const BibleCardLayout({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
  });

  static const List<BibleCardLayout> layouts = [
    BibleCardLayout(
      type: CardLayoutType.minimal,
      name: '깔끔',
      description: '깔끔하고 단순한 디자인',
      icon: Icons.line_style,
    ),
    BibleCardLayout(
      type: CardLayoutType.classic,
      name: '고전',
      description: '전통적인 성경 카드',
      icon: Icons.auto_stories,
    ),
    BibleCardLayout(
      type: CardLayoutType.simple,
      name: '기본',
      description: '간결한 화이트 카드',
      icon: Icons.receipt_long,
    ),
    BibleCardLayout(
      type: CardLayoutType.elegant,
      name: '우아',
      description: '고급스러운 골드 테마',
      icon: Icons.workspace_premium,
    ),
    BibleCardLayout(
      type: CardLayoutType.nature,
      name: '자연',
      description: '부드러운 자연 테마',
      icon: Icons.park,
    ),
    BibleCardLayout(
      type: CardLayoutType.vintage,
      name: '빈티지',
      description: '레트로 감성 디자인',
      icon: Icons.photo_camera,
    ),
  ];
}
