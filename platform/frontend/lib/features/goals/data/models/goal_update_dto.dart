import '../../../../shared/utils/date_labels.dart';
import '../../../../shared/utils/money.dart';
import '../../domain/entities/goal_update.dart';

class GoalUpdateDto {
  const GoalUpdateDto(this.data);

  final GoalUpdate data;

  Map<String, dynamic> toJson() => {
    'name': data.name,
    'icon': data.icon,
    'color': data.color,
    'target_amount': Money.toApi(data.targetCents),
    'expires_at': data.expiresAt == null
        ? null
        : DateLabels.toApi(data.expiresAt!),
  };
}
