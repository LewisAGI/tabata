import 'package:flutter/material.dart';

class AppColors {
  static const canvas = Color(0xFFFFFFFF);
  static const accent = Color(0xFFF15A22);
  static const accentPressed = Color(0xFFD14A18);
  static const accentSoft = Color(0xFFFFE8DE);
  static const ink = Color(0xFF1C1917);
  static const muted = Color(0xFF78716C);
  static const hairline = Color(0xFFE7E5E4);
  static const stop = Color(0xFFFF3B30);
  static const workTint = Color(0xFFFFF1EB);
  static const restTint = Color(0xFFE8EEF5);
  static const setRestTint = Color(0xFFF3F0FA);
  static const cooldownTint = Color(0xFFF5F5F4);
  static const field = Color(0xFFF5F5F4);
}

ThemeData buildTheme() {
  const accent = AppColors.accent;
  final scheme = ColorScheme.light(
    primary: accent,
    onPrimary: Colors.white,
    secondary: accent,
    onSecondary: Colors.white,
    surface: AppColors.canvas,
    onSurface: AppColors.ink,
    outline: AppColors.hairline,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: AppColors.canvas,
    splashColor: AppColors.accentSoft,
    dividerColor: AppColors.hairline,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontFamily: 'Roboto',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      iconTheme: IconThemeData(color: AppColors.accent),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(
        fontFamily: 'Roboto',
        color: AppColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

BoxDecoration cardBox() {
  return BoxDecoration(
    color: AppColors.canvas,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: AppColors.hairline),
    boxShadow: const [
      BoxShadow(color: Color(0x0A1C1917), blurRadius: 16, offset: Offset(0, 6)),
    ],
  );
}
