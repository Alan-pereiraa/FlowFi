import 'package:flowfi_app/core/network/paginated.dart';
import 'package:flowfi_app/features/transactions/data/models/transaction_dto.dart';
import 'package:flowfi_app/features/transactions/data/models/transaction_request_dto.dart';
import 'package:flowfi_app/features/transactions/domain/entities/installment.dart';
import 'package:flowfi_app/features/transactions/domain/entities/recurring_input.dart';
import 'package:flowfi_app/features/transactions/domain/entities/transaction_filter.dart';
import 'package:flowfi_app/features/transactions/domain/entities/transaction_input.dart';
import 'package:flowfi_app/features/transactions/domain/entities/transaction_schedule.dart';
import 'package:flowfi_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flowfi_app/features/transactions/domain/entities/transaction_update.dart';
import 'package:flowfi_app/shared/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

void main() {
  test('parses a transaction with installments', () {
    final transaction = TransactionDto.fromJson(transactionJson()).toEntity();

    expect(transaction.type, TransactionType.expense);
    expect(transaction.categoryId, 3);
    expect(transaction.date, DateTime(2026, 10, 24));
    expect(transaction.totalAmount, const Money(10001));
    expect(transaction.installments, hasLength(2));
    expect(transaction.installments.first.status, InstallmentStatus.paid);
    expect(transaction.installments.last.amount, const Money(5000));
    expect(transaction.hasPaidInstallment, isTrue);
  });

  test('parses a transfer with no category', () {
    final json = transactionJson(type: 'transfer', installments: const [])
      ..['category_id'] = null
      ..['goal_id'] = 4;
    final transaction = TransactionDto.fromJson(json).toEntity();

    expect(transaction.type, TransactionType.transfer);
    expect(transaction.categoryId, isNull);
    expect(transaction.hasPaidInstallment, isFalse);
  });

  test('parses a Laravel paginator page', () {
    final page = Paginated.fromJson({
      'data': [transactionJson()],
      'links': <String, dynamic>{},
      'meta': {'current_page': 1, 'last_page': 3, 'per_page': 20, 'total': 41},
    }, TransactionDto.fromJson);

    expect(page.items, hasLength(1));
    expect(page.hasMore, isTrue);
    expect(page.total, 41);
  });

  group('request bodies', () {
    test('single installment sends no period', () {
      final body = TransactionRequestDto.store(
        TransactionInput(
          type: TransactionType.expense,
          categoryId: 3,
          date: DateTime(2026, 10, 24),
          schedule: const TransactionSchedule(totalAmount: Money(4500)),
        ),
      );

      expect(body, {
        'type': 'expense',
        'category_id': 3,
        'description': null,
        'date': '2026-10-24',
        'total_amount': '45.00',
        'installments_count': 1,
        'period_unit': null,
        'period_interval': null,
      });
    });

    test('recurrence becomes a monthly split', () {
      final body = TransactionRequestDto.store(
        TransactionInput(
          type: TransactionType.income,
          categoryId: 3,
          date: DateTime(2026, 10, 24),
          description: 'Salário',
          schedule: const TransactionSchedule(
            totalAmount: Money(300000),
            installmentsCount: 3,
          ),
        ),
      );

      expect(body['installments_count'], 3);
      expect(body['period_unit'], 'month');
      expect(body['period_interval'], 1);
    });

    test('update without a schedule leaves the payment plan alone', () {
      final body = TransactionRequestDto.update(
        TransactionUpdate(categoryId: 3, date: DateTime(2026, 10, 25)),
      );

      expect(
        body.keys,
        unorderedEquals(['category_id', 'description', 'date']),
      );
    });

    test('transfer sends the goal and no category or split', () {
      final body = TransactionRequestDto.store(
        TransactionInput(
          type: TransactionType.transfer,
          goalId: 7,
          date: DateTime(2026, 10, 24),
          schedule: const TransactionSchedule(totalAmount: Money(10000)),
        ),
      );

      expect(body, {
        'type': 'transfer',
        'goal_id': 7,
        'description': null,
        'date': '2026-10-24',
        'total_amount': '100.00',
      });
    });

    test('transfer update sends the goal instead of a category', () {
      final body = TransactionRequestDto.update(
        TransactionUpdate(goalId: 7, date: DateTime(2026, 10, 25)),
      );

      expect(body['goal_id'], 7);
      expect(body.containsKey('category_id'), isFalse);
    });

    test('recurrence repeats the full amount monthly', () {
      final body = TransactionRequestDto.recurring(
        RecurringInput(
          type: TransactionType.expense,
          categoryId: 3,
          amount: const Money(3990),
          startDate: DateTime(2026, 10, 24),
          description: 'Netflix',
          occurrences: 12,
        ),
      );

      expect(body, {
        'type': 'expense',
        'category_id': 3,
        'description': 'Netflix',
        'amount': '39.90',
        'period_unit': 'month',
        'period_interval': 1,
        'start_date': '2026-10-24',
        'occurrences': 12,
      });

      final untilDate = TransactionRequestDto.recurring(
        RecurringInput(
          type: TransactionType.transfer,
          goalId: 7,
          amount: const Money(5000),
          startDate: DateTime(2026, 10, 24),
          endDate: DateTime(2027, 3, 24),
        ),
      );
      expect(untilDate['goal_id'], 7);
      expect(untilDate['end_date'], '2027-03-24');
      expect(untilDate.containsKey('occurrences'), isFalse);
      expect(untilDate.containsKey('category_id'), isFalse);
    });

    test('query sends only the filters that are set', () {
      expect(
        TransactionRequestDto.query(
          TransactionFilter(
            type: TransactionType.expense,
            categoryId: 3,
            dateFrom: DateTime(2026, 10),
            dateTo: DateTime(2026, 10, 31),
          ),
          page: 2,
          perPage: 20,
        ),
        {
          'page': 2,
          'per_page': 20,
          'type': 'expense',
          'category_id': 3,
          'date_from': '2026-10-01',
          'date_to': '2026-10-31',
        },
      );
      expect(
        TransactionRequestDto.query(
          const TransactionFilter(),
          page: 1,
          perPage: 20,
        ),
        {'page': 1, 'per_page': 20},
      );
    });
  });
}
