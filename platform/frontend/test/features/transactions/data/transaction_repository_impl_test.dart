import 'package:flowfi_app/core/errors/failure.dart';
import 'package:flowfi_app/core/network/api_exception.dart';
import 'package:flowfi_app/features/transactions/data/datasources/transactions_api.dart';
import 'package:flowfi_app/features/transactions/data/models/transaction_dto.dart';
import 'package:flowfi_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures.dart';

class _MockApi extends Mock implements TransactionsApi {}

void main() {
  late _MockApi api;
  late TransactionRepositoryImpl repository;

  setUp(() {
    api = _MockApi();
    repository = TransactionRepositoryImpl(api);
  });

  test('show maps the DTO to an entity', () async {
    when(() => api.show(12))
        .thenAnswer((_) async => TransactionDto.fromJson(transactionJson()));

    final transaction = await repository.show(12);
    expect(transaction.id, 12);
  });

  final cases = <int?, Matcher>{
    404: isA<NotFoundFailure>(),
    422: isA<ValidationFailure>(),
    null: isA<NetworkFailure>(),
    500: isA<UnexpectedFailure>(),
  };
  for (final MapEntry(key: status, value: matcher) in cases.entries) {
    test('HTTP $status → $matcher', () async {
      when(() => api.delete(1)).thenThrow(ApiException(statusCode: status));

      await expectLater(repository.delete(1), throwsA(matcher));
    });
  }
}
