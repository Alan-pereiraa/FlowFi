import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Rounded progress bar. Defaults to the design system's track/success
/// colors; pass [color] to tint it (a category's own color, or the error
/// color when a limit is close). [value] is 0..1.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
  });

  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final fraction = value.clamp(0.0, 1.0);
    final fill = color ?? colors.success;

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Container(
          height: height,
          color: color == null
              ? colors.progressTrack
              : fill.withValues(alpha: 0.16),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction,
            child: Container(color: fill),
          ),
        ),
      ),
    );
  }
}
