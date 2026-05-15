import 'package:flutter/material.dart';

class PostyTheme {
  const PostyTheme({
    required this.brightness,
    required this.scaffoldBackground,
    required this.panelBackground,
    required this.borderColor,
    required this.primaryColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.inputFill,
    required this.successColor,
    required this.warningColor,
    required this.errorColor,
    required this.codeBackground,
  });

  final Brightness brightness;
  final Color scaffoldBackground;
  final Color panelBackground;
  final Color borderColor;
  final Color primaryColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color inputFill;
  final Color successColor;
  final Color warningColor;
  final Color errorColor;
  final Color codeBackground;

  static PostyTheme dark() => const PostyTheme(
        brightness: Brightness.dark,
        scaffoldBackground: Color(0xFF13141A),
        panelBackground: Color(0xFF1E1F26),
        borderColor: Color(0xFF2E3038),
        primaryColor: Color(0xFF7C5CFF),
        textPrimary: Color(0xFFE8E9ED),
        textSecondary: Color(0xFF9DA3AE),
        inputFill: Color(0xFF25262E),
        successColor: Color(0xFF3DDC84),
        warningColor: Color(0xFFFFB020),
        errorColor: Color(0xFFFF6B6B),
        codeBackground: Color(0xFF16171D),
      );

  static PostyTheme light() => const PostyTheme(
        brightness: Brightness.light,
        scaffoldBackground: Color(0xFFF4F5F7),
        panelBackground: Color(0xFFFFFFFF),
        borderColor: Color(0xFFE2E4E9),
        primaryColor: Color(0xFF6B4EFF),
        textPrimary: Color(0xFF1A1D24),
        textSecondary: Color(0xFF6B7280),
        inputFill: Color(0xFFF9FAFB),
        successColor: Color(0xFF16A34A),
        warningColor: Color(0xFFD97706),
        errorColor: Color(0xFFDC2626),
        codeBackground: Color(0xFFF3F4F6),
      );

  ThemeData toThemeData() {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor,
      ),
      dividerColor: borderColor,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        isDense: true,
      ),
    );
  }
}
