import 'package:flutter/material.dart';

const _primary = Color(0xFF1769E0);
const _success = Color(0xFF12B76A);
const _warning = Color(0xFFF79009);
const _error = Color(0xFFD92D20);

abstract final class GuruTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          primary: _primary,
          error: _error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        extensions: const [WtfColors(success: _success, warning: _warning)],
      );
}

class WtfColors extends ThemeExtension<WtfColors> {
  const WtfColors({required this.success, required this.warning});

  final Color success;
  final Color warning;

  @override
  WtfColors copyWith({Color? success, Color? warning}) =>
      WtfColors(success: success ?? this.success, warning: warning ?? this.warning);

  @override
  WtfColors lerp(WtfColors? other, double t) {
    if (other == null) return this;
    return WtfColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}
