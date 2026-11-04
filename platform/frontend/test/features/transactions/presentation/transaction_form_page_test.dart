import 'package:flowfi_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:flowfi_app/features/categories/domain/repositories/category_repository.dart';
import 'package:flowfi_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:flowfi_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flowfi_app/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:flowfi_app/shared/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactions extends Mock implements TransactionRepository {}

class _MockCategories extends Mock implements CategoryRepository {}

void main() {
  late _MockCategories categories;

  setUp(() {
    categories = _MockCategories();
    when(() => categories.list()).thenAnswer((_) async => []);
  });

  Future<void> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(_MockTransactions()),
          categoryRepositoryProvider.overrideWithValue(categories),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const TransactionFormPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('a split expense hides the recurrence', (tester) async {
    await pumpForm(tester);
    expect(find.text('Transação Recorrente'), findsOneWidget);

    await tap(tester, 'Transação Parcelada');

    expect(find.text('Transação Recorrente'), findsNothing);
    expect(find.text('2x'), findsOneWidget);

    await tap(tester, 'Transação Parcelada');

    expect(find.text('Transação Recorrente'), findsOneWidget);
  });

  testWidgets('choosing a split turns the recurrence off', (tester) async {
    await pumpForm(tester);
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Até ser cancelado'), findsOneWidget);

    await tap(tester, 'Transação Parcelada');
    await tap(tester, 'Transação Parcelada');

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    expect(find.text('Até ser cancelado'), findsNothing);
  });

  testWidgets('income cannot be split', (tester) async {
    await pumpForm(tester);
    await tap(tester, 'Transação Parcelada');

    await tap(tester, 'Entrada');

    expect(find.text('Transação Parcelada'), findsNothing);
    expect(find.text('Transação Recorrente'), findsOneWidget);

    await tap(tester, 'Saída');

    expect(find.text('Transação Parcelada'), findsOneWidget);
    expect(find.text('2x'), findsNothing);
  });
}
