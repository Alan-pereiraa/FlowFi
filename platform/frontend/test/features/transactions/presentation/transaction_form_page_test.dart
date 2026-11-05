import 'package:flowfi_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:flowfi_app/features/categories/domain/repositories/category_repository.dart';
import 'package:flowfi_app/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:flowfi_app/features/goals/domain/entities/goal.dart';
import 'package:flowfi_app/features/goals/domain/repositories/goal_repository.dart';

import 'dart:typed_data';

import 'package:flowfi_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:flowfi_app/features/transactions/data/voice/voice_recorder.dart';
import 'package:flowfi_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flowfi_app/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:flowfi_app/shared/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import 'voice_draft_controller_test.dart' show FakeRecorder, transferDraft;

class _MockTransactions extends Mock implements TransactionRepository {}

class _MockCategories extends Mock implements CategoryRepository {}

class _MockGoals extends Mock implements GoalRepository {}

void main() {
  late _MockCategories categories;
  late _MockTransactions transactions;
  late _MockGoals goals;

  setUpAll(() => registerFallbackValue(Uint8List(0)));

  setUp(() {
    categories = _MockCategories();
    transactions = _MockTransactions();
    goals = _MockGoals();
    when(() => categories.list()).thenAnswer((_) async => []);
  });

  Future<void> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(transactions),
          categoryRepositoryProvider.overrideWithValue(categories),
          goalRepositoryProvider.overrideWithValue(goals),
          voiceRecorderProvider.overrideWithValue(FakeRecorder()),
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

  testWidgets('a split expense disables the recurrence', (tester) async {
    await pumpForm(tester);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);

    await tap(tester, 'Transação Parcelada');

    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    expect(find.text('2x'), findsOneWidget);

    await tap(tester, 'Transação Parcelada');

    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);
  });

  testWidgets('a recurrence disables the split', (tester) async {
    await pumpForm(tester);
    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Até ser cancelado'), findsOneWidget);

    await tap(tester, 'Transação Parcelada');

    expect(find.byTooltip('Número de parcelas'), findsNothing);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.text('Até ser cancelado'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tap(tester, 'Transação Parcelada');

    expect(find.byTooltip('Número de parcelas'), findsOneWidget);
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

  testWidgets('voice fills a transfer to the goal, ready to review', (
    tester,
  ) async {
    when(() => transactions.draftFromAudio(any()))
        .thenAnswer((_) async => transferDraft);
    when(() => goals.list()).thenAnswer(
      (_) async => const [
        Goal(
          id: 7,
          name: 'Viagem de férias',
          icon: 'flight',
          color: '#2E7D32',
          targetCents: 500000,
          currentCents: 50000,
        ),
      ],
    );
    await pumpForm(tester);
    expect(find.text('Preencher por voz'), findsOneWidget);

    await tester.tap(find.byTooltip('Gravar'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Ouvindo...'), findsOneWidget);

    await tester.tap(find.byTooltip('Parar e preencher'));
    await tester.pumpAndSettle();

    expect(find.text('Campos preenchidos'), findsOneWidget);
    expect(find.text('guardei 200 na viagem'), findsOneWidget);
    expect(find.text('200,00'), findsOneWidget);
    expect(find.text('Viagem de férias'), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Viagem de férias'),
          matching: find.byType(InkWell),
        ),
        matching: find.byIcon(Icons.radio_button_checked),
      ),
      findsOneWidget,
    );
    expect(find.text('Transação Parcelada'), findsNothing);
  });
}
