import 'package:flutter/material.dart';

const cream = Color(0xFFFFF8EF);
const peach = Color(0xFFFAD6B8);
const sage = Color(0xFFDBE9DB);
const ink = Color(0xFF412E29);

ThemeData koinuTheme() {
  final scheme =
      ColorScheme.fromSeed(seedColor: const Color(0xFFC36948)).copyWith(
    primary: const Color(0xFF99472E),
    surface: cream,
    onSurface: ink,
    secondaryContainer: sage,
    primaryContainer: peach,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(22));
  final field = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFD9C5B8)));
  return ThemeData(
    fontFamily: 'Roboto',
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: cream,
    appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: ink,
        titleTextStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: ink)),
    cardTheme: CardThemeData(color: Colors.white, elevation: 0, shape: shape),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF2AA76),
            foregroundColor: ink,
            minimumSize: const Size(48, 50),
            textStyle: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 16))),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: field,
        enabledBorder: field),
  );
}
