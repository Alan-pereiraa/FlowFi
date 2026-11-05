import '../../../../shared/utils/dates.dart';
import '../../domain/entities/recurring_input.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/entities/transaction_input.dart';
import '../../domain/entities/transaction_schedule.dart';
import '../../domain/entities/transaction_type.dart';
import '../../domain/entities/transaction_update.dart';

abstract final class TransactionRequestDto {
  static Map<String, dynamic> store(TransactionInput input) {
    final movesGoal = input.type.movesGoal;
    return {
      'type': input.type.apiValue,
      if (movesGoal)
        'goal_id': input.goalId
      else
        'category_id': input.categoryId,
      'description': input.description,
      'date': Dates.toApi(input.date),
      if (movesGoal)
        'total_amount': input.schedule.totalAmount.toDecimal()
      else
        ..._schedule(input.schedule),
    };
  }

  static Map<String, dynamic> update(TransactionUpdate update) => {
    if (update.goalId != null)
      'goal_id': update.goalId
    else
      'category_id': update.categoryId,
    'description': update.description,
    'date': Dates.toApi(update.date),
    if (update.schedule != null) ..._schedule(update.schedule!),
  };

  static Map<String, dynamic> recurring(RecurringInput input) => {
    'type': input.type.apiValue,
    if (input.type == TransactionType.transfer)
      'goal_id': input.goalId
    else
      'category_id': input.categoryId,
    'description': input.description,
    'amount': input.amount.toDecimal(),
    'period_unit': input.periodUnit,
    'period_interval': input.periodInterval,
    'start_date': Dates.toApi(input.startDate),
    if (input.endDate != null) 'end_date': Dates.toApi(input.endDate!),
    if (input.occurrences != null) 'occurrences': input.occurrences,
  };

  static Map<String, dynamic> query(
    TransactionFilter filter, {
    required int page,
    required int perPage,
  }) => {
    'page': page,
    'per_page': perPage,
    if (filter.type != null) 'type': filter.type!.apiValue,
    if (filter.categoryId != null) 'category_id': filter.categoryId,
    if (filter.dateFrom != null) 'date_from': Dates.toApi(filter.dateFrom!),
    if (filter.dateTo != null) 'date_to': Dates.toApi(filter.dateTo!),
    if (filter.overdue) 'overdue': 1,
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
