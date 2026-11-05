import 'package:flowfi_app/shared/widgets/app_logo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  String assetIn(WidgetTester tester) =>
      (tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName;

  testWidgets('shows the logo image at the given height', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: AppLogo(height: 40))),
    );

    expect(assetIn(tester), AppLogo.asset);
    expect(tester.widget<Image>(find.byType(Image)).height, 40);
    expect(find.bySemanticsLabel('FlowFi'), findsOneWidget);
  });

  testWidgets('uses the white version on a dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: const Center(child: AppLogo()),
      ),
    );

    expect(assetIn(tester), AppLogo.darkAsset);
  });
}
