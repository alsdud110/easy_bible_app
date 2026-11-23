import 'package:flutter/material.dart';
import 'colors.dart';

// 테마 원칙
// - 표면/글자는 종이·먹색 무채색 하나, 강조는 버건디 하나 (colors.dart)
// - 굵기는 400/500, 드물게 600. 800~900 제목 없음
// - 작은 글자에 음수 자간 없음. 큰 제목만 살짝 좁힘
// - 깊이는 그림자가 아니라 면의 단계와 헤어라인으로
// - 모서리: 버튼/입력 10, 카드 16, 시트 20

/// 팔레트 한 벌 (라이트/다크 공통 구조)
class _Palette {
  final Brightness brightness;
  final Color background, surface, raised, deepest;
  final Color primary, onPrimary, primaryContainer, onPrimaryContainer;
  final Color secondary, onSecondary;
  final Color divider, outline;
  final Color text, textBody, textSecondary, textMuted;
  final Color error, onError;

  const _Palette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.raised,
    required this.deepest,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.divider,
    required this.outline,
    required this.text,
    required this.textBody,
    required this.textSecondary,
    required this.textMuted,
    required this.error,
    required this.onError,
  });
}

const _light = _Palette(
  brightness: Brightness.light,
  background: LightColors.background,
  surface: LightColors.surface,
  raised: LightColors.raised,
  deepest: LightColors.deepest,
  primary: LightColors.primary,
  onPrimary: LightColors.onPrimary,
  primaryContainer: LightColors.primaryContainer,
  onPrimaryContainer: LightColors.onPrimaryContainer,
  secondary: LightColors.secondary,
  onSecondary: LightColors.onSecondary,
  divider: LightColors.divider,
  outline: LightColors.outline,
  text: LightColors.onSurface,
  textBody: LightColors.body,
  textSecondary: LightColors.bodyMedium,
  textMuted: LightColors.bodySmall,
  error: CommonColors.error,
  onError: Colors.white,
);

const _dark = _Palette(
  brightness: Brightness.dark,
  background: DarkColors.background,
  surface: DarkColors.surface,
  raised: DarkColors.raised,
  deepest: DarkColors.deepest,
  primary: DarkColors.primary,
  onPrimary: DarkColors.onPrimary,
  primaryContainer: DarkColors.primaryContainer,
  onPrimaryContainer: DarkColors.onPrimaryContainer,
  secondary: DarkColors.secondary,
  onSecondary: DarkColors.onSecondary,
  divider: DarkColors.divider,
  outline: DarkColors.outline,
  text: DarkColors.onSurface,
  textBody: DarkColors.body,
  textSecondary: DarkColors.bodyMedium,
  textMuted: DarkColors.bodySmall,
  error: Color(0xFFE07A72),
  onError: Color(0xFF1F1310),
);

ThemeData _buildTheme(_Palette p) {
  // Material 3가 빈 역할을 기본 보라색으로 채우지 않도록 모든 역할을 지정한다.
  final scheme = ColorScheme(
    brightness: p.brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    primaryContainer: p.primaryContainer,
    onPrimaryContainer: p.onPrimaryContainer,
    secondary: p.secondary,
    onSecondary: p.onSecondary,
    secondaryContainer: p.raised,
    onSecondaryContainer: p.text,
    tertiary: p.secondary,
    onTertiary: p.onSecondary,
    tertiaryContainer: p.raised,
    onTertiaryContainer: p.text,
    error: p.error,
    onError: p.onError,
    errorContainer: p.error.withValues(alpha: 0.12),
    onErrorContainer: p.error,
    surface: p.surface,
    onSurface: p.text,
    onSurfaceVariant: p.textSecondary,
    surfaceDim: p.deepest,
    surfaceBright: p.surface,
    surfaceContainerLowest: p.surface,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.background,
    surfaceContainerHigh: p.raised,
    surfaceContainerHighest: p.raised,
    outline: p.outline,
    outlineVariant: p.divider,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: p.text,
    onInverseSurface: p.background,
    inversePrimary: p.brightness == Brightness.light
        ? DarkColors.primary
        : LightColors.primary,
    surfaceTint: Colors.transparent,
  );

  final textTheme = TextTheme(
    // 큰 제목만 살짝 좁은 자간
    displayLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.6,
      color: p.text,
      height: 1.2,
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.3,
      color: p.text,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      color: p.text,
      height: 1.3,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: p.text,
      height: 1.35,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: p.text,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: p.text,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: p.text,
    ),
    bodyLarge: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      color: p.textBody,
      height: 1.6,
    ),
    bodyMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: p.textSecondary,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: p.textMuted,
      height: 1.45,
    ),
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: p.textSecondary,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: p.textSecondary,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: p.textMuted,
    ),
  );

  final controlShape =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
  const buttonText = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w500,
    fontSize: 16,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    fontFamily: 'Pretendard',
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    canvasColor: p.background,
    primaryColor: p.primary,
    dividerColor: p.divider,
    splashFactory: InkRipple.splashFactory,
    highlightColor: p.text.withValues(alpha: 0.04),
    splashColor: p.text.withValues(alpha: 0.06),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.text,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: true,
      shadowColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w500,
        fontSize: 18,
        color: p.text,
      ),
      // 앱바 아이콘은 강조색이 아니라 글자색. 강조는 아껴 쓴다
      iconTheme: IconThemeData(color: p.text),
      actionsIconTheme: IconThemeData(color: p.textSecondary),
    ),
    iconTheme: IconThemeData(color: p.textSecondary, size: 22),
    cardTheme: CardThemeData(
      elevation: 0,
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.divider),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: p.textSecondary,
      textColor: p.text,
      selectedColor: p.primary,
      selectedTileColor: p.raised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.primary,
      foregroundColor: p.onPrimary,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.raised,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: p.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: p.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: p.primary, width: 1.5),
      ),
      hintStyle: TextStyle(
        color: p.textMuted,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: TextStyle(
        color: p.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        shape: controlShape,
        textStyle: buttonText,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        shape: controlShape,
        textStyle: buttonText,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        // 보조 버튼: 강조색이 아니라 올라온 면 + 헤어라인 + 본문 글자
        foregroundColor: p.text,
        backgroundColor: Colors.transparent,
        side: BorderSide(color: p.outline),
        shape: controlShape,
        textStyle: buttonText,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.primary,
        shape: controlShape,
        textStyle: buttonText.copyWith(fontSize: 15),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.raised,
      selectedColor: p.primaryContainer,
      side: BorderSide(color: p.divider),
      labelStyle: TextStyle(color: p.text, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.primary,
      linearTrackColor: p.raised,
      circularTrackColor: p.raised,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? p.onPrimary : p.textMuted),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? p.primary : p.raised),
      trackOutlineColor: WidgetStateProperty.all(p.outline),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? p.primary : Colors.transparent),
      checkColor: WidgetStateProperty.all(p.onPrimary),
      side: BorderSide(color: p.outline, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.divider),
      ),
      titleTextStyle: textTheme.headlineSmall,
      contentTextStyle: textTheme.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.text,
      contentTextStyle: TextStyle(
        fontFamily: 'Pretendard',
        color: p.background,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: p.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: p.divider,
      thickness: 1,
      space: 1,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: p.background,
      elevation: 0,
      selectedItemColor: p.primary,
      unselectedItemColor: p.textMuted,
      selectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      unselectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
  );
}

final ThemeData appTheme = _buildTheme(_light);
final ThemeData appThemeDark = _buildTheme(_dark);
