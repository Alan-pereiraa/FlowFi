import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// The single source of colors, fonts and shapes. Widgets read everything
/// through `Theme.of(context)`; never write a hex literal inside a widget.
abstract final class AppTheme {
  static const _headingFont = 'Montserrat';
  static const _bodyFont = 'Inter';

  static final ColorScheme _scheme =
      ColorScheme.fromSeed(seedColor: const Color(0xFF00530C)).copyWith(
        primary: const Color(0xFF00530C),
        onPrimary: const Color(0xFFFFFFFF),
        error: const Color(0xFFBA1A1A),
        surface: const Color(0xFFFCF9F7),
        surfaceContainerLowest: const Color(0xFFFFFFFF),
        onSurface: const Color(0xFF1C1C1B),
        onSurfaceVariant: const Color(0xFF444844),
        outlineVariant: const Color(0xFFBEC5BE),
      );

  static ThemeData light() {
    final scheme = _scheme;
    const colors = AppColors.light;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _bodyFont,
    );

    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontFamily: _headingFont,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontFamily: _headingFont,
        fontWeight: FontWeight.w700,
        color: scheme.primary,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontFamily: _headingFont,
        fontWeight: FontWeight.w700,
        color: scheme.primary,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontFamily: _headingFont,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontFamily: _headingFont,
        fontWeight: FontWeight.w600,
        color: scheme.primary,
      ),
    );

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.inputBorder),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      extensions: const [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: buttonShape,
          textStyle: const TextStyle(
            fontFamily: _bodyFont,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(
            fontFamily: _bodyFont,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        indicatorShape: const StadiumBorder(),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, color: scheme.onSurface),
        ),
      ),
    );
  }
}
