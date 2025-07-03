import 'package:flutter/material.dart';
import 'colors.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  fontFamily: 'Pretendard',
  scaffoldBackgroundColor: LightColors.background,
  primaryColor: LightColors.primary,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: LightColors.primary,
    onPrimary: LightColors.onPrimary,
    secondary: LightColors.secondary,
    onSecondary: LightColors.onSecondary,
    background: LightColors.background,
    onBackground: LightColors.onBackground,
    surface: LightColors.surface,
    onSurface: LightColors.onSurface,
    error: CommonColors.error,
    onError: Colors.white,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.bold,
      letterSpacing: -1,
      color: LightColors.display,
    ),
    headlineLarge: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.bold,
      color: LightColors.headline,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: LightColors.headline,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: LightColors.onSurface,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: LightColors.body,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: LightColors.bodyMedium,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: LightColors.bodySmall,
    ),
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: LightColors.label,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: LightColors.label,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: LightColors.labelSmall,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: LightColors.appBar,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w700,
      fontSize: 20,
      color: LightColors.onBackground,
      letterSpacing: -0.5,
    ),
    iconTheme: IconThemeData(color: LightColors.primary),
    actionsIconTheme: IconThemeData(color: LightColors.primary),
    centerTitle: true,
    shadowColor: Colors.transparent,
  ),
  cardTheme: CardTheme(
    elevation: 0,
    color: LightColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: LightColors.cardBorder, width: 1.2),
    ),
    margin: const EdgeInsets.all(12),
    shadowColor: Colors.black12,
    surfaceTintColor: LightColors.cardSurfaceTint,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: LightColors.fabFill,
    foregroundColor: Colors.white,
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: LightColors.inputFill,
    contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: LightColors.secondary, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: LightColors.secondary, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: LightColors.primary, width: 2),
    ),
    hintStyle: TextStyle(
      color: LightColors.bodySmall,
      fontSize: 15,
      fontWeight: FontWeight.w400,
    ),
    labelStyle: TextStyle(
      color: LightColors.primary,
      fontWeight: FontWeight.w500,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: LightColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(
          fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.5),
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: LightColors.primary,
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: LightColors.primary, width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: LightColors.divider,
    thickness: 1,
    space: 1,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: LightColors.appBar,
    elevation: 8,
    selectedItemColor: LightColors.primary,
    unselectedItemColor: LightColors.secondary,
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
    type: BottomNavigationBarType.fixed,
    showUnselectedLabels: true,
  ),
);

final ThemeData appThemeDark = ThemeData(
  useMaterial3: true,
  fontFamily: 'Pretendard',
  scaffoldBackgroundColor: DarkColors.background,
  primaryColor: DarkColors.primary,
  colorScheme: const ColorScheme.dark(
    primary: DarkColors.primary,
    onPrimary: DarkColors.onPrimary,
    secondary: DarkColors.secondary,
    onSecondary: DarkColors.onSecondary,
    background: DarkColors.background,
    onBackground: DarkColors.onBackground,
    surface: DarkColors.surface,
    onSurface: DarkColors.onSurface,
    error: CommonColors.error,
    onError: Colors.black,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.bold,
      letterSpacing: -1,
      color: DarkColors.display,
    ),
    headlineLarge: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.bold,
      color: DarkColors.headline,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: DarkColors.headline,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: DarkColors.display,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: DarkColors.body,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: DarkColors.bodyMedium,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: DarkColors.bodySmall,
    ),
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: DarkColors.label,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: DarkColors.label,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: DarkColors.labelSmall,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: DarkColors.appBar,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w700,
      fontSize: 20,
      color: DarkColors.onSurface,
      letterSpacing: -0.5,
    ),
    iconTheme: IconThemeData(color: DarkColors.primary),
    actionsIconTheme: IconThemeData(color: DarkColors.primary),
    centerTitle: true,
    shadowColor: Colors.transparent,
  ),
  cardTheme: CardTheme(
    elevation: 0,
    color: DarkColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: DarkColors.cardBorder, width: 1.2),
    ),
    margin: const EdgeInsets.all(12),
    shadowColor: Colors.black45,
    surfaceTintColor: DarkColors.cardSurfaceTint,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: DarkColors.fabFill,
    foregroundColor: Colors.black,
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: DarkColors.inputFill,
    contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: DarkColors.primary, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: DarkColors.primary, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: DarkColors.onSurface, width: 2),
    ),
    hintStyle: TextStyle(
      color: DarkColors.bodySmall,
      fontSize: 15,
      fontWeight: FontWeight.w400,
    ),
    labelStyle: TextStyle(
      color: DarkColors.primary,
      fontWeight: FontWeight.w500,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: DarkColors.primary,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(
          fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: -0.5),
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: DarkColors.primary,
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: DarkColors.primary, width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
    ),
  ),
  dividerTheme: const DividerThemeData(
    color: DarkColors.divider,
    thickness: 1,
    space: 1,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: DarkColors.appBar,
    elevation: 8,
    selectedItemColor: DarkColors.primary,
    unselectedItemColor: DarkColors.secondary,
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
    type: BottomNavigationBarType.fixed,
    showUnselectedLabels: true,
  ),
);
