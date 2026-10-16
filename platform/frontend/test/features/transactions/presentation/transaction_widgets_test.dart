import 'package:flowfi_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flowfi_app/features/transactions/presentation/widgets/transaction_type_toggle.dart';
import 'package:flowfi_app/shared/money/money.dart';
import 'package:flowfi_app/shared/theme/app_theme.dart';
import 'package:flowfi_app/shared/widgets/money_amount_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('MoneyAmountField builds the value digit by digit', (
    tester,
  ) async {
    var value = Money.zero;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => MoneyAmountField(
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );

    expect(find.text('0,00'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '5');
    await tester.pump();
    expect(value, const Money(5));
    expect(find.text('0,05'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0,050');
    await tester.pump();
    expect(value, const Money(50));

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(value, const Money(123456));
    expect(find.text('1.234,56'), findsOneWidget);
  });

  testWidgets('MoneyAmountField stepper adds and subtracts', (tester) async {
    var value = const Money(500);
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => MoneyAmountField(
            value: value,
            step: const Money(1000),
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Aumentar'));
    await tester.pump();
    expect(value, const Money(1500));

    await tester.tap(find.byTooltip('Diminuir'));
    await tester.tap(find.byTooltip('Diminuir'));
    await tester.pump();
    // Never goes negative.
    expect(value, const Money(500));
  });

  testWidgets('type toggle is inert on edit', (tester) async {
    TransactionType? changed;
    await tester.pumpWidget(
      _host(
        TransactionTypeToggle(value: TransactionType.expense, onChanged: null),
      ),
    );

    await tester.tap(find.text('Entrada'));
    await tester.pump();
    expect(changed, isNull);

    await tester.pumpWidget(
      _host(
        TransactionTypeToggle(
          value: TransactionType.expense,
          onChanged: (t) => changed = t,
        ),
      ),
    );
    await tester.tap(find.text('Entrada'));
    expect(changed, TransactionType.income);
  });
}
