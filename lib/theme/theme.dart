import 'package:arber/theme/colors.dart';
import 'package:flutter/material.dart';

class AppTheme {

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: smoothBlue,
      scaffoldBackgroundColor: Colors.white,
      inputDecorationTheme: _inputDecorationTheme,
    );
  }

  static InputDecorationTheme get _inputDecorationTheme {
    return InputDecorationTheme(
      fillColor: Colors.grey.shade200,
      filled: true,
      hintStyle: _hintTextStyle,
      focusedBorder: _inputDecorationBorder,
      enabledBorder: _inputDecorationBorder,
      errorBorder: _inputDecorationBorder,
      disabledBorder: _inputDecorationBorder,
      border: _inputDecorationBorder,
      focusedErrorBorder: _inputDecorationBorder,
    );
  }

  static OutlineInputBorder get _inputDecorationBorder {
    return OutlineInputBorder(
      borderSide: BorderSide.none,
      borderRadius: BorderRadius.circular(10),
    );
  }

  static TextStyle get inputTextStyle => const TextStyle(color: Colors.black54);
  static TextStyle get _hintTextStyle => const TextStyle(color: Colors.black45);
}
