import '../../../../shared/utils/date_labels.dart';
import '../../../../shared/utils/money.dart';
import '../../domain/entities/goal.dart';

/// Mirrors the backend `GoalResource` (the inner object, without envelope).
class GoalDto {
  const GoalDto({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.targetAmount,
    required this.currentAmount,
    this.expiresAt,
  });

  factory GoalDto.fromJson(Map<String, dynamic> json) => GoalDto(
    id: json['id'] as int,
    name: json['name'] as String,
    icon: json['icon'] as String,
    color: json['color'] as String,
    // Decimal strings ("1500.00"); toString() also tolerates a bare number.
    targetAmount: json['target_amount'].toString(),
    currentAmount: (json['current_amount'] ?? '0.00').toString(),
    expiresAt: json['expires_at'] as String?,
  );

  final int id;
  final String name;
  final String icon;
  final String color;
  final String targetAmount;
  final String currentAmount;
  final String? expiresAt;

  Goal toEntity() => Goal(
    id: id,
    name: name,
    icon: icon,
    color: color,
    targetCents: Money.parseApi(targetAmount) ?? 0,
    currentCents: Money.parseApi(currentAmount) ?? 0,
    expiresAt: DateLabels.parseApi(expiresAt),
  );
}
