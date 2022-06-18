import 'package:flutter/material.dart';

class AppTheme {

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      inputDecorationTheme: _inputDecorationTheme,
    );
  }

  static InputDecorationTheme get _inputDecorationTheme {
    return const InputDecorationTheme(
      focusedBorder: OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(),
      errorBorder: OutlineInputBorder(),
      disabledBorder: OutlineInputBorder(),
      border: OutlineInputBorder(),
      focusedErrorBorder: OutlineInputBorder(),
    );
  }

}