import 'package:flutter/material.dart';

import 'calc.dart';

/// Palet C (onaylı).
abstract final class C {
  static const deep = Color(0xFF3C3489);
  static const main = Color(0xFF534AB7);
  static const ink = Color(0xFF26215C);
  static const muted = Color(0xFF5F5A80);
  static const tint = Color(0xFFEEEDFE);
  static const line = Color(0xFFCECBF6);
  static const bg = Color(0xFFF6F5FC);
  static const accent = Color(0xFFEF9F27);
  static const onAccent = Color(0xFF412402);
  static const accentTint = Color(0xFFFAEEDA);
  static const accentInk = Color(0xFF854F0B);
  static const up = Color(0xFF2E9E5B);
  static const down = Color(0xFFE24B4A);
  static const same = Color(0xFFBA7517);
  static const blank = Color(0xFF888780);
  static const okInk = Color(0xFF3B6D11);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: C.main,
    primary: C.deep,
    secondary: C.accent,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: C.deep,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: C.tint,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 16, color: C.ink),
      bodyLarge: TextStyle(fontSize: 17, color: C.ink),
    ),
  );
}

/// ▲ / ▼ / ▶ arrow for a trend; empty for [Trend.none].
class TrendArrow extends StatelessWidget {
  final Trend trend;
  final double size;
  const TrendArrow(this.trend, {super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final (String t, Color c) = switch (trend) {
      Trend.better => ('▲', C.up),
      Trend.worse => ('▼', C.down),
      Trend.same => ('▶', C.same),
      Trend.none => ('', C.muted),
    };
    return Text(t, style: TextStyle(color: c, fontSize: size));
  }
}
