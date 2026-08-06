import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

/// Builds the light and dark [ThemeData].
///
/// Both themes are produced by the same function so a component can never look
/// polished in one mode and neglected in the other.
abstract final class AppTheme {
  static ThemeData light() => _build(
    scheme: AppColors.lightScheme(),
    palette: AppPalette.light,
    brightness: Brightness.light,
  );

  static ThemeData dark() => _build(
    scheme: AppColors.darkScheme(),
    palette: AppPalette.dark,
    brightness: Brightness.dark,
  );

  static ThemeData _build({
    required ColorScheme scheme,
    required AppPalette palette,
    required Brightness brightness,
  }) {
    final textTheme = AppTypography.textTheme(
      palette.textPrimary,
      palette.textSecondary,
    );

    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      textTheme: textTheme,
      fontFamily: AppTypography.fontFamily,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      extensions: [palette],

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeThroughTransitionBuilder(),
          TargetPlatform.iOS: _FadeThroughTransitionBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: palette.background,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: palette.background,
              ),
      ),

      cardTheme: CardThemeData(
        color: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.lgAll,
          side: BorderSide(color: palette.border),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
          shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: Gap.md),
          foregroundColor: palette.textPrimary,
          side: BorderSide(color: palette.border),
          shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.textSecondary,
          shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.cardMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Gap.md,
          vertical: Gap.sm + 2,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        helperStyle: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
        helperMaxLines: 3,
        errorMaxLines: 3,
        border: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: palette.cardMuted,
        side: BorderSide(color: palette.border),
        labelStyle: textTheme.labelMedium?.copyWith(color: palette.textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: Gap.xs, vertical: Gap.xxs),
        shape: const RoundedRectangleBorder(borderRadius: Radii.pillAll),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkSurfaceMuted : const Color(0xFF22222B),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: isDark ? AppColors.accentDark : const Color(0xFFB9BFFF),
        shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
        insetPadding: const EdgeInsets.all(Gap.md),
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.xlAll,
          side: BorderSide(color: palette.border),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: palette.textSecondary,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: palette.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: palette.textSecondary,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: palette.textSecondary,
        ),
        shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
        contentPadding: const EdgeInsets.symmetric(horizontal: Gap.md),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : palette.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : palette.cardMuted,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : palette.border,
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: palette.cardMuted,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: palette.cardMuted,
        circularTrackColor: palette.cardMuted,
        linearMinHeight: 6,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceMuted : const Color(0xFF22222B),
          borderRadius: Radii.smAll,
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
    );
  }
}

/// A fade-through page transition.
///
/// Material's default Android transition (a vertical slide) fights the app's
/// card-based layout; a fade with a small scale keeps navigation calm and is
/// cheap enough to stay at 60/120fps on mid-range hardware.
final class _FadeThroughTransitionBuilder extends PageTransitionsBuilder {
  const _FadeThroughTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
        child: child,
      ),
    );
  }

  @override
  Duration get transitionDuration => MotionConstants.medium;
}
