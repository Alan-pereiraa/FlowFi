import 'package:flowfi_app/core/errors/failure.dart';
import 'package:flowfi_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:flowfi_app/features/categories/domain/repositories/category_repository.dart';
import 'package:flowfi_app/features/transactions/data/models/transaction_dto.dart';
import 'package:flowfi_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:flowfi_app/features/transactions/domain/entities/recurring_input.dart';
import 'package:flowfi_app/features/transactions/domain/entities/transaction_input.dart';
import 'package:flowfi_app/features/transactions/domain/entities/transaction_schedule.dart';
import 'package:flowfi_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flowfi_app/features/transactions/domain/entities/transaction_update.dart';
import 'package:flowfi_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flowfi_app/features/transactions/presentation/controllers/transaction_form_controller.dart';
import 'package:flowfi_app/shared/money/money.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class _MockTransactions extends Mock implements TransactionRepository {}

class _MockCategories extends Mock implements CategoryRepository {}

void main() {
  late _MockTransactions transactions;
  late _MockCategories categories;
  // total 100.01 in 2 installments, the first one paid.
  final original = TransactionDto.fromJson(transactionJson()).toEntity();

  TransactionInput draft({Money amount = const Money(10001), int count = 2}) =>
      TransactionInput(
        type: TransactionType.expense,
        categoryId: 3,
        date: DateTime(2026, 10, 25),
        description: 'Almoço',
        schedule: TransactionSchedule(
          totalAmount: amount,
          installmentsCount: count,
        ),
      );

  setUpAll(() {
    registerFallbackValue(draft());
    registerFallbackValue(TransactionUpdate(categoryId: 1, date: DateTime(0)));
    registerFallbackValue(
      RecurringInput(
        type: TransactionType.expense,
        amount: Money.zero,
        startDate: DateTime(0),
      ),
    );
  });

  setUp(() {
    transactions = _MockTransactions();
    categories = _MockCategories();
    when(() => categories.list()).thenAnswer((_) async => []);
    when(() => transactions.show(12)).thenAnswer((_) async => original);
  });

  Future<ProviderContainer> boot(int? id) async {
    final container = ProviderContainer.test(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(transactions),
        categoryRepositoryProvider.overrideWithValue(categories),
      ],
    );
    container.listen(transactionFormControllerProvider(id), (_, _) {});
    await pumpEventQueue();
    return container;
  }

  test('new transaction is created as drafted', () async {
    when(() => transactions.create(any())).thenAnswer((_) async => original);

    final container = await boot(null);
    final input = draft();
    await container
        .read(transactionFormControllerProvider(null).notifier)
        .save(input);

    verify(() => transactions.create(input)).called(1);
    expect(container.read(transactionFormControllerProvider(null)).saved, true);
  });

  test('edit loads the transaction and flags the paid lock', () async {
    final container = await boot(12);
    final state = container.read(transactionFormControllerProvider(12));

    expect(state.original, original);
    expect(state.scheduleLocked, isTrue);
  });

  test('edit without schedule changes omits the schedule', () async {
    when(() => transactions.update(12, any()))
        .thenAnswer((_) async => original);

    final container = await boot(12);
    await container
        .read(transactionFormControllerProvider(12).notifier)
        .save(draft());

    final update =
        verify(() => transactions.update(12, captureAny())).captured.single
            as TransactionUpdate;
    expect(update.schedule, isNull);
    expect(update.date, DateTime(2026, 10, 25));
  });

  test('edit with a new amount sends the schedule', () async {
    when(() => transactions.update(12, any()))
        .thenAnswer((_) async => original);

    final container = await boot(12);
    await container
        .read(transactionFormControllerProvider(12).notifier)
        .save(draft(amount: const Money(20000)));

    final update =
        verify(() => transactions.update(12, captureAny())).captured.single
            as TransactionUpdate;
    expect(
      update.schedule,
      const TransactionSchedule(
        totalAmount: Money(20000),
        installmentsCount: 2,
      ),
    );
  });

  test('paid-installment 422 becomes a form error', () async {
    when(() => transactions.update(12, any())).thenThrow(
      const ValidationFailure(
        fieldErrors: {
          'installments': [
            'This transaction already has paid installments; its payment '
                'plan can no longer be changed.',
          ],
        },
      ),
    );

    final container = await boot(12);
    await container
        .read(transactionFormControllerProvider(12).notifier)
        .save(draft(amount: const Money(1)));
    final state = container.read(transactionFormControllerProvider(12));

    expect(state.saved, isFalse);
    expect(state.formError, contains('parcelas pagas'));
  });

  test('over-limit 422 is shown under the amount', () async {
    when(() => transactions.create(any())).thenThrow(
      const ValidationFailure(
        fieldErrors: {
          'total_amount': [
            'This transaction exceeds the category limit for 2026-10.',
          ],
        },
      ),
    );

    final container = await boot(null);
    await container
        .read(transactionFormControllerProvider(null).notifier)
        .save(draft());
    final state = container.read(transactionFormControllerProvider(null));

    expect(
      state.fieldErrors['total_amount'],
      'Esta transação ultrapassa o limite da categoria em 10/2026.',
    );
    expect(state.formError, isNull);
  });

  test('delete marks the form as deleted', () async {
    when(() => transactions.delete(12)).thenAnswer((_) async {});

    final container = await boot(12);
    await container
        .read(transactionFormControllerProvider(12).notifier)
        .delete();

    expect(container.read(transactionFormControllerProvider(12)).deleted, true);
  });

  test('missing transaction → load error', () async {
    when(() => transactions.show(99)).thenThrow(const NotFoundFailure());

    final container = await boot(99);
    final state = container.read(transactionFormControllerProvider(99));

    expect(state.loadError, 'Não encontrado.');
    expect(state.original, isNull);
  });

  test('a new recurrence goes to /recurring-transactions', () async {
    when(() => transactions.createRecurring(any())).thenAnswer((_) async {});
    final input = RecurringInput(
      type: TransactionType.expense,
      categoryId: 3,
      amount: const Money(3990),
      startDate: DateTime(2026, 10, 24),
      occurrences: 12,
    );

    final container = await boot(null);
    await container
        .read(transactionFormControllerProvider(null).notifier)
        .saveRecurring(input);

    verify(() => transactions.createRecurring(input)).called(1);
    verifyNever(() => transactions.create(any()));
    expect(container.read(transactionFormControllerProvider(null)).saved, true);
  });

  test('cancelling the recurrence ends it', () async {
    when(() => transactions.show(13)).thenAnswer(
      (_) async => TransactionDto.fromJson({
        ...transactionJson(id: 13),
        'recurring_transaction_id': 5,
      }).toEntity(),
    );
    when(() => transactions.endRecurring(5)).thenAnswer((_) async {});

    final container = await boot(13);
    await container
        .read(transactionFormControllerProvider(13).notifier)
        .endRecurrence();

    verify(() => transactions.endRecurring(5)).called(1);
    expect(
      container.read(transactionFormControllerProvider(13)).recurrenceEnded,
      isTrue,
    );
  });
}
