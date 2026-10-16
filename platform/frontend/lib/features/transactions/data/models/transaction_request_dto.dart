import '../../../../shared/utils/dates.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/entities/transaction_input.dart';
import '../../domain/entities/transaction_schedule.dart';
import '../../domain/entities/transaction_update.dart';

/// Request bodies and query parameters for `/transactions`.
abstract final class TransactionRequestDto {
  static Map<String, dynamic> store(TransactionInput input) => {
    'type': input.type.apiValue,
    'category_id': input.categoryId,
    'description': input.description,
    'date': Dates.toApi(input.date),
    ..._schedule(input.schedule),
  };

  static Map<String, dynamic> update(TransactionUpdate update) => {
    'category_id': update.categoryId,
    'description': update.description,
    'date': Dates.toApi(update.date),
    if (update.schedule != null) ..._schedule(update.schedule!),
  };

  static Map<String, dynamic> query(
    TransactionFilter filter, {
    required int page,
    required int perPage,
  }) => {
    'page': page,
    'per_page': perPage,
    if (filter.type != null) 'type': filter.type!.apiValue,
    if (filter.dateFrom != null) 'date_from': Dates.toApi(filter.dateFrom!),
    if (filter.dateTo != null) 'date_to': Dates.toApi(filter.dateTo!),
  };

  /// A split over N months, or a single installment (null period so the
  /// backend stores it as `single`).
  static Map<String, dynamic> _schedule(TransactionSchedule schedule) => {
    'total_amount': schedule.totalAmount.toDecimal(),
    'installments_count': schedule.installmentsCount,
    'period_unit': schedule.isRecurring ? 'month' : null,
    'period_interval': schedule.isRecurring ? 1 : null,
  };
}
