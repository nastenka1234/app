import 'package:flutter/material.dart';

/// پالت ثابت؛ رنگ دیگری اضافه نشود.
class T {
  static const bg = Color(0xFF17172D);
  static const sec = Color(0xFF282444);
  static const glass = Color(0x1FA78BFA); // rgba(167,139,250,.12)
  static const line = Color(0x29FFFFFF); // rgba(255,255,255,.16)
  static const acc = Color(0xFFA78BFA);
  static const tx = Color(0xFFFFFFFF);
  static const tx2 = Color(0xFFB8B5D0);
  static const hi = Color(0xFFE9DFFF);

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(seedColor: acc, brightness: Brightness.dark).copyWith(
      primary: acc,
      onPrimary: bg,
      secondary: hi,
      surface: sec,
      surfaceContainer: sec,
      surfaceContainerHigh: sec,
      onSurface: tx,
    );
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Sheed',
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
    );
    OutlineInputBorder b(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(22), borderSide: BorderSide(color: c));
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: tx, displayColor: tx, fontFamily: 'Sheed'),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
            fontFamily: 'Sheed', fontWeight: FontWeight.w700, fontSize: 18, color: tx),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glass,
        border: b(line),
        enabledBorder: b(line),
        focusedBorder: b(acc),
        labelStyle: const TextStyle(color: tx2),
        hintStyle: const TextStyle(color: tx2),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: sec, surfaceTintColor: Colors.transparent),
      snackBarTheme: SnackBarThemeData(
          backgroundColor: sec,
          contentTextStyle: const TextStyle(fontFamily: 'Sheed', color: tx),
          behavior: SnackBarBehavior.floating),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: acc,
        labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontFamily: 'Sheed', fontSize: 12, color: tx2)),
        iconTheme: WidgetStateProperty.resolveWith(
            (s) => IconThemeData(color: s.contains(WidgetState.selected) ? bg : tx2)),
      ),
      dividerColor: line,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? bg : tx2),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? acc : glass),
      ),
    );
  }
}
