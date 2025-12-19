import 'package:flutter/material.dart';
import '../models/bible_card_layout.dart';
import '../models/bible_card_theme.dart';
import 'bible_card_layouts/minimal_layout.dart';
import 'bible_card_layouts/classic_layout.dart';
import 'bible_card_layouts/simple_layout.dart';
import 'bible_card_layouts/elegant_layout.dart';
import 'bible_card_layouts/nature_layout.dart';
import 'bible_card_layouts/vintage_layout.dart';

/// 다양한 레이아웃을 지원하는 성경 카드
class MultiLayoutBibleCard extends StatelessWidget {
  final String verse;
  final String reference;
  final CardLayoutType layoutType;
  final BibleCardTheme? theme; // 모던 레이아웃에서만 사용
  final bool? forceWhiteText; // 모던 레이아웃에서만 사용
  final String shareTitle;

  const MultiLayoutBibleCard({
    super.key,
    required this.verse,
    required this.reference,
    this.layoutType = CardLayoutType.minimal,
    this.theme,
    this.forceWhiteText,
    required this.shareTitle,
  });

  @override
  Widget build(BuildContext context) {
    switch (layoutType) {
      case CardLayoutType.minimal:
        return MinimalLayout(
          verse: verse,
          reference: reference,
          shareTitle: shareTitle,
        );

      case CardLayoutType.classic:
        return ClassicLayout(
          verse: verse,
          reference: reference,
          shareTitle: shareTitle,
        );

      case CardLayoutType.simple:
        return SimpleLayout(
          verse: verse,
          reference: reference,
          shareTitle: shareTitle,
        );

      case CardLayoutType.elegant:
        return ElegantLayout(
          verse: verse,
          reference: reference,
          shareTitle: shareTitle,
        );

      case CardLayoutType.nature:
        return NatureLayout(
          verse: verse,
          reference: reference,
          shareTitle: shareTitle,
        );

      case CardLayoutType.vintage:
        return VintageLayout(
          verse: verse,
          reference: reference,
          shareTitle: shareTitle,
        );
    }
  }
}
