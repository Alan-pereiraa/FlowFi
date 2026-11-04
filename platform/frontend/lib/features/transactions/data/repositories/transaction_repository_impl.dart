import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/network/paginated.dart';
import '../../domain/entities/recurring_input.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/entities/transaction_input.dart';
import '../../domain/entities/transaction_update.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transactions_api.dart';
import '../models/transaction_request_dto.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepositoryImpl(ref.watch(transactionsApiProvider)),
);

class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._api);

  final TransactionsApi _api;

  @override
  Future<Paginated<Transaction>> list({
    TransactionFilter filter = const TransactionFilter(),
    int page = 1,
    int perPage = 20,
  }) async {
    final query = TransactionRequestDto.query(
      filter,
      page: page,
      perPage: perPage,
    );
    final dtos = await guardApi(() => _api.list(query));
    return dtos.map((dto) => dto.toEntity());
  }

  @override
  Future<Transaction> show(int id) async {
    final dto = await guardApi(() => _api.show(id));
    return dto.toEntity();
  }

  @override
  Future<Transaction> create(TransactionInput input) async {
    final dto = await guardApi(
      () => _api.store(TransactionRequestDto.store(input)),
    );
    return dto.toEntity();
  }

  @override
  Future<Transaction> update(int id, TransactionUpdate update) async {
    final dto = await guardApi(
      () => _api.update(id, TransactionRequestDto.update(update)),
    );
    return dto.toEntity();
  }

  @override
  Future<void> delete(int id) => guardApi(() => _api.delete(id));

  @override
  Future<void> createRecurring(RecurringInput input) => guardApi(
    () => _api.storeRecurring(TransactionRequestDto.recurring(input)),
  );

  @override
  Future<void> endRecurring(int recurringId) =>
      guardApi(() => _api.endRecurring(recurringId));
}
