import 'package:flutter/material.dart';

/// The app's colour palette.
///
/// Rather than letting Material 3 derive everything from a single seed, the
/// neutrals are hand-picked: seeded neutrals carry a colour tint that reads as
/// muddy in a content-heavy app. The accents are seeded, the surfaces are not —
/// which is what gives the UI its Linear/Notion-like calm.
abstract final class AppColors {
  /// Primary accent — indigo/violet.
  static const Color accent = Color(0xFF5E6AD2);
  static const Color accentDark = Color(0xFF7C87E8);

  /// Used for the TikTok → YouTube gradient on the home title.
  static const Color tiktokPink = Color(0xFFEE1D52);
  static const Color tiktokCyan = Color(0xFF25F4EE);
  static const Color youtubeRed = Color(0xFFFF0033);

  static const Color success = Color(0xFF17A673);
  static const Color successDark = Color(0xFF3DDC97);
  static const Color warning = Color(0xFFCC7A00);
  static const Color danger = Color(0xFFD92D20);
  static const Color dangerDark = Color(0xFFFF6B60);

  // --- Light neutrals -------------------------------------------------------
  static const Color lightBackground = Color(0xFFFBFBFD);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFF4F4F7);
  static const Color lightBorder = Color(0xFFE6E6EC);
  static const Color lightTextPrimary = Color(0xFF16161D);
  static const Color lightTextSecondary = Color(0xFF6B6B7B);

  // --- Dark neutrals --------------------------------------------------------
  static const Color darkBackground = Color(0xFF0B0B0F);
  static const Color darkSurface = Color(0xFF141419);
  static const Color darkSurfaceMuted = Color(0xFF1C1C23);
  static const Color darkBorder = Color(0xFF2A2A33);
  static const Color darkTextPrimary = Color(0xFFEDEDF2);
  static const Color darkTextSecondary = Color(0xFF9494A5);

  /// The gradient used behind the home screen's headline.
  static const List<Color> brandGradient = [tiktokPink, accent];

  static ColorScheme lightScheme() =>
      ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
      ).copyWith(
        primary: accent,
        onPrimary: Colors.white,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        onSurfaceVariant: lightTextSecondary,
        surfaceContainerLowest: lightSurface,
        surfaceContainerLow: lightBackground,
        surfaceContainer: lightSurfaceMuted,
        surfaceContainerHigh: lightSurfaceMuted,
        outline: lightBorder,
        outlineVariant: lightBorder,
        error: danger,
      );

  static ColorScheme darkScheme() =>
      ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
      ).copyWith(
        primary: accentDark,
        onPrimary: const Color(0xFF10101A),
        surface: darkSurface,
        onSurface: darkTextPrimary,
        onSurfaceVariant: darkTextSecondary,
        surfaceContainerLowest: darkBackground,
        surfaceContainerLow: darkSurface,
        surfaceContainer: darkSurfaceMuted,
        surfaceContainerHigh: darkSurfaceMuted,
        outline: darkBorder,
        outlineVariant: darkBorder,
        error: dangerDark,
      );
}

/// Theme-aware colours that Material's [ColorScheme] has no slot for.
///
/// Registered as a [ThemeExtension] so widgets read them from the theme rather
/// than branching on `Theme.of(context).brightness` at every call site.
final class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.card,
    required this.cardMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.shadow,
  });

  final Color background;
  final Color card;
  final Color cardMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color shadow;

  static const AppPalette light = AppPalette(
    background: AppColors.lightBackground,
    card: AppColors.lightSurface,
    cardMuted: AppColors.lightSurfaceMuted,
    border: AppColors.lightBorder,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    success: AppColors.success,
    shadow: Color(0x14161630),
  );

  static const AppPalette dark = AppPalette(
    background: AppColors.darkBackground,
    card: AppColors.darkSurface,
    cardMuted: AppColors.darkSurfaceMuted,
    border: AppColors.darkBorder,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    success: AppColors.successDark,
    shadow: Color(0x66000000),
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? card,
    Color? cardMuted,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? shadow,
  }) => AppPalette(
    background: background ?? this.background,
    card: card ?? this.card,
    cardMuted: cardMuted ?? this.cardMuted,
    border: border ?? this.border,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    success: success ?? this.success,
    shadow: shadow ?? this.shadow,
  );

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardMuted: Color.lerp(cardMuted, other.cardMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// Convenient `context.palette` access.
extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
