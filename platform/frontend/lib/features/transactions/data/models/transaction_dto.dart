import '../../../../shared/money/money.dart';
import '../../../../shared/utils/dates.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_type.dart';
import 'installment_dto.dart';

/// Mirrors the backend `TransactionResource` (the inner object).
class TransactionDto {
  const TransactionDto({
    required this.id,
    required this.type,
    required this.date,
    required this.totalAmount,
    required this.installmentsCount,
    this.categoryId,
    this.goalId,
    this.description,
    this.scheduleType,
    this.periodUnit,
    this.periodInterval,
    this.recurringTransactionId,
    this.installments = const [],
  });

  factory TransactionDto.fromJson(Map<String, dynamic> json) => TransactionDto(
    id: json['id'] as int,
    categoryId: json['category_id'] as int?,
    goalId: json['goal_id'] as int?,
    type: json['type'] as String,
    description: json['description'] as String?,
    date: json['date'] as String,
    totalAmount: json['total_amount'] as String,
    installmentsCount: json['installments_count'] as int,
    scheduleType: json['schedule_type'] as String?,
    periodUnit: json['period_unit'] as String?,
    periodInterval: json['period_interval'] as int?,
    recurringTransactionId: json['recurring_transaction_id'] as int?,
    installments: [
      for (final item in (json['installments'] as List<dynamic>? ?? const []))
        InstallmentDto.fromJson(item as Map<String, dynamic>),
    ],
  );

  final int id;
  final int? categoryId;
  final int? goalId;
  final String type;
  final String? description;
  final String date;
  final String totalAmount;
  final int installmentsCount;

  /// `single` | `periodic` | `custom`.
  final String? scheduleType;
  final String? periodUnit;
  final int? periodInterval;
  final int? recurringTransactionId;
  final List<InstallmentDto> installments;

  Transaction toEntity() => Transaction(
    id: id,
    categoryId: categoryId,
    goalId: goalId,
    type: TransactionType.fromApi(type),
    description: description,
    date: Dates.fromApi(date),
    totalAmount: Money.parse(totalAmount),
    installmentsCount: installmentsCount,
    periodUnit: periodUnit,
    periodInterval: periodInterval,
    recurringTransactionId: recurringTransactionId,
    installments: installments.map((i) => i.toEntity()).toList(),
  );
}
