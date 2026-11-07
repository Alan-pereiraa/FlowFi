import 'dart:typed_data';

import '../../../../core/network/paginated.dart';
import '../entities/installment.dart';
import '../entities/recurring_input.dart';
import '../entities/transaction.dart';
import '../entities/transaction_draft.dart';
import '../entities/transaction_filter.dart';
import '../entities/transaction_input.dart';
import '../entities/transaction_update.dart';
import '../entities/recurrence.dart';

abstract interface class TransactionRepository {
  Future<Paginated<Transaction>> list({
    TransactionFilter filter = const TransactionFilter(),
    int page = 1,
    int perPage = 20,
  });

  Future<Transaction> show(int id);

  Future<Transaction> create(TransactionInput input);

  Future<Transaction> update(int id, TransactionUpdate update);

  Future<void> delete(int id);

  Future<Installment> payInstallment(int transactionId, int installmentId);

  Future<Installment> unpayInstallment(int transactionId, int installmentId);

  Future<void> createRecurring(RecurringInput input);

  Future<void> endRecurring(int recurringId);

  Future<Recurrence> recurrence(int recurringId);

  Future<TransactionDraft> draftFromAudio(Uint8List wav);
}
