import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Brand colour tokens.
///
/// Text colours must meet WCAG AA (4.5:1) against [paper], [surface] and
/// [surfaceMuted]. [faint] and [orange] are decorative only — never use them
/// for body or label text.
abstract final class AppColors {
  static const ink = Color(0xFF22201E);
  static const inkSoft = Color(0xFF4E4A44);

  /// Secondary text. 6.2:1 on [paper] and 6.5:1 on [surface].
  static const muted = Color(0xFF5F5B54);

  /// Decorative dividers, disabled icons and art only. 3.2:1 on [paper] —
  /// below AA for text, so keep it out of [Text] widgets.
  static const faint = Color(0xFF8D887F);

  static const paper = Color(0xFFF7F5F0);
  static const surface = Color(0xFFFBFAF7);
  static const surfaceMuted = Color(0xFFFCFBF8);
  static const line = Color(0xFFE2DED6);
  static const lineStrong = Color(0xFFD2CEC5);

  static const teal = Color(0xFF277C78);
  static const tealSoft = Color(0xFFDDF2EE);
  static const tealBorder = Color(0xFFB7D8D2);

  /// Accent only: 2.7:1 on [paper], so never use it for text.
  static const orange = Color(0xFFF07A2F);

  static const danger = Color(0xFFB3261E);
  static const dangerSoft = Color(0xFFFFF1EC);
  static const success = Color(0xFF1E6B3F);
  static const successSoft = Color(0xFFE3F1E7);
  static const warning = Color(0xFF795D2D);
  static const warningSoft = Color(0xFFF7EBD1);
  static const focus = Color(0xFF1F6F6B);
}

/// 4-point spacing scale. Use these instead of ad-hoc padding values.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

/// Corner-radius tokens: controls, cards, and media surfaces.
abstract final class AppRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
}

/// Type scale. Keep sizes to these steps and weights to three levels.
abstract final class AppType {
  static const display = 30.0;
  static const screen = 24.0;
  static const section = 20.0;
  static const cardTitle = 15.0;
  static const body = 14.0;
  static const caption = 12.0;
  static const micro = 11.0;
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.teal,
      onPrimary: Colors.white,
      secondary: AppColors.orange,
      onSecondary: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: Color(0xFFB3261E),
      onError: Colors.white,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.paper,
      focusColor: AppColors.focus.withValues(alpha: 0.16),
      hoverColor: AppColors.teal.withValues(alpha: 0.06),
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 46),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 46),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          foregroundColor: AppColors.teal,
          side: const BorderSide(color: AppColors.tealBorder),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.tealSoft,
        secondarySelectedColor: AppColors.tealSoft,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.teal,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.teal
              : AppColors.line,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.teal
              : AppColors.muted,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.teal
              : Colors.transparent,
        ),
        side: const BorderSide(color: AppColors.teal, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.teal
              : AppColors.muted,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.tealBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.line, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.tealSoft,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.teal
                : AppColors.muted,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.ink,
          fontSize: AppType.display,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
          height: 1.05,
        ),
        headlineMedium: TextStyle(
          color: AppColors.ink,
          fontSize: AppType.screen,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          height: 1.1,
        ),
        titleLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          color: AppColors.ink,
          fontSize: AppType.cardTitle,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: AppColors.ink,
          fontSize: AppType.body,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          color: AppColors.muted,
          fontSize: AppType.caption,
          height: 1.45,
        ),
      ),
    );
  }
}
