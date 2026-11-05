import 'package:material_ui/material_ui.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 32});

  static const asset = 'assets/images/logo.png';
  static const darkAsset = 'assets/images/logo_dark.png';

  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      dark ? darkAsset : asset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'FlowFi',
    );
  }
}
