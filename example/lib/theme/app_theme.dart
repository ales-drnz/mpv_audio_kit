import 'dart:ui';
import 'package:flutter/material.dart';

/// App-wide theme. Aligned with the maintainer's other Flutter project
/// (`dart_smb2`): Material 3 + Colors.blue seed + click cursor on every
/// interactive surface + 12 px border radius on buttons.
///
/// Light/dark variants are derived from a single shared builder that
/// flips only the [Brightness] — all surfaces, buttons, sliders, and
/// scrollbars are brightness-agnostic and resolve via the seeded
/// [ColorScheme]. [MaterialApp.themeMode] should be set to
/// [ThemeMode.system] so the OS preference drives the choice.
class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: brightness,
    ),
    useMaterial3: true,
    // Opt into Material 3 expressive (year2024) slider design:
    // wider track, squared "stadium" thumb, visible gap between
    // thumb and track. Applies to every Slider in the app.
    // The `year2023` flag is marked deprecated because in a future
    // Flutter release the 2024 design becomes the default; until
    // then the explicit opt-in is the only way to get it.
    // ignore: deprecated_member_use
    sliderTheme: const SliderThemeData(year2023: false),
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: WidgetStateProperty.all(true),
      interactive: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
    ),
    switchTheme: SwitchThemeData(
      mouseCursor: WidgetStateProperty.resolveWith(
        (states) => SystemMouseCursors.click,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      mouseCursor: WidgetStateProperty.resolveWith(
        (states) => SystemMouseCursors.click,
      ),
    ),
    radioTheme: RadioThemeData(
      mouseCursor: WidgetStateProperty.resolveWith(
        (states) => SystemMouseCursors.click,
      ),
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      menuStyle: MenuStyle(
        mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
      ),
    ),
  );

  static ScrollBehavior get scrollBehavior =>
      const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      );

  /// Color used by audio_service for the system media notification
  /// accent (Android MediaSession color band, etc). Sampled from the
  /// Material Blue palette (700) so it matches the in-app primary.
  static const Color notificationColor = Color(0xFF1976D2);
}
