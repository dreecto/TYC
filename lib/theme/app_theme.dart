import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens + [ThemeData] for TYC Partner.
///
/// Dark, high-contrast, built for speed at a retail counter:
/// large tap targets, generous spacing, minimal chrome.
class AppColors {
  AppColors._();

  /// Base background behind everything.
  static const Color ground = Color(0xFF0E0E0E);

  /// Cards, sheets, inputs, raised surfaces.
  static const Color surface = Color(0xFF1A1A1A);

  // --- Bone family: light-on-dark cards for customer-facing moments ---
  // Use sparingly (offer display, acceptance summary) so those screens feel
  // premium and distinct from the clerk-facing dark UI. Pair with [onBone]
  // dark text.
  /// Bone card base.
  static const Color bone = Color(0xFFF2F0E8);

  /// Bone border (subtle).
  static const Color boneBorder = Color(0xFFE5E2D8);

  /// Bone divider / stronger border.
  static const Color boneDivider = Color(0xFFD8D4C8);

  /// Dark text/icons on a bone surface.
  static const Color onBone = Color(0xFF0E0E0E);

  /// Brand green — buttons, active states, highlights. Single source of green.
  static const Color primary = Color(0xFF7ED957);

  /// Accent green. Same brand green; kept as a separate token for intent.
  static const Color accent = Color(0xFF7ED957);

  /// Amber secondary accent — pending / attention states.
  static const Color amber = Color(0xFFF0A93B);

  /// Pure white — the floating nav pill (dark icons sit on it).
  static const Color pill = Color(0xFFFFFFFF);

  /// Off-white for text on dark surfaces.
  static const Color text = Color(0xFFF2F0E8);

  /// Muted variant of the off-white text for secondary content.
  static const Color textMuted = Color(0xFF9A988F);

  /// Hairline borders / dividers.
  static const Color border = Color(0xFF2A2A2A);

  /// Error / destructive.
  static const Color danger = Color(0xFFE5533C);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    // DM Sans for body text, applied across the default text theme.
    final bodyTextTheme = GoogleFonts.dmSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );

    // Space Grotesk 700 for headings/titles.
    final headingStyle = GoogleFonts.spaceGrotesk(
      fontWeight: FontWeight.w700,
      color: AppColors.text,
    );

    final textTheme = bodyTextTheme.copyWith(
      displayLarge: headingStyle.copyWith(fontSize: 40, letterSpacing: -0.5),
      displayMedium: headingStyle.copyWith(fontSize: 32, letterSpacing: -0.5),
      headlineLarge: headingStyle.copyWith(fontSize: 28),
      headlineMedium: headingStyle.copyWith(fontSize: 24),
      headlineSmall: headingStyle.copyWith(fontSize: 20),
      titleLarge: headingStyle.copyWith(fontSize: 20),
      titleMedium: headingStyle.copyWith(fontSize: 16),
    );

    final colorScheme = const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Color(0xFF07230A),
      secondary: AppColors.accent,
      onSecondary: Color(0xFF07230A),
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
      onError: AppColors.text,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.ground,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryColor: AppColors.primary,
      dividerColor: AppColors.border,
      splashColor: AppColors.primary.withValues(alpha: 0.12),
      highlightColor: AppColors.primary.withValues(alpha: 0.08),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ground,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headingStyle.copyWith(fontSize: 22),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: const Color(0xFF07230A),
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size.fromHeight(56), // large tap target
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
          shape: const StadiumBorder(), // pill buttons
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: AppColors.border),
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.text,
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
        labelStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
        floatingLabelStyle: GoogleFonts.dmSans(color: AppColors.accent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.22),
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.accent : AppColors.textMuted,
            size: 26,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.text : AppColors.textMuted,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: GoogleFonts.dmSans(color: AppColors.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
    );
  }
}
