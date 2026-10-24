import '../../../../shared/money/money.dart';
import '../../../../shared/utils/dates.dart';
import '../../../transactions/domain/entities/transaction_type.dart';
import '../../domain/entities/dashboard_tag.dart';
import '../../domain/entities/recent_transaction.dart';

class RecentTransactionDto {
  const RecentTransactionDto({
    required this.id,
    required this.type,
    required this.date,
    required this.totalAmount,
    required this.installmentsCount,
    this.description,
    this.category,
    this.goal,
  });

  factory RecentTransactionDto.fromJson(Map<String, dynamic> json) =>
      RecentTransactionDto(
        id: json['id'] as int,
        type: json['type'] as String,
        description: json['description'] as String?,
        date: json['date'] as String,
        totalAmount: json['total_amount'].toString(),
        installmentsCount: json['installments_count'] as int,
        category: json['category'] as Map<String, dynamic>?,
        goal: json['goal'] as Map<String, dynamic>?,
      );

  final int id;
  final String type;
  final String? description;
  final String date;
  final String totalAmount;
  final int installmentsCount;
  final Map<String, dynamic>? category;
  final Map<String, dynamic>? goal;

  RecentTransaction toEntity() => RecentTransaction(
    id: id,
    type: TransactionType.fromApi(type),
    description: description,
    date: Dates.fromApi(date),
    totalAmount: Money.parse(totalAmount),
    installmentsCount: installmentsCount,
    category: _tag(category),
    goal: _tag(goal),
  );

  static DashboardTag? _tag(Map<String, dynamic>? json) => json == null
      ? null
      : DashboardTag(
          id: json['id'] as int,
          name: json['name'] as String,
          icon: json['icon'] as String,
          color: json['color'] as String,
        );
}
