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
    final scheme =
        ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
    final blendedSurface = Color.alphaBlend(
      scheme.primary.withOpacity(brightness == Brightness.dark ? 0.08 : 0.06),
      scheme.surface,
    );
    final blendedMuted = Color.alphaBlend(
      scheme.primaryContainer
          .withOpacity(brightness == Brightness.dark ? 0.08 : 0.04),
      scheme.surfaceVariant,
    );
    return PlannerTokens(
      seed: seedColor,
      surface: blendedSurface,
      surfaceMuted: blendedMuted,
      hero: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: scheme.onSurface,
      ),
      emphasis: TextStyle(
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
        letterSpacing: 0.15,
      ),
      surfaceRadius: BorderRadius.circular(22),
      gutter: 16,
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
      surfaceMuted:
          Color.lerp(surfaceMuted, other.surfaceMuted, t) ?? surfaceMuted,
      hero: TextStyle.lerp(hero, other.hero, t) ?? hero,
      emphasis: TextStyle.lerp(emphasis, other.emphasis, t) ?? emphasis,
      surfaceRadius: BorderRadius.lerp(surfaceRadius, other.surfaceRadius, t) ??
          surfaceRadius,
      gutter: lerpDouble(gutter, other.gutter, t) ?? gutter,
    );
  }
}

/// Centralizes theme creation so the visual direction can be tweaked from a
/// single seed color.
class PlannerTheme {
  static const Color defaultSeed = Color(0xFFFFC7A6);

  static ThemeData themed({
    Color seedColor = defaultSeed,
    Brightness brightness = Brightness.light,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      surfaceTint: seedColor,
    );
    final tokens =
        PlannerTokens.fromSeed(seedColor: seedColor, brightness: brightness);
    final baseTextTheme = brightness == Brightness.dark
        ? Typography.whiteMountainView
        : Typography.blackMountainView;

    final CardThemeData cardTheme = CardThemeData(
      color: tokens.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: tokens.surfaceRadius),
      elevation: 2,
      shadowColor: colorScheme.shadow.withOpacity(
        brightness == Brightness.dark ? 0.35 : 0.18,
      ),
      surfaceTintColor: Colors.white.withOpacity(
        brightness == Brightness.dark ? 0.04 : 0.08,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: baseTextTheme.copyWith(
        headlineMedium: tokens.hero,
        titleMedium: tokens.emphasis,
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.25,
        ),
      ),
      cardTheme: cardTheme,
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        shadowColor: colorScheme.shadow
            .withOpacity(brightness == Brightness.dark ? 0.3 : 0.14),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.6)),
        labelStyle: TextStyle(color: colorScheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        backgroundColor: tokens.surface,
        selectedColor: tokens.surfaceMuted,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: tokens.surfaceRadius,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: colorScheme.primary.withOpacity(0.35)),
          borderRadius: tokens.surfaceRadius,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outlineVariant),
          borderRadius: tokens.surfaceRadius,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.65),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurface,
          shadowColor:
              colorScheme.shadow.withOpacity(brightness == Brightness.dark ? 0.4 : 0.2),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: tokens.surfaceRadius),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.6)),
          shape: RoundedRectangleBorder(borderRadius: tokens.surfaceRadius),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: tokens.surface,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: tokens.surfaceRadius),
        elevation: 4,
        focusElevation: 5,
        hoverElevation: 6,
        highlightElevation: 6,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        shadowColor:
            colorScheme.shadow.withOpacity(brightness == Brightness.dark ? 0.4 : 0.2),
      ),
      shadowColor: colorScheme.shadow.withOpacity(
        brightness == Brightness.dark ? 0.4 : 0.22,
      ),
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }
}

class PlannerFlutterApp extends StatefulWidget {
  const PlannerFlutterApp(
      {super.key,
      required this.repository,
      this.seedColor = PlannerTheme.defaultSeed});

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
