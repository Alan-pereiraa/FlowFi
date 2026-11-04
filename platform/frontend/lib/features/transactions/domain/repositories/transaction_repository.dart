import '../../../../core/network/paginated.dart';
import '../entities/recurring_input.dart';
import '../entities/transaction.dart';
import '../entities/transaction_filter.dart';
import '../entities/transaction_input.dart';
import '../entities/transaction_update.dart';

abstract interface class TransactionRepository {
  /// Newest first.
  Future<Paginated<Transaction>> list({
    TransactionFilter filter = const TransactionFilter(),
    int page = 1,
    int perPage = 20,
  });

  Future<Transaction> show(int id);

  Future<Transaction> create(TransactionInput input);

  Future<Transaction> update(int id, TransactionUpdate update);

  Future<void> delete(int id);

  Future<void> createRecurring(RecurringInput input);

  Future<void> endRecurring(int recurringId);
}
