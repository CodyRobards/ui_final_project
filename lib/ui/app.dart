import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/planner_item.dart';
import '../services/planner_repository.dart';
import 'home_page.dart';
import 'item_form_page.dart';
import 'planner_controller.dart';

/// Design tokens that can be swapped by changing the seed color in one place.
@immutable
class PlannerTokens extends ThemeExtension<PlannerTokens> {
  const PlannerTokens({
    required this.seed,
    required this.surface,
    required this.surfaceMuted,
    required this.hero,
    required this.emphasis,
    required this.surfaceRadius,
    required this.gutter,
  });

  final Color seed;
  final Color surface;
  final Color surfaceMuted;
  final TextStyle hero;
  final TextStyle emphasis;
  final BorderRadius surfaceRadius;
  final double gutter;

  factory PlannerTokens.fromSeed({
    required Color seedColor,
    Brightness brightness = Brightness.light,
  }) {
    final scheme = ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
    return PlannerTokens(
      seed: seedColor,
      surface: scheme.surfaceContainerHighest,
      surfaceMuted: scheme.surfaceContainerHigh,
      hero: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: scheme.onSurface,
      ),
      emphasis: TextStyle(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
        letterSpacing: 0.05,
      ),
      surfaceRadius: BorderRadius.circular(18),
      gutter: 14,
    );
  }

  @override
  PlannerTokens copyWith({
    Color? seed,
    Color? surface,
    Color? surfaceMuted,
    TextStyle? hero,
    TextStyle? emphasis,
    BorderRadius? surfaceRadius,
    double? gutter,
  }) {
    return PlannerTokens(
      seed: seed ?? this.seed,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      hero: hero ?? this.hero,
      emphasis: emphasis ?? this.emphasis,
      surfaceRadius: surfaceRadius ?? this.surfaceRadius,
      gutter: gutter ?? this.gutter,
    );
  }

  @override
  PlannerTokens lerp(ThemeExtension<PlannerTokens>? other, double t) {
    if (other is! PlannerTokens) {
      return this;
    }
    return PlannerTokens(
      seed: Color.lerp(seed, other.seed, t) ?? seed,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t) ?? surfaceMuted,
      hero: TextStyle.lerp(hero, other.hero, t) ?? hero,
      emphasis: TextStyle.lerp(emphasis, other.emphasis, t) ?? emphasis,
      surfaceRadius: BorderRadius.lerp(surfaceRadius, other.surfaceRadius, t) ?? surfaceRadius,
      gutter: lerpDouble(gutter, other.gutter, t) ?? gutter,
    );
  }
}

/// Centralizes theme creation so the visual direction can be tweaked from a
/// single seed color.
class PlannerTheme {
  static const Color defaultSeed = Color(0xFF4C5BD4);

  static ThemeData themed({
    Color seedColor = defaultSeed,
    Brightness brightness = Brightness.light,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      surfaceTint: seedColor,
    );
    final tokens = PlannerTokens.fromSeed(seedColor: seedColor, brightness: brightness);
    final baseTextTheme = brightness == Brightness.dark
        ? Typography.whiteMountainView
        : Typography.blackMountainView;

    final cardTheme = CardThemeData(
      color: tokens.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: tokens.surfaceRadius),
      elevation: 0,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: baseTextTheme.copyWith(
        headlineMedium: tokens.hero,
        titleMedium: tokens.emphasis,
      ),
      cardTheme: cardTheme,
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: colorScheme.outlineVariant),
        labelStyle: TextStyle(color: colorScheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceMuted,
        border: OutlineInputBorder(borderRadius: tokens.surfaceRadius),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.primary),
          borderRadius: tokens.surfaceRadius,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: tokens.surfaceRadius),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: tokens.surfaceRadius),
      ),
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }
}

class PlannerFlutterApp extends StatefulWidget {
  const PlannerFlutterApp({super.key, required this.repository, this.seedColor = PlannerTheme.defaultSeed});

  final PlannerRepository repository;
  final Color seedColor;

  @override
  State<PlannerFlutterApp> createState() => _PlannerFlutterAppState();
}

class _PlannerFlutterAppState extends State<PlannerFlutterApp> {
  late final PlannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PlannerController(repository: widget.repository);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planner',
      theme: PlannerTheme.themed(seedColor: widget.seedColor),
      routes: {
        '/': (context) => PlannerHomePage(controller: _controller),
      },
      onGenerateRoute: (settings) {
        if (settings.name == PlannerFormPage.routeName) {
          final args = settings.arguments as PlannerFormArguments?;
          return MaterialPageRoute<void>(
            builder: (context) => PlannerFormPage(
              controller: _controller,
              existingItem: args?.existing,
            ),
          );
        }
        return null;
      },
    );
  }
}
