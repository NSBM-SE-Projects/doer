import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ──────────────────────────────────────────────────────────────
// SECTION 1: APP COLORS
// Every color in the app is defined here. Design A = Warm Gold.
// Usage: AppColors.primary, AppColors.background, etc.
// ──────────────────────────────────────────────────────────────
class AppColors {
  // Primary - Warm Gold (the main brand color)
  static const Color primary = Color(0xFFD4A55A);
  static const Color primaryLight = Color(0xFFE8C98A);
  static const Color primaryDark = Color(0xFFB8893E);

  // Backgrounds
  static const Color background = Color(0xFFFAFAF7); // warm off-white
  static const Color surface = Color(0xFFFFFFFF);     // pure white cards
  static const Color surfaceVariant = Color(0xFFF5F3EE); // slightly tinted

  // Text colors (dark to light)
  static const Color textPrimary = Color(0xFF2C2A26);   // main text
  static const Color textSecondary = Color(0xFF8B8680); // subtitles
  static const Color textTertiary = Color(0xFFA09B94);  // hints/placeholders
  static const Color textOnPrimary = Color(0xFFFFFFFF); // text on gold buttons

  // Borders
  static const Color border = Color(0xFFE8E5DF);
  static const Color borderLight = Color(0xFFF0EDE7);

  // Status colors (success, error, warning, info)
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFFBE9E7);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Category background colors (each service type gets a soft tint)
  static const Color categoryPlumbing = Color(0xFFFFF3E0);
  static const Color categoryElectrical = Color(0xFFE8F5E9);
  static const Color categoryCleaning = Color(0xFFE3F2FD);
  static const Color categoryPainting = Color(0xFFFBE9E7);
  static const Color categoryGardening = Color(0xFFF1F8E9);
  static const Color categoryMoving = Color(0xFFF3E5F5);
  static const Color categoryCarpentry = Color(0xFFEFEBE9);
  static const Color categoryAppliance = Color(0xFFE0F7FA);

  // Worker trust badge colors
  static const Color badgeBronze = Color(0xFFCD7F32);
  static const Color badgeSilver = Color(0xFFC0C0C0);
  static const Color badgeGold = Color(0xFFFFD700);
  static const Color badgePlatinum = Color(0xFFE5E4E2);
}

// ──────────────────────────────────────────────────────────────
// SECTION 2: TYPOGRAPHY
// Two font families:
//   - Lora (serif) = display/headings → warm, trustworthy feel
//   - Plus Jakarta Sans = body/labels → clean, modern
// Each style has size, weight, color, line height predefined.
// Usage: AppTypography.displayLarge, AppTypography.bodyMedium, etc.
// ──────────────────────────────────────────────────────────────
class AppTypography {
  static const String fontFamily = 'PlusJakartaSans';
  static const String fontFamilySerif = 'Lora';

  // Display styles (Lora serif - for big headings)
  static TextStyle get displayLarge => const TextStyle(
        fontFamily: fontFamilySerif,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontFamily: fontFamilySerif,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.25,
        letterSpacing: -0.3,
      );

  static TextStyle get displaySmall => const TextStyle(
        fontFamily: fontFamilySerif,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  // Headline styles (Plus Jakarta Sans - for section titles)
  static TextStyle get headlineLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get headlineMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      );

  static TextStyle get headlineSmall => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // Body styles (for paragraphs and descriptions)
  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // Label styles (for buttons, chips, tags)
  static TextStyle get labelLarge => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  static TextStyle get labelMedium => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        height: 1.4,
      );

  // Button text style
  static TextStyle get button => const TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
        height: 1.2,
        letterSpacing: 0.2,
      );
}

// ──────────────────────────────────────────────────────────────
// SECTION 3: THEME DATA
// This configures Flutter's Material theme so ALL default widgets
// (buttons, inputs, cards, app bars) automatically use our design.
// Usage: In main.dart → theme: AppTheme.light
// ──────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: AppTypography.fontFamily,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.textOnPrimary,
          secondary: AppColors.primaryLight,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        // App bar: transparent, no shadow, dark icons
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        // Cards: white, no shadow, thin border, rounded
        cardTheme: CardTheme(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        // Primary buttons: gold background, white text
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: AppTypography.button,
          ),
        ),
        // Outlined buttons: border only, no fill
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            side: const BorderSide(color: AppColors.border),
            textStyle: AppTypography.button.copyWith(color: AppColors.textPrimary),
          ),
        ),
        // Text buttons: gold text, no background
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTypography.labelLarge.copyWith(color: AppColors.primary),
          ),
        ),
        // Text fields: white fill, rounded border, gold focus
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
          labelStyle: AppTypography.labelMedium,
        ),
        // Bottom nav bar styling
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textTertiary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        // Divider styling
        dividerTheme: const DividerThemeData(
          color: AppColors.borderLight,
          thickness: 1,
          space: 0,
        ),
        // Bottom sheets: white, rounded top
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
      );
}
