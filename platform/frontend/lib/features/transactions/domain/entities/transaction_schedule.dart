import 'package:flutter/foundation.dart';

import '../../../../shared/money/money.dart';

/// Amount and duration of a transaction. The backend splits [totalAmount]
/// evenly over [installmentsCount] monthly installments.
// GAP: the design's "Repetir mensalmente" means repeating the full amount,
// but the backend only splits it (`installments_count`). Until that is
// decided, the duration maps to a monthly split.
@immutable
class TransactionSchedule {
  const TransactionSchedule({
    required this.totalAmount,
    this.installmentsCount = 1,
  });

  final Money totalAmount;
  final int installmentsCount;

  bool get isRecurring => installmentsCount > 1;

  @override
  bool operator ==(Object other) =>
      other is TransactionSchedule &&
      other.totalAmount == totalAmount &&
      other.installmentsCount == installmentsCount;

  @override
  int get hashCode => Object.hash(totalAmount, installmentsCount);
}
