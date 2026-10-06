import 'package:material_ui/material_ui.dart';

/// Design colors that have no slot in [ColorScheme].
/// Read with `Theme.of(context).extension<AppColors>()!`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.inputFill,
    required this.inputBorder,
    required this.progressTrack,
    required this.heroGradient,
  });

  static const light = AppColors(
    success: Color(0xFF43A94D),
    inputFill: Color(0xFFF0F3FF),
    inputBorder: Color(0xFFCCC3D8),
    progressTrack: Color(0xFFF0EDEC),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1B6524), Color(0xFF00530C)],
    ),
  );

  final Color success;
  final Color inputFill;
  final Color inputBorder;
  final Color progressTrack;
  final LinearGradient heroGradient;

  @override
  AppColors copyWith({
    Color? success,
    Color? inputFill,
    Color? inputBorder,
    Color? progressTrack,
    LinearGradient? heroGradient,
  }) {
    return AppColors(
      success: success ?? this.success,
      inputFill: inputFill ?? this.inputFill,
      inputBorder: inputBorder ?? this.inputBorder,
      progressTrack: progressTrack ?? this.progressTrack,
      heroGradient: heroGradient ?? this.heroGradient,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      progressTrack: Color.lerp(progressTrack, other.progressTrack, t)!,
      heroGradient: LinearGradient.lerp(heroGradient, other.heroGradient, t)!,
    );
  }
}
