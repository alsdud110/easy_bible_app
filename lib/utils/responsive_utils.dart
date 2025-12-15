import 'package:flutter/material.dart';

/// 반응형 폰트 크기 및 레이아웃 유틸리티
class ResponsiveUtils {
  /// 화면 너비 기준 breakpoint
  static const double smallScreenWidth = 380.0;
  static const double mediumScreenWidth = 600.0;

  /// 화면이 작은지 확인
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < smallScreenWidth;
  }

  /// 화면이 중간 크기인지 확인
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= smallScreenWidth && width < mediumScreenWidth;
  }

  /// 화면이 큰지 확인
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= mediumScreenWidth;
  }

  /// 반응형 폰트 크기 계산 (작은 화면 / 기본 화면)
  static double fontSize(BuildContext context, double defaultSize) {
    return isSmallScreen(context) ? defaultSize - 2 : defaultSize;
  }

  /// 반응형 아이콘 크기 계산
  static double iconSize(BuildContext context, double defaultSize) {
    return isSmallScreen(context) ? defaultSize - 4 : defaultSize;
  }

  /// 반응형 패딩 계산
  static double padding(BuildContext context, double defaultPadding) {
    return isSmallScreen(context) ? defaultPadding - 4 : defaultPadding;
  }

  /// 반응형 여백 계산
  static double spacing(BuildContext context, double defaultSpacing) {
    return isSmallScreen(context) ? defaultSpacing * 0.8 : defaultSpacing;
  }

  /// 제목용 폰트 크기 (큰 텍스트)
  static double titleFontSize(BuildContext context) {
    return isSmallScreen(context) ? 20.0 : 22.0;
  }

  /// 본문용 폰트 크기
  static double bodyFontSize(BuildContext context) {
    return isSmallScreen(context) ? 14.0 : 16.0;
  }

  /// 캡션용 폰트 크기 (작은 텍스트)
  static double captionFontSize(BuildContext context) {
    return isSmallScreen(context) ? 12.0 : 13.0;
  }

  /// 버튼용 폰트 크기
  static double buttonFontSize(BuildContext context) {
    return isSmallScreen(context) ? 16.0 : 18.0;
  }

  /// AppBar 타이틀용 폰트 크기
  static double appBarTitleFontSize(BuildContext context) {
    return isSmallScreen(context) ? 20.0 : 22.0;
  }

  /// 카드 패딩
  static double cardPadding(BuildContext context) {
    return isSmallScreen(context) ? 16.0 : 20.0;
  }

  /// 화면 전체 패딩
  static double screenPadding(BuildContext context) {
    return isSmallScreen(context) ? 16.0 : 20.0;
  }

  /// 반응형 텍스트 위젯 (FittedBox 포함)
  static Widget responsiveText(
    String text, {
    required TextStyle style,
    TextAlign? textAlign,
    int? maxLines,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: textAlign == TextAlign.center
          ? Alignment.center
          : Alignment.centerLeft,
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines ?? 1,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
