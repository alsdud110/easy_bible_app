import 'package:flutter/material.dart';

/// 반응형 텍스트 위젯 - 기존 Text를 감싸서 사용
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool autoScale;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.autoScale = true,
  });

  @override
  Widget build(BuildContext context) {
    // 스타일에서 폰트 크기 추출
    final fontSize = style?.fontSize;

    // 큰 텍스트(20px 이상)만 반응형 처리
    final shouldMakeResponsive = fontSize != null && fontSize >= 18.0;

    if (shouldMakeResponsive && autoScale) {
      // FittedBox로 감싸서 반응형으로 만들기
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: _getAlignment(),
        child: Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines ?? 1,
          overflow: TextOverflow.visible,
        ),
      );
    }

    // 작은 텍스트는 그대로 표시
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  Alignment _getAlignment() {
    switch (textAlign) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }
}

/// 반응형 스타일 헬퍼
extension ResponsiveTextStyle on TextStyle {
  /// 반응형 폰트 크기 적용
  TextStyle responsive(BuildContext context) {
    if (fontSize == null) return this;

    final screenWidth = MediaQuery.of(context).size.width;
    final adjustedSize = screenWidth < 380
        ? (fontSize! * 0.9) // 10% 줄이기
        : fontSize!;

    return copyWith(fontSize: adjustedSize);
  }
}
