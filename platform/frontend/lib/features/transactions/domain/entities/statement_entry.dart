import 'package:flutter/foundation.dart';

import '../../../../shared/money/money.dart';
import 'installment.dart';
import 'transaction.dart';

@immutable
class StatementEntry {
  const StatementEntry({required this.transaction, this.installment});

  final Transaction transaction;
  final Installment? installment;

  DateTime get date => installment?.date ?? transaction.date;

  Money get amount => installment?.amount ?? transaction.totalAmount;
}
